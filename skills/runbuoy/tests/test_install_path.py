"""Exercise the real uv updater and real shell startup, isolated from the user's home."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

import pytest

HELPER = Path(__file__).resolve().parents[1] / "scripts" / "ensure_cli_path.py"
UV = shutil.which("uv")
pytestmark = pytest.mark.skipif(UV is None, reason="uv is required for shell integration checks")


def execute(argv: list[str], env: dict[str, str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(  # noqa: S603 - fixed commands in an isolated temporary home
        argv, env=env, cwd=env["HOME"], capture_output=True, text=True, timeout=60, check=False
    )


@pytest.fixture(params=["bash", "zsh", "fish"])
def shell(request: pytest.FixtureRequest) -> str:
    executable = shutil.which(request.param)
    if executable is None:
        pytest.skip(f"{request.param} is not installed")
    return executable


@pytest.fixture
def isolated_env(tmp_path: Path, shell: str) -> dict[str, str]:
    env = {
        "HOME": str(tmp_path),
        "SHELL": shell,
        "PATH": os.defpath,
        "TERM": "dumb",
        "LANG": "C.UTF-8",
        "UV_TOOL_DIR": str(tmp_path / "uv-tools"),
        "UV_TOOL_BIN_DIR": str(tmp_path / "自定义 tools" / "bin"),
        "UV_CACHE_DIR": str(tmp_path / "cache"),
        "UV_OFFLINE": "1",
        "UV_PYTHON_DOWNLOADS": "never",
        "XDG_CONFIG_HOME": str(tmp_path / "config"),
        "XDG_DATA_HOME": str(tmp_path / "data"),
    }
    if Path(shell).name == "zsh":
        # uv must honor the user's startup directory instead of assuming ~/.zshrc.
        env["ZDOTDIR"] = str(tmp_path / "zsh config")
        Path(env["ZDOTDIR"]).mkdir()
    return env


def install_fixture(env: dict[str, str], *, broken: bool = False) -> Path:
    executable = Path(env["UV_TOOL_BIN_DIR"]) / "runbuoy"
    executable.parent.mkdir(parents=True, exist_ok=True)
    executable.write_text("#!/bin/sh\n" + ("exit 1\n" if broken else "printf 'runbuoy 0.0.0\\n'\n"))
    executable.chmod(0o755)
    return executable


def check(env: dict[str, str], *, repair: bool = True) -> dict:
    command = [sys.executable, str(HELPER), "--uv", str(UV)]
    if repair:
        command.append("--repair")
    response = execute(command, env)
    result = json.loads(response.stdout)
    assert response.returncode == (0 if result["ok"] else 1), response.stderr
    return result


def home_contents(env: dict[str, str]) -> dict[str, bytes]:
    return {str(path): path.read_bytes() for path in Path(env["HOME"]).rglob("*") if path.is_file()}


def test_repairs_hidden_executable_and_persists_without_inherited_path(isolated_env: dict) -> None:
    executable = install_fixture(isolated_env)
    before = home_contents(isolated_env)
    inspection = check(isolated_env, repair=False)
    assert not inspection["ok"]
    assert not inspection["repair_attempted"]
    assert home_contents(isolated_env) == before

    result = check(isolated_env)
    assert result["ok"], result
    assert result["repair_attempted"]
    assert not result["current_process_on_path"]
    assert result["executable"] == str(executable)
    assert all(item["ok"] for item in result["fresh_shells"].values())

    # The helper cannot mutate its caller. Its activation must work in the actual
    # current shell too, without relying on another shell's startup files.
    activate = result["activate_current_shell"] + "; runbuoy --version"
    response = execute([isolated_env["SHELL"], "-c", activate], isolated_env)
    assert response.returncode == 0, response.stderr
    assert "runbuoy 0.0.0" in response.stdout

    persisted = home_contents(isolated_env)
    second = check(isolated_env)
    assert second["ok"]
    assert not second["repair_attempted"]
    assert home_contents(isolated_env) == persisted


def test_repairs_when_uv_skips_because_agent_already_has_path(isolated_env: dict) -> None:
    install_fixture(isolated_env)
    visible_env = {
        **isolated_env,
        "PATH": isolated_env["UV_TOOL_BIN_DIR"] + os.pathsep + isolated_env["PATH"],
    }
    before = home_contents(isolated_env)
    original_update = execute([str(UV), "tool", "update-shell"], visible_env)
    assert original_update.returncode == 0, original_update.stderr
    assert home_contents(isolated_env) == before
    assert not check(visible_env, repair=False)["ok"]

    result = check(visible_env)
    assert result["ok"], result
    assert result["current_process_on_path"]
    assert result["repair_attempted"]
    assert all(item["ok"] for item in result["fresh_shells"].values())


@pytest.mark.parametrize("broken", [False, True], ids=["absent", "broken"])
def test_does_not_register_path_for_missing_or_broken_cli(isolated_env: dict, broken: bool) -> None:
    if broken:
        install_fixture(isolated_env, broken=True)
    before = home_contents(isolated_env)
    result = check(isolated_env)
    assert not result["ok"]
    assert result["error"] == (
        "installed_cli_failed_version_check" if broken else "cli_not_installed_in_uv_tool_directory"
    )
    assert not result["repair_attempted"]
    assert home_contents(isolated_env) == before


def test_startup_path_reset_is_not_mistaken_for_success(isolated_env: dict) -> None:
    install_fixture(isolated_env)
    assert check(isolated_env)["ok"]
    shell = Path(isolated_env["SHELL"]).name
    if shell == "zsh":
        startup = Path(isolated_env["ZDOTDIR"]) / ".zshrc"
        reset = '\nexport PATH="/usr/bin:/bin"\n'
    elif shell == "bash":
        # uv's existing snippet precedes this user's final override. Re-running
        # update-shell can return nonzero; the fresh shells decide readiness.
        startup = Path(isolated_env["HOME"]) / ".bashrc"
        reset = '\nexport PATH="/usr/bin:/bin"\n'
    else:
        startup = Path(isolated_env["XDG_CONFIG_HOME"]) / "fish" / "config.fish"
        startup.parent.mkdir(parents=True, exist_ok=True)
        reset = "\nset -gx PATH /usr/bin /bin\n"
    with startup.open("a") as stream:
        stream.write(reset)
    result = check(isolated_env)
    assert not result["ok"]
    assert result["error"] == "fresh_shell_path_unverified"
    assert result["repair_attempted"]
    assert not result["fresh_shells"]["interactive"]["ok"]
    assert startup.read_text().endswith(reset)


def test_preserves_existing_startup_configuration(isolated_env: dict) -> None:
    install_fixture(isolated_env)
    shell = Path(isolated_env["SHELL"]).name
    if shell == "zsh":
        startup = Path(isolated_env["ZDOTDIR"]) / ".zshenv"
    elif shell == "bash":
        startup = Path(isolated_env["HOME"]) / ".bashrc"
    else:
        startup = Path(isolated_env["XDG_CONFIG_HOME"]) / "fish" / "config.fish"
        startup.parent.mkdir(parents=True, exist_ok=True)
    original = "# Existing user configuration — keep this intact.\n"
    startup.write_text(original)
    result = check(isolated_env)
    assert result["ok"], result
    assert startup.read_text().startswith(original)


def test_project_only_path_does_not_pass_as_global_install(isolated_env: dict) -> None:
    install_fixture(isolated_env)
    home = Path(isolated_env["HOME"])
    project = home / "project"
    project.mkdir()
    shell = Path(isolated_env["SHELL"]).name
    if shell == "fish":
        startup = Path(isolated_env["XDG_CONFIG_HOME"]) / "fish" / "config.fish"
        startup.parent.mkdir(parents=True, exist_ok=True)
        snippet = 'if test "$PWD" != "$HOME"\n  set -gx PATH "$UV_TOOL_BIN_DIR" $PATH\nend\n'
    else:
        startup = Path(isolated_env["ZDOTDIR"]) / ".zshenv" if shell == "zsh" else home / ".bashrc"
        snippet = 'if [ "$PWD" != "$HOME" ]; then\n  export PATH="$UV_TOOL_BIN_DIR:$PATH"\nfi\n'
    startup.write_text(snippet)
    response = subprocess.run(  # noqa: S603 - fixed helper and isolated project directory
        [sys.executable, str(HELPER), "--uv", str(UV), "--repair"],
        env=isolated_env,
        cwd=project,
        capture_output=True,
        text=True,
        timeout=60,
        check=False,
    )
    result = json.loads(response.stdout)
    assert result["ok"], result
    assert result["repair_attempted"]
    assert check(isolated_env, repair=False)["ok"]
