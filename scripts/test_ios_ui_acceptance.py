"""Exercise the source-bound UI exception without a simulator or network."""

from __future__ import annotations

import copy
import json
import unittest
from datetime import UTC, datetime

from check_ios_ui_acceptance import CORE, OCR, POLICY, RUNTIME, evaluate

NATIVE = "TypographyDiagnosticsTests/testSettingsNativeAuditWithoutFilters()"
RUNTIME_IDS = {f"TypographyDiagnosticsTests/{name}()" for name in RUNTIME}


class UIAcceptanceTests(unittest.TestCase):
    def fixture(self) -> dict:
        policy = json.loads(POLICY.read_text())
        expected = {CORE, OCR, NATIVE, *RUNTIME_IDS}
        signature = policy["native_signatures"][NATIVE][0]
        return {
            "policy": policy,
            "tree": policy["ios_tree"],
            "revision": "tested-sha",
            "now": datetime(2026, 10, 2, tzinfo=UTC),
            "expected": expected,
            "tests": {
                "devices": [{"osVersion": "26.5", "modelName": "iPhone 17"}],
                "testNodes": [
                    {
                        "nodeType": "Test Case",
                        "nodeIdentifier": name,
                        "result": "Failed" if name == NATIVE else "Passed",
                    }
                    for name in sorted(expected)
                ],
            },
            "issues": {
                "testFailureSummaries": {"_values": [self.failure(NATIVE, signature["compact"])]}
            },
            "signatures": {NATIVE: [signature]},
            "controller": {
                "revision": "tested-sha",
                "errors": [],
                "original_size": "large",
                "restoration": {"system_size": "large"},
                "xcodebuild_exit_code": 65,
                "passed": False,
                "sessions": {
                    name: {
                        "test": f"-[TypographyDiagnosticsTests {name}]",
                        "restored": True,
                        "original_size": "large",
                        "stages": [{"system_size": "large"}],
                    }
                    for name in RUNTIME
                },
            },
            "wrapper_exit": 1,
        }

    @staticmethod
    def failure(test: str, message: str) -> dict:
        return {
            "testCaseName": {"_value": test.replace("/", ".", 1)},
            "message": {"_value": message},
        }

    def check(self, data: dict, accepted: bool) -> dict:
        report = evaluate(**data)
        self.assertEqual(report["gate_accepted"], accepted, report)
        return report

    def test_known_risk_remains_a_raw_failure(self) -> None:
        report = self.check(self.fixture(), True)
        self.assertFalse(report["all_xctests_passed"])
        self.assertEqual(len(report["accepted_failed_tests"]), 1)
        self.assertEqual(report["passed_tests"], 4)

    def test_all_actual_passes_need_no_exception(self) -> None:
        data = self.fixture()
        data["tree"] = "new-product-tree"
        data["now"] = datetime(2027, 1, 1, tzinfo=UTC)
        for node in data["tests"]["testNodes"]:
            node["result"] = "Passed"
        data["issues"] = {}
        data["controller"].update(xcodebuild_exit_code=0, passed=True)
        data["wrapper_exit"] = 0
        self.assertTrue(self.check(data, True)["all_xctests_passed"])

    def test_unknown_assertion_cannot_hide_behind_known_native_failure(self) -> None:
        data = self.fixture()
        data["issues"]["testFailureSummaries"]["_values"].append(
            self.failure(NATIVE, "XCTAssertTrue failed - navigation failed")
        )
        self.check(data, False)

    def test_exact_date_ocr_only(self) -> None:
        for message, accepted in [
            (self.fixture()["policy"]["ocr_failures"][0], True),
            ("XCTAssertNotNil failed - Full text absent: Machines", False),
            ("XCTAssertGreaterThan failed - glyph did not scale", False),
        ]:
            with self.subTest(message=message):
                data = self.fixture()
                for node in data["tests"]["testNodes"]:
                    if node["nodeIdentifier"] == OCR:
                        node["result"] = "Failed"
                data["issues"]["testFailureSummaries"]["_values"].append(self.failure(OCR, message))
                self.check(data, accepted)

    def test_incomplete_unaccepted_or_unbound_evidence_blocks_release(self) -> None:
        original = self.fixture()
        mutations = [
            lambda d: d.update(tree="different-product"),
            lambda d: d.update(now=datetime(2026, 10, 3, tzinfo=UTC)),
            lambda d: d["policy"].update(human_acceptance={}),
            lambda d: d["tests"]["testNodes"].pop(),
            lambda d: d["tests"]["testNodes"].append(d["tests"]["testNodes"][0]),
            lambda d: d["tests"]["testNodes"][0].update(result="Skipped"),
            lambda d: d["signatures"].clear(),
            lambda d: d["signatures"][NATIVE][0].update(identifier="unknown.control"),
            lambda d: d["issues"].update(errorSummaries={"_values": [{"error": "build"}]}),
            lambda d: d["issues"].clear(),
            lambda d: d["controller"].update(errors=["restoration failed"]),
            lambda d: d["controller"].update(revision="other-sha"),
            lambda d: d["controller"].update(xcodebuild_exit_code=70),
            lambda d: d["controller"]["restoration"].update(system_size="small"),
            lambda d: d["controller"]["sessions"].clear(),
            lambda d: next(iter(d["controller"]["sessions"].values())).update(restored=False),
            lambda d: d["tests"]["devices"][0].update(osVersion="27.0"),
            lambda d: d.update(wrapper_exit=2),
        ]
        for index, mutate in enumerate(mutations):
            with self.subTest(index=index):
                data = copy.deepcopy(original)
                # Signature references must not alias the policy whitelist in a fixture.
                data["signatures"] = copy.deepcopy(data["signatures"])
                mutate(data)
                self.check(data, False)


if __name__ == "__main__":
    unittest.main(verbosity=2)
