"""Verify real Simulator Dynamic Type changes and restoration in one live app."""

from __future__ import annotations

import argparse
import json
import re
import signal
import subprocess
import time
from pathlib import Path

XCRUN = "/usr/bin/xcrun"
APP = "dev.runbuoy.app"
SIZES = dict(
    zip(
        [
            "extra-small",
            "small",
            "medium",
            "large",
            "extra-large",
            "extra-extra-large",
            "extra-extra-extra-large",
            "accessibility-medium",
            "accessibility-large",
            "accessibility-extra-large",
            "accessibility-extra-extra-large",
            "accessibility-extra-extra-extra-large",
        ],
        [
            "XS",
            "S",
            "M",
            "L",
            "XL",
            "XXL",
            "XXXL",
            "AccessibilityM",
            "AccessibilityL",
            "AccessibilityXL",
            "AccessibilityXXL",
            "AccessibilityXXXL",
        ],
        strict=True,
    )
)


class ExpectedFailure(Exception):
    """Exercise restoration after a verified maximum-size change."""


def command(arguments: list[str], timeout: int = 30) -> str:
    result = subprocess.run(  # noqa: S603 - fixed Apple tooling; no shell interpolation
        arguments, text=True, capture_output=True, timeout=timeout
    )
    if result.returncode:
        raise RuntimeError(
            f"Command failed ({result.returncode}): {result.stdout}\n{result.stderr}"
        )
    return result.stdout.strip()


def read_app(pid: int, evidence: Path, label: str) -> list[str]:
    # Both getters are public UIKit APIs. The debugger does not set app state.
    arguments = [
        XCRUN,
        "lldb",
        "--batch",
        "-o",
        f"process attach --pid {pid}",
        "-o",
        "expression -l objc++ -- @import UIKit",
        "-o",
        "expression -l objc++ -O -- (id)[[UIApplication sharedApplication] "
        "preferredContentSizeCategory]",
        "-o",
        "expression -l objc++ -O -- ((UIWindowScene *)[[[UIApplication "
        "sharedApplication] connectedScenes] anyObject]).windows.firstObject."
        "traitCollection.preferredContentSizeCategory",
        "-o",
        "process detach",
        "-o",
        "quit",
    ]
    result = subprocess.run(  # noqa: S603 - fixed read-only debugger expressions
        arguments, text=True, capture_output=True, timeout=60
    )
    output = result.stdout + result.stderr
    (evidence / f"{label}-lldb.log").write_text(output)
    if result.returncode:
        raise RuntimeError(f"LLDB readback failed; see {label}-lldb.log")
    values = re.findall(r"^UICTContentSizeCategory\w+$", output, re.MULTILINE)
    if len(values) != 2:
        raise RuntimeError(f"Both app and window readbacks are required; see {label}-lldb.log")
    return values


def verify_live_app(device: str, pid: int, evidence: Path, label: str, category: str) -> dict:
    actual = command([XCRUN, "simctl", "ui", device, "content_size"])
    if actual != category:
        raise RuntimeError(f"System readback {actual!r} does not match {category!r}")
    if command(["/bin/ps", "-p", str(pid), "-o", "pid="]).strip() != str(pid):
        raise RuntimeError("The original app process is no longer alive")
    values = read_app(pid, evidence, label)
    expected = "UICTContentSizeCategory" + SIZES[category]
    if values != [expected, expected]:
        raise RuntimeError(f"Live app/window readback {values!r}; expected {expected!r}")
    record = {
        "stage": label,
        "system_size": actual,
        "pid": pid,
        "application_category": values[0],
        "window_category": values[1],
    }
    print(json.dumps(record), flush=True)
    return record


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--device", required=True)
    parser.add_argument("--evidence-dir", type=Path, required=True)
    parser.add_argument("--inject-failure", action="store_true")
    args = parser.parse_args()
    evidence = args.evidence_dir
    evidence.mkdir(parents=True, exist_ok=True)

    def simctl(*arguments: str) -> str:
        return command([XCRUN, "simctl", *arguments])

    def interrupted(_signum: int, _frame: object) -> None:
        raise InterruptedError("System-size check interrupted; restoring original size")

    signal.signal(signal.SIGTERM, interrupted)
    original = simctl("ui", args.device, "content_size")
    if original not in SIZES:
        raise RuntimeError(f"Unsupported original system size: {original}")
    result: dict = {
        "revision": command(["/usr/bin/git", "rev-parse", "HEAD"]),
        "device": args.device,
        "original_size": original,
        "injected_failure_requested": args.inject_failure,
        "expected_failure_observed": False,
        "stages": [],
        "errors": [],
    }
    pid: int | None = None

    def verify(label: str, category: str) -> dict:
        assert pid is not None
        return verify_live_app(args.device, pid, evidence, label, category)

    try:
        launch = simctl(
            "launch",
            "--terminate-running-process",
            args.device,
            APP,
            "-runbuoy-ui-testing",
            "-runbuoy-ui-scenario",
            "loaded",
            "-runbuoy-ui-reset-state",
            "-AppleLanguages",
            "(en)",
            "-AppleLocale",
            "en_US",
        )
        pid = int(launch.rsplit(":", 1)[1].strip())
        result["pid"] = pid
        for label, category in [
            ("large", "large"),
            ("maximum", "accessibility-extra-extra-extra-large"),
            ("returned", "large"),
        ]:
            simctl("ui", args.device, "content_size", category)
            time.sleep(1)
            result["stages"].append(verify(label, category))
            if args.inject_failure and label == "maximum":
                raise ExpectedFailure("Injected failure after verified maximum system size")
    except ExpectedFailure:
        result["expected_failure_observed"] = True
    except BaseException as error:
        result["errors"].append(f"{type(error).__name__}: {error}")
    finally:
        try:
            simctl("ui", args.device, "content_size", original)
            time.sleep(1)
            result["restoration"] = (
                verify("cleanup", original)
                if pid
                else {"system_size": simctl("ui", args.device, "content_size")}
            )
            if result["restoration"]["system_size"] != original:
                raise RuntimeError("Original system size was not restored")
        except BaseException as error:
            result["errors"].append(f"Restoration {type(error).__name__}: {error}")
        finally:
            if pid:
                try:
                    simctl("terminate", args.device, APP)
                except (RuntimeError, subprocess.TimeoutExpired) as error:
                    result["errors"].append(f"App cleanup failed: {error}")
            result["passed"] = (
                not result["errors"]
                and (result["expected_failure_observed"] == args.inject_failure)
                and len(result["stages"]) == (2 if args.inject_failure else 3)
            )
            (evidence / "result.json").write_text(json.dumps(result, indent=2) + "\n")
            print(json.dumps(result, indent=2), flush=True)
    return 0 if result["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
