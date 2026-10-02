"""Regression checks for Simulator startup delays versus real control failures."""

import json
import subprocess
import tempfile
import unittest
import uuid
from pathlib import Path
from unittest.mock import patch

from check_ios_system_size import read_app
from run_ios_system_size_tests import DIRECTORY, Controller


class SystemSizeControllerTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.directory = Path(temporary.name)
        with patch("run_ios_system_size_tests.command", return_value="large"):
            self.controller = Controller("test-device", self.directory / "evidence")

    def test_runner_discovery_retries_timeout_and_not_installed_until_ready(self) -> None:
        with patch(
            "run_ios_system_size_tests.command",
            side_effect=[
                subprocess.TimeoutExpired("simctl", 5),
                RuntimeError("Runner not installed"),
                str(self.directory / "runner"),
            ],
        ) as command:
            for _ in range(3):
                self.controller.next_container_check = 0
                self.controller.poll()
        self.assertEqual(self.controller.container_discovery["retry_count"], 2)
        self.assertEqual(self.controller.root, self.directory / "runner" / "Documents" / DIRECTORY)
        self.assertEqual(self.controller.errors, [])
        self.assertTrue(all(call.kwargs["timeout"] == 5 for call in command.call_args_list))
        self.assertTrue(
            all(call.args[0][2] == "get_app_container" for call in command.call_args_list)
        )

    def test_cached_container_keeps_processing_during_discovery_delay(self) -> None:
        self.controller.root = self.directory / "exchange"
        self.controller.root.mkdir()
        request = self.controller.root / "next.request.json"
        request.write_text(json.dumps({"action": "begin", "session": str(uuid.uuid4())}))
        with (
            patch(
                "run_ios_system_size_tests.command",
                side_effect=subprocess.TimeoutExpired("simctl", 5),
            ),
            patch.object(self.controller, "process", return_value={"pid": 123}) as process,
        ):
            self.controller.poll()
        process.assert_called_once()
        response = json.loads(request.with_name("next.response.json").read_text())
        self.assertTrue(response["ok"])
        self.assertEqual(self.controller.errors, [])

    def test_actual_system_mutation_timeout_still_fails(self) -> None:
        identifier = str(uuid.uuid4())
        self.controller.sessions[identifier] = {"pid": 123, "restored": False}
        with (
            patch.object(self.controller, "app_pid", return_value=123),
            patch(
                "run_ios_system_size_tests.command",
                side_effect=subprocess.TimeoutExpired("simctl", 30),
            ),
            self.assertRaises(subprocess.TimeoutExpired),
        ):
            self.controller.process({"session": identifier, "action": "set", "category": "large"})
        self.assertFalse(self.controller.sessions[identifier]["restored"])

    def test_debugger_timeout_preserves_partial_evidence_and_still_fails(self) -> None:
        with (
            patch(
                "check_ios_system_size.subprocess.run",
                side_effect=subprocess.TimeoutExpired("lldb", 120, output=b"partial SDK import"),
            ),
            self.assertRaisesRegex(RuntimeError, "timed out after 120s"),
        ):
            read_app(123, self.directory, "cold-read")
        self.assertEqual((self.directory / "cold-read-lldb.log").read_text(), "partial SDK import")


if __name__ == "__main__":
    unittest.main(verbosity=2)
