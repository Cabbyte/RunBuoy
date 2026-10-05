#!/usr/bin/env python3
"""Verify a uv-installed CLI in fresh shells; optionally register its bin directory."""

from __future__ import annotations

import argparse
import json
import os
import pwd
import shlex
import shutil
import subprocess
from pathlib import Path

MARKER = "__RUNBUOY_EXECUTABLE__="
PROBE = f"""
runbuoy_path=$(command -v runbuoy) || exit 1
test -x "$runbuoy_path" || exit 1
"$runbuoy_path" --version >/dev/null || exit 1
printf '\\n{MARKER}%s\\n' "$runbuoy_path"
"""
FISH_PROBE = f"""
set -l runbuoy_path (command -s runbuoy); or exit 1
test -x "$runbuoy_path"; or exit 1
"$runbuoy_path" --version >/dev/null; or exit 1
printf '\\n{MARKER}%s\\n' "$runbuoy_path"
"""


def run(
    argv: list[str], env: dict[str, str], *, cwd: Path | None = None
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(  # noqa: S603 - fixed commands, with paths passed as argv
        argv, env=env, cwd=cwd, capture_output=True, text=True, timeout=20, check=False
    )


def without_directory(path: str, directory: Path) -> str:
    """Do not let the installer's inherited PATH make a fresh-shell check pass."""
    return os.pathsep.join(
        entry for entry in path.split(os.pathsep) if Path(entry).resolve() != directory.resolve()
    )


def probe(shell: str, env: dict[str, str], executable: Path) -> dict[str, dict[str, object]]:
    command = FISH_PROBE if Path(shell).name == "fish" else PROBE
    results = {}
    for label, flags in (("interactive", "-ic"), ("login_interactive", "-lic")):
        try:
            # A fresh terminal normally opens at home. Project-specific shell
            # hooks must not make a global CLI appear ready only in this checkout.
            response = run([shell, flags, command], env, cwd=Path.home())
            paths = [
                line[len(MARKER) :]
                for line in response.stdout.splitlines()
                if line.startswith(MARKER)
            ]
            resolved = Path(paths[-1]) if paths else None
            matched = resolved is not None and resolved.resolve() == executable.resolve()
            results[label] = {
                "ok": response.returncode == 0 and matched,
                "executable": str(resolved) if resolved else None,
                "exit_code": response.returncode,
            }
        except subprocess.TimeoutExpired:
            results[label] = {"ok": False, "error": "shell_startup_timeout"}
    return results


def ensure_path(uv: str, shell: str, repair: bool) -> dict[str, object]:
    env = dict(os.environ)
    if Path(shell).name not in {"bash", "zsh", "fish"}:
        return {"ok": False, "error": "unsupported_shell", "shell": shell}
    location = run([uv, "tool", "dir", "--bin"], env)
    if location.returncode:
        return {"ok": False, "error": "uv_tool_directory_unavailable"}
    directory_text = location.stdout.rstrip("\r\n")
    # uv writes this directory into shell configuration. Require a single absolute,
    # literal path; leave unusual shell-metacharacter paths for manual diagnosis.
    if not Path(directory_text).is_absolute() or any(c in directory_text for c in ':\r\n"`$\\'):
        return {"ok": False, "error": "unsupported_tool_directory"}
    directory = Path(directory_text)
    executable = directory / "runbuoy"
    result: dict[str, object] = {
        "ok": False,
        "bin_dir": str(directory),
        "executable": str(executable),
        "shell": shell,
        "repair_attempted": False,
    }
    if not executable.is_file() or not os.access(executable, os.X_OK):
        return {**result, "error": "cli_not_installed_in_uv_tool_directory"}
    version = run([str(executable), "--version"], env)
    if version.returncode:
        return {**result, "error": "installed_cli_failed_version_check"}
    result["version"] = version.stdout.strip()
    visible = shutil.which("runbuoy")
    result["current_process_on_path"] = bool(
        visible and Path(visible).resolve() == executable.resolve()
    )
    result["activate_current_shell"] = (
        f"set -gx PATH {shlex.quote(str(directory))} $PATH"
        if Path(shell).name == "fish"
        else f'export PATH={shlex.quote(str(directory))}:"$PATH"; hash -r'
    )
    clean_env = {**env, "SHELL": shell, "PATH": without_directory(env.get("PATH", ""), directory)}
    shells = probe(shell, clean_env, executable)
    if repair and not all(item["ok"] for item in shells.values()):
        # update-shell otherwise skips persistence when this Agent already has the
        # tool bin in PATH. Use uv's absolute path even when it shares that bin.
        result["repair_attempted"] = True
        update = run([uv, "tool", "update-shell"], clean_env)
        result["update_shell_exit_code"] = update.returncode
        shells = probe(shell, clean_env, executable)
    result["fresh_shells"] = shells
    result["ok"] = all(item["ok"] for item in shells.values())
    if not result["ok"]:
        result["error"] = "fresh_shell_path_unverified"
        result["hint"] = (
            "Check the user's shell startup files for PATH resets or early returns; "
            "do not report installation complete or reinstall the CLI to fix PATH."
        )
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repair", action="store_true", help="Allow uv to update shell configuration"
    )
    parser.add_argument(
        "--uv", default=shutil.which("uv"), help="Absolute uv executable if off PATH"
    )
    parser.add_argument(
        "--shell", help="User's terminal shell; defaults to SHELL or the login shell"
    )
    args = parser.parse_args()
    shell = args.shell or os.environ.get("SHELL") or pwd.getpwuid(os.getuid()).pw_shell
    shell = shutil.which(shell) or shell
    try:
        result = (
            ensure_path(shutil.which(args.uv) or str(Path(args.uv).absolute()), shell, args.repair)
            if args.uv
            else {"ok": False, "error": "uv_not_found"}
        )
    except subprocess.TimeoutExpired:
        result = {"ok": False, "error": "path_check_timeout"}
    except OSError as error:
        result = {"ok": False, "error": "path_check_failed", "detail": str(error)}
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
