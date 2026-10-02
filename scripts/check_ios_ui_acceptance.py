"""Keep raw XCTest failures; accept only the user's source-bound internal beta risks."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
from datetime import UTC, datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
POLICY = ROOT / "docs/release-acceptance/2026-10-02-internal-testflight.json"
CORE = "RunBuoyUITests/testAccessibilityAuditForCoreScreensAndScenarios()"
OCR = "TypographyDiagnosticsTests/testRemainingSettingsTextAtLargeAndLargestSizes()"
RUNTIME = (
    "testRuntimeFontSwitchPreservesAppAndMachineNavigation",
    "testRuntimeFontSwitchRestoresSizeAfterInjectedFailure",
)


def command(arguments: list[str]) -> str:
    return subprocess.check_output(arguments, text=True, cwd=ROOT)  # noqa: S603


def cases(nodes: list[dict]) -> list[dict]:
    found = []
    for node in nodes:
        if node.get("nodeType") == "Test Case":
            found.append(node)
        else:
            found.extend(cases(node.get("children", [])))
    return found


def expected_tests() -> set[str]:
    return {
        f"{path.stem}/{method}()"
        for path in (ROOT / "apps/ios/RunBuoyUITests").glob("*.swift")
        for method in re.findall(r"func (test\w+)\(", path.read_text())
    }


def evaluate(
    *,
    policy: dict,
    tree: str,
    revision: str,
    now: datetime,
    expected: set[str],
    tests: dict,
    issues: dict,
    signatures: dict[str, list[dict]],
    controller: dict,
    wrapper_exit: int,
) -> dict:
    errors: list[str] = []
    accepted: list[dict] = []
    leaves = cases(tests.get("testNodes", []))
    identifiers = [node["nodeIdentifier"] for node in leaves]
    results = {node["nodeIdentifier"]: node.get("result") for node in leaves}
    if set(identifiers) != expected or len(identifiers) != len(expected):
        errors.append("UI tests missing, duplicated, or unexpected")
    if any(value not in {"Passed", "Failed"} for value in results.values()):
        errors.append("Skipped, incomplete, or unexpected test result")
    if controller.get("revision") != revision:
        errors.append("Controller revision differs from tested checkout")
    if controller.get("errors") != []:
        errors.append("System size controller reported an error or has no error record")
    if controller.get("restoration", {}).get("system_size") != controller.get("original_size"):
        errors.append("System size was not restored")
    sessions = list(controller.get("sessions", {}).values())
    for method in RUNTIME:
        matching = [
            s for s in sessions if s.get("test") == f"-[TypographyDiagnosticsTests {method}]"
        ]
        if len(matching) != 1:
            errors.append(f"Missing or duplicate runtime session: {method}")
    for session in sessions:
        stages = session.get("stages", [])
        if not session.get("restored") or not stages:
            errors.append("Runtime session did not complete restoration")
        elif stages[-1].get("system_size") != session.get("original_size"):
            errors.append("Runtime session restored the wrong size")
    exit_code = controller.get("xcodebuild_exit_code")
    if exit_code not in {0, 65} or wrapper_exit != (0 if controller.get("passed") else 1):
        errors.append("Build, runner, or controller exit was unexpected")
    if issues.get("errorSummaries", {}).get("_values", []):
        errors.append("Xcode reported build or infrastructure errors")
    failures = issues.get("testFailureSummaries", {}).get("_values", [])
    failed_tests = {name for name, result in results.items() if result == "Failed"}
    reported: dict[str, list[str]] = {}
    for failure in failures:
        identifier = failure.get("testCaseName", {}).get("_value", "").replace(".", "/", 1)
        reported.setdefault(identifier, []).append(failure.get("message", {}).get("_value", ""))
    if set(reported) != failed_tests:
        errors.append("Failed tests and complete XCTest assertion records disagree")
    if bool(failures) != (exit_code == 65):
        errors.append("XCTest failure records and xcodebuild exit disagree")
    if failures:
        if tree != policy["ios_tree"]:
            errors.append("User acceptance does not cover this iOS source tree")
        if now >= datetime.fromisoformat(policy["expires_at"]):
            errors.append("Temporary internal TestFlight risk acceptance expired")
        if policy.get("human_acceptance", {}).get("result") != "user-reported-pass":
            errors.append("Human acceptance is missing")
        devices = tests.get("devices", [])
        if len(devices) != 1 or any(
            d.get("osVersion") != "26.5" or d.get("modelName") != "iPhone 17" for d in devices
        ):
            errors.append("Accepted native signatures are specific to iPhone 17 / iOS 26.5")
    for identifier, messages in reported.items():
        allowed = False
        if identifier == CORE:
            allowed = all(message == policy["core_failure"] for message in messages)
        elif identifier == OCR:
            allowed = all(message in policy["ocr_failures"] for message in messages)
        elif identifier in policy["native_signatures"]:
            observed = signatures.get(identifier, [])
            known = policy["native_signatures"][identifier]
            allowed = bool(observed) and all(signature in known for signature in observed)
            # xcresult issue summaries deduplicate identical messages within a test.
            # Attachments retain every callback occurrence; summaries must contain
            # exactly their message categories and no additional assertion failure.
            allowed = allowed and set(messages) == {s["compact"] for s in observed}
        if allowed:
            accepted.append({"test": identifier, "raw_failures": messages})
        else:
            errors.append(
                f"Unaccepted failure or missing native evidence: {identifier}: {messages}"
            )
    return {
        "revision": revision,
        "ios_tree": tree,
        "passed_tests": sum(result == "Passed" for result in results.values()),
        "total_tests": len(leaves),
        "accepted_failed_tests": accepted,
        "blocking_errors": errors,
        "gate_accepted": not errors,
        "all_xctests_passed": not errors and not failures,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--evidence", required=True, type=Path)
    parser.add_argument("--wrapper-exit", required=True, type=int)
    args = parser.parse_args()
    evidence = args.evidence
    bundle = evidence / "RunBuoyUITests.xcresult"
    attachments = evidence / "UI-attachments"
    try:
        command(["/usr/bin/git", "diff", "--exit-code", "HEAD", "--", "apps/ios"])
        for name, arguments in {
            "UI-legacy.json": ["get", "object", "--legacy", "--format", "json"],
            "UI-tests.json": ["get", "test-results", "tests"],
        }.items():
            (evidence / name).write_text(
                command(["/usr/bin/xcrun", "xcresulttool", *arguments, "--path", str(bundle)])
            )
        command(
            [
                "/usr/bin/xcrun",
                "xcresulttool",
                "export",
                "attachments",
                "--path",
                str(bundle),
                "--output-path",
                str(attachments),
            ]
        )
        signatures: dict[str, list[dict]] = {}
        for test in json.loads((attachments / "manifest.json").read_text()):
            for attachment in test["attachments"]:
                if attachment["suggestedHumanReadableName"].startswith(
                    "Unfiltered audit signature"
                ):
                    fields = dict(
                        line.split(": ", 1)
                        for line in (attachments / attachment["exportedFileName"])
                        .read_text()
                        .splitlines()
                        if ": " in line
                    )
                    signatures.setdefault(test["testIdentifier"], []).append(
                        {
                            key: fields[key]
                            for key in ("OS", "type", "compact", "identifier", "label")
                        }
                    )
        report = evaluate(
            policy=json.loads(POLICY.read_text()),
            tree=command(["/usr/bin/git", "rev-parse", "HEAD:apps/ios"]).strip(),
            revision=command(["/usr/bin/git", "rev-parse", "HEAD"]).strip(),
            now=datetime.now(UTC),
            expected=expected_tests(),
            tests=json.loads((evidence / "UI-tests.json").read_text()),
            issues=json.loads((evidence / "UI-legacy.json").read_text())["issues"],
            signatures=signatures,
            controller=json.loads((evidence / "runtime-system-size/result.json").read_text()),
            wrapper_exit=args.wrapper_exit,
        )
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError) as error:
        report = {"gate_accepted": False, "blocking_errors": [str(error)]}
    rendered = json.dumps(report, indent=2, ensure_ascii=False) + "\n"
    (evidence / "UI-acceptance.json").write_text(rendered)
    print(rendered)
    if summary := os.environ.get("GITHUB_STEP_SUMMARY"):
        with Path(summary).open("a") as stream:
            stream.write(
                "## iOS UI results (raw failures retained)\n\n```json\n" + rendered + "```\n"
            )
    return 0 if report["gate_accepted"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
