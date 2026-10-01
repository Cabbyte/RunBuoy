"""Exercise the actual TestFlight shell gate with isolated GitHub API responses."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
APPROVED_BRANCH = "codex/ios-signal-buoy-v3"
MOCK_GH = r"""#!/usr/bin/env python3
import json
import os
import sys
from urllib.parse import unquote

fixture = json.loads(os.environ["RELEASE_GATE_FIXTURE"])
if fixture.get("api_error"):
    sys.exit(3)
args = sys.argv[1:]
endpoint = next(arg for arg in args if arg.startswith("repos/"))
if "/compare/" in endpoint:
    branch = unquote(endpoint.split("...")[1])
    print(fixture["ancestry"].get(branch, "behind"))
elif endpoint.endswith("/actions/workflows/ci.yml/runs"):
    fields = dict(args[i + 1].split("=", 1) for i, arg in enumerate(args) if arg == "-f")
    assert fields["head_sha"] == os.environ["GITHUB_SHA"]
    assert fields["branch"] in ["main", "codex/ios-signal-buoy-v3"]
    assert fields["event"] == "push"
    assert fields["status"] == "completed"
    # Deliberately return unrelated records too: the gate must check the
    # returned branch, SHA, event and completion, not only the query string.
    print(json.dumps({"workflow_runs": fixture["runs"]}))
else:
    sys.exit(4)
"""


class IOSReleaseGateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        workflow = yaml.safe_load((ROOT / ".github/workflows/testflight.yml").read_text())
        cls.gate = next(
            step["run"]
            for step in workflow["jobs"]["publish"]["steps"]
            if step["name"] == "Verify release source is an exactly tested approved branch commit"
        )
        cls.sha = subprocess.check_output(  # noqa: S603 -- local git metadata only
            [shutil.which("git") or "/usr/bin/git", "rev-parse", "HEAD"], cwd=ROOT, text=True
        ).strip()

    def run_gate(
        self,
        *,
        branch: str = APPROVED_BRANCH,
        sha: str | None = None,
        event: str = "push",
        status: str = "completed",
        conclusion: str = "success",
        ancestry: str = "identical",
        api_error: bool = False,
        empty: bool = False,
    ) -> subprocess.CompletedProcess[str]:
        fixture = {
            "ancestry": {"main": ancestry, APPROVED_BRANCH: ancestry},
            "api_error": api_error,
            "runs": []
            if empty
            else [
                {
                    "head_branch": branch,
                    "head_sha": sha or self.sha,
                    "event": event,
                    "status": status,
                    "conclusion": conclusion,
                }
            ],
        }
        with tempfile.TemporaryDirectory(prefix="runbuoy-release-gate-") as directory:
            gh = Path(directory) / "gh"
            gh.write_text(MOCK_GH)
            gh.chmod(0o700)
            return subprocess.run(  # noqa: S603 -- trusted workflow; gh is a local mock
                [shutil.which("bash") or "/bin/bash", "-c", self.gate],
                cwd=ROOT,
                env={
                    **os.environ,
                    "PATH": f"{directory}{os.pathsep}{os.environ['PATH']}",
                    "GITHUB_SHA": self.sha,
                    "GITHUB_REPOSITORY": "Cabbyte/RunBuoy",
                    "RELEASE_GATE_FIXTURE": json.dumps(fixture),
                    "GH_TOKEN": "isolated-test-no-network",
                },
                capture_output=True,
                text=True,
                check=False,
                timeout=10,
            )

    def test_main_exact_push_ci_is_accepted(self) -> None:
        result = self.run_gate(branch="main")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("successful push CI on main", result.stdout)

    def test_v3_exact_push_ci_is_accepted(self) -> None:
        result = self.run_gate(ancestry="ahead")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(f"successful push CI on {APPROVED_BRANCH}", result.stdout)

    def test_unapproved_or_untested_sources_are_rejected(self) -> None:
        cases = [
            {"branch": "feature/unapproved"},
            {"sha": "0" * 40},
            {"event": "pull_request"},
            {"event": "workflow_dispatch"},
            {"conclusion": "failure"},
            {"status": "in_progress"},
            {"ancestry": "behind"},
            {"ancestry": "diverged"},
            {"empty": True},
            {"api_error": True},
        ]
        for case in cases:
            with self.subTest(case=case):
                result = self.run_gate(**case)
                self.assertNotEqual(result.returncode, 0, result.stdout)


if __name__ == "__main__":
    unittest.main(verbosity=2)
