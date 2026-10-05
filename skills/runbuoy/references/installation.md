# Installation routing

## Global CLI

Check the current shell first:

```sh
command -v runbuoy
```

If it is missing, do not assume the package is absent. If `uv` is available, resolve
the actual executable directory (including `UV_TOOL_BIN_DIR` / XDG overrides):

```sh
runbuoy_bin_dir="$(uv tool dir --bin)"
test -x "$runbuoy_bin_dir/runbuoy"
```

If that executable exists, repair PATH without reinstalling. Only when the executable
is absent does an explicit RunBuoy request authorize:

```sh
uv tool install --python 3.12 runbuoy
```

### Register PATH and prove it persists

After a uv installation, or when its executable is hidden from PATH, run the installed
Skill's bundled helper. Replace the placeholder with the actual Skill location reported
by the host; do not guess an Agent-specific installation directory:

```sh
uv run --no-project --python 3.12 /actual/skill/path/scripts/ensure_cli_path.py --repair
```

The helper uses `uv tool dir --bin` and checks the user's interactive and login-interactive
shells with the tool directory removed from their inherited PATH. If needed it calls
`uv tool update-shell` under that same clean PATH. This avoids uv skipping persistent
registration just because the installing Agent already has a temporary PATH entry.
It does not install packages, pair a phone, start a Run, or read credentials.

Require `ok == true` and both `fresh_shells` checks to pass. The helper cannot modify
its parent shell: apply its `activate_current_shell` command in the **current execution
shell**, adapting syntax if the Agent uses a different shell from the user's terminal.
For bash/zsh:

```sh
runbuoy_bin_dir="$(uv tool dir --bin)"
export PATH="$runbuoy_bin_dir:$PATH"
hash -r
command -v runbuoy
runbuoy --version
```

For fish, use `set -gx PATH "$runbuoy_bin_dir" $PATH` with a fish-local variable instead.
Do not source a user's entire shell configuration into a different shell. An export in
one tool subprocess does not update the Agent's parent process or later non-login tool
calls: keep the explicit PATH prefix in those calls until the host environment refreshes.

Do not report installation complete merely because an absolute executable path, `uv run`,
or an import worked. Report the resolved executable, current-shell direct command check,
and both fresh-shell checks separately. If startup files overwrite PATH, the helper
times out, or the shell is unsupported, report the specific incomplete check and repair
the actual user startup configuration; never hide the failure by reinstalling or adding
an alias. Existing terminals may still need the reported activation command or a restart.

If an existing executable is managed by something other than uv, preserve its installation
method. Inspect its real location and verify it in the current and fresh user shells;
do not overwrite it with a uv installation just to change PATH.

Then verify in the shell where the command is directly available:

```sh
runbuoy --version
runbuoy doctor --json
runbuoy capabilities --json
```

If `uv` itself is absent, or tmux needs installation, consult
`docs/user-guide/installation.md`. Ask before using sudo, a system package manager, or a curl
installer. Do not weaken sandbox or approval rules. macOS/Linux, Python 3.12+, and tmux are the
supported local runtime.

## Project Python API

Only install the project API when the user explicitly asks for instrumentation/code changes.
Use the project's actual interpreter (for example `uv run python`, `.venv/bin/python`, or the
declared runtime), not whichever `python` happens to be global. Check import with that interpreter.

For PEP 621/uv projects, keep RunBuoy out of default business dependencies:

```sh
uv add --optional runbuoy runbuoy
uv sync --extra runbuoy
```

This creates an optional extra named `runbuoy`. For requirements-based projects, create a
separate `requirements-runbuoy.txt` containing `runbuoy`; do not add it to the default
requirements file.

Global CLI and project API environments are intentionally separate. Install both when both are
needed. If the project's Python range is incompatible with Python 3.12+, do not change it without
the user's decision.
