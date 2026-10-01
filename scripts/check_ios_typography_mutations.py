"""Prove each typography assertion rejects fixed and capped fonts, restoring sources."""

import argparse
import hashlib
import json
import subprocess
from pathlib import Path

NODES = {
    "hint": ("apps/ios/RunBuoyApp/RunsView.swift", "activeRuns.confirmationHint"),
    "title": ("apps/ios/RunBuoyApp/SettingsView.swift", "settings.machines.title"),
    "count": ("apps/ios/RunBuoyApp/SettingsView.swift", "settings.machines.count"),
    "suffix": ("apps/ios/RunBuoyApp/SettingsView.swift", "settings.machines.suffix"),
}
TEST = "RunBuoyUITests/TypographyDiagnosticsTests/testRenderedGlyphsAtLargestAccessibilitySize"


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--worktree", type=Path, default=Path.cwd())
    parser.add_argument("--evidence-dir", type=Path, required=True)
    parser.add_argument("--derived-data-path", type=Path, required=True)
    parser.add_argument("--destination", required=True)
    args = parser.parse_args()
    worktree = args.worktree.resolve()
    evidence = args.evidence_dir.resolve()
    evidence.mkdir(parents=True, exist_ok=True)
    originals = {path: (worktree / path).read_bytes() for path, _ in NODES.values()}
    source_hashes = {path: digest(data) for path, data in originals.items()}
    revision = subprocess.check_output(
        ["/usr/bin/git", "rev-parse", "HEAD"], cwd=worktree, text=True
    ).strip()
    results = []

    def run_test(case_name: str) -> tuple[int, list[str]]:
        command = [
            "/usr/bin/xcodebuild",
            "-project",
            "apps/ios/RunBuoy.xcodeproj",
            "-scheme",
            "RunBuoy",
            "-configuration",
            "Debug",
            "-destination",
            args.destination,
            "-derivedDataPath",
            str(args.derived_data_path.resolve()),
            "-resultBundlePath",
            str(evidence / f"{case_name}.xcresult"),
            "-parallel-testing-enabled",
            "NO",
            "-maximum-concurrent-test-simulator-destinations",
            "1",
            "-collect-test-diagnostics",
            "never",
            f"-only-testing:{TEST}",
            "CODE_SIGNING_ALLOWED=NO",
            "ONLY_ACTIVE_ARCH=YES",
            "test",
        ]
        log_path = evidence / f"{case_name}.log"
        with log_path.open("w") as log:
            # Fixed Apple executable and argument array; no shell interpolation.
            completed = subprocess.run(  # noqa: S603
                command, cwd=worktree, stdout=log, stderr=subprocess.STDOUT, check=False
            )
        failures = [line for line in log_path.read_text().splitlines() if "error:" in line]
        return completed.returncode, failures

    baseline_code, _ = run_test("mutation-positive-before")
    if baseline_code:
        raise SystemExit("Unmodified positive control failed; no mutations applied")
    try:
        for kind, modifier in [
            ("fixed", ".font(.system(size: 17))"),
            ("capped", ".dynamicTypeSize(...DynamicTypeSize.xxxLarge)"),
        ]:
            for short_name, (path, identifier) in NODES.items():
                for name, expected in originals.items():
                    if (worktree / name).read_bytes() != expected:
                        raise RuntimeError(f"Source changed before mutation: {name}")
                target = worktree / path
                source = originals[path].decode()
                anchor = f'.accessibilityIdentifier("{identifier}")'
                if source.count(anchor) != 1:
                    raise RuntimeError(f"Expected unique node anchor: {identifier}")
                line = next(line for line in source.splitlines() if anchor in line)
                indent = line[: len(line) - len(line.lstrip())]
                mutant = source.replace(line, f"{indent}{modifier}\n{line}", 1)
                case_name = f"mutation-{kind}-{short_name}"
                try:
                    target.write_text(mutant)
                    code, failures = run_test(case_name)
                    killed = code != 0 and any(
                        "XCTAssertEqualWithAccuracy failed" in line and identifier in line
                        for line in failures
                    )
                    results.append(
                        {
                            "case": case_name,
                            "node": identifier,
                            "mutation": modifier,
                            "xcodebuild_exit_code": code,
                            "killed_by_target_glyph_assertion": killed,
                            "failure_lines": failures,
                            "original_source_sha256": source_hashes[path],
                            "mutant_source_sha256": digest(mutant.encode()),
                        }
                    )
                    (evidence / "mutation-results.json").write_text(
                        json.dumps({"base_revision": revision, "results": results}, indent=2)
                    )
                    print(f"{case_name}: target assertion rejected mutation={killed}", flush=True)
                finally:
                    if target.read_text() != mutant:
                        raise RuntimeError(f"External edit; refusing to overwrite: {path}")
                    target.write_bytes(originals[path])
                if not killed:
                    raise SystemExit(f"Mutation survived or failed for another reason: {case_name}")
    finally:
        restored = all((worktree / path).read_bytes() == data for path, data in originals.items())
        (evidence / "mutation-restoration.json").write_text(
            json.dumps(
                {"base_revision": revision, "restored": restored, "source_sha256": source_hashes},
                indent=2,
            )
        )
    restored_code, _ = run_test("mutation-positive-after")
    if restored_code:
        raise SystemExit("Restored positive control failed")
    print(
        "All eight mutations rejected; exact sources restored; positive control passed", flush=True
    )


if __name__ == "__main__":
    main()
