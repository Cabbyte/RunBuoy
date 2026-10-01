"""Run XCTest with real Simulator size control through its private test container."""

from __future__ import annotations

import argparse
import json
import plistlib
import signal
import subprocess
import time
import uuid
from pathlib import Path

from check_ios_system_size import APP, SIZES, XCRUN, command, verify_live_app

RUNNER = "dev.runbuoy.app.uitests.xctrunner"
DIRECTORY = "RunBuoySystemSizeControl"


def write_json(path: Path, value: dict) -> None:
    temporary = path.with_suffix(".writing")
    temporary.write_text(json.dumps(value, indent=2) + "\n")
    temporary.replace(path)


class Controller:
    def __init__(self, device: str, evidence: Path):
        self.device = device
        self.evidence = evidence
        self.evidence.mkdir(parents=True, exist_ok=True)
        self.started_at = time.time()
        self.original = self.simctl("ui", device, "content_size")
        if self.original not in SIZES:
            raise RuntimeError(f"Unsupported original size: {self.original}")
        self.sessions: dict[str, dict] = {}
        self.errors: list[str] = []
        self.root: Path | None = None
        self.next_container_check = 0.0

    def simctl(self, *arguments: str) -> str:
        return command([XCRUN, "simctl", *arguments])

    def app_pid(self) -> int:
        bundle = Path(self.simctl("get_app_container", self.device, APP, "app"))
        executable = plistlib.loads((bundle / "Info.plist").read_bytes())["CFBundleExecutable"]
        expected = str(bundle / executable)
        matches = []
        for line in command(["/bin/ps", "-axo", "pid=,command="]).splitlines():
            parts = line.strip().split(maxsplit=1)
            if len(parts) == 2 and parts[1].startswith(expected + " "):
                if "-runbuoy-ui-testing" not in parts[1].split():
                    raise RuntimeError("Only the sample-data UI-test app may be controlled")
                matches.append(int(parts[0]))
        if len(matches) != 1:
            raise RuntimeError(f"Expected one running sample app on {self.device}; found {matches}")
        return matches[0]

    def process(self, request: dict) -> dict:
        identifier = str(uuid.UUID(request["session"]))
        action = request["action"]
        if action == "begin":
            if identifier in self.sessions:
                raise RuntimeError("Duplicate session")
            if any(not value["restored"] for value in self.sessions.values()):
                raise RuntimeError("Previous session has not restored its original size")
            original = self.simctl("ui", self.device, "content_size")
            if original not in SIZES:
                raise RuntimeError("Invalid system snapshot")
            session = {
                "pid": self.app_pid(),
                "original_size": original,
                "test": request["test"],
                "stages": [],
                "restored": False,
            }
            self.sessions[identifier] = session
            (self.evidence / identifier).mkdir()
            return {
                "pid": session["pid"],
                "original_size": original,
                "original_category": "UICTContentSizeCategory" + SIZES[original],
            }
        session = self.sessions[identifier]
        if session["restored"]:
            raise RuntimeError("A restored session cannot change system state again")
        # Re-resolve the executable in this specific simulator, not just a PID
        # that could have been reused after an unnoticed app relaunch.
        if self.app_pid() != session["pid"]:
            raise RuntimeError("The sample app was relaunched during the size session")
        if action not in {"set", "restore"}:
            raise RuntimeError(f"Unsupported action: {action}")
        category = session["original_size"] if action == "restore" else request["category"]
        if category not in SIZES:
            raise RuntimeError(f"Unsupported requested category: {category}")
        self.simctl("ui", self.device, "content_size", category)
        time.sleep(1)
        record = verify_live_app(
            self.device,
            session["pid"],
            self.evidence / identifier,
            f"{len(session['stages']):02d}-{action}",
            category,
        )
        session["stages"].append(record)
        if action == "restore":
            session["restored"] = True
        return record

    def poll(self) -> None:
        if time.monotonic() >= self.next_container_check:
            self.next_container_check = time.monotonic() + 3
            try:
                container = self.simctl("get_app_container", self.device, RUNNER, "data")
                self.root = Path(container) / "Documents" / DIRECTORY
            except RuntimeError:
                return  # XCTest has not installed its runner yet.
        if self.root is None:
            return
        for path in sorted(self.root.glob("*.request.json")):
            if path.stat().st_mtime < self.started_at:
                continue  # Never act on requests left by an earlier run.
            response = path.with_name(path.name.replace(".request.json", ".response.json"))
            if response.exists():
                continue
            request = json.loads(path.read_text())
            try:
                value = {"ok": True, **self.process(request)}
            except Exception as error:
                message = f"{type(error).__name__}: {error}"
                self.errors.append(message)
                value = {"ok": False, "error": message}
            write_json(self.evidence / path.name, request)
            write_json(self.evidence / response.name, value)
            write_json(response, value)

    def restore(self) -> dict:
        result: dict = {}
        try:
            self.simctl("ui", self.device, "content_size", self.original)
            result["system_size"] = self.simctl("ui", self.device, "content_size")
            if result["system_size"] != self.original:
                raise RuntimeError("Independent system restoration failed")
            for identifier, session in self.sessions.items():
                if not session["restored"]:
                    # XCTest may abort or its runner may crash before teardown.
                    # Keep the missing teardown as a failure even if host cleanup works.
                    self.errors.append(f"Session {identifier} did not complete XCTest restoration")
                    if self.app_pid() == session["pid"]:
                        time.sleep(1)
                        result["emergency_live_app"] = verify_live_app(
                            self.device,
                            session["pid"],
                            self.evidence / identifier,
                            "emergency-cleanup",
                            self.original,
                        )
        except Exception as error:
            self.errors.append(f"Cleanup {type(error).__name__}: {error}")
        return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--device", required=True)
    parser.add_argument("--evidence-dir", type=Path, required=True)
    parser.add_argument("test_command", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    arguments = args.test_command
    if arguments[:1] == ["--"]:
        arguments = arguments[1:]
    if not arguments:
        parser.error("Provide the xcodebuild test command after --")
    controller = Controller(args.device, args.evidence_dir)
    process = None
    exit_code = 1

    def interrupted(_signum: int, _frame: object) -> None:
        raise InterruptedError("Interrupted; restoring original system size")

    signal.signal(signal.SIGTERM, interrupted)
    try:
        # This command is supplied by the developer/CI, never by container requests.
        process = subprocess.Popen(arguments)  # noqa: S603
        while process.poll() is None:
            controller.poll()
            time.sleep(0.1)
        exit_code = process.wait()
    except BaseException as error:
        controller.errors.append(f"{type(error).__name__}: {error}")
    finally:
        if process is not None and process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
        restoration = controller.restore()
        if not controller.sessions:
            controller.errors.append("No runtime UI-test session reached the system controller")
        report = {
            "revision": command(["/usr/bin/git", "rev-parse", "HEAD"]),
            "device": args.device,
            "original_size": controller.original,
            "sessions": controller.sessions,
            "xcodebuild_exit_code": exit_code,
            "restoration": restoration,
            "errors": controller.errors,
            "passed": exit_code == 0 and not controller.errors,
        }
        write_json(args.evidence_dir / "result.json", report)
        print(json.dumps(report, indent=2), flush=True)
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
