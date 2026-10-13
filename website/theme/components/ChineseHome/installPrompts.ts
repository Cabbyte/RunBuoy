export const AGENT_PROMPTS = {
  zh: `请帮我安装并验证 RunBuoy：

1. 使用你原生支持的 Skill 安装机制，从
https://github.com/Cabbyte/RunBuoy/tree/main/skills/runbuoy
安装或更新 RunBuoy Skill，完整保留 SKILL.md、agents/openai.yaml、references/ 和 scripts/ 目录，不要猜测安装路径。

2. 读取该 Skill 的 references/installation.md，按其中的规则检测 CLI。先检查 command -v runbuoy；找不到命令且 uv 已可用时，用 uv tool dir --bin 检查实际目录中是否已有 runbuoy。已安装但不在 PATH 中时修复路径，不要重复安装；确实未安装且 uv 已可用时，执行：
uv tool install --python 3.12 runbuoy

3. 如果缺少 uv、tmux，或者需要 sudo、系统包管理器或 curl 安装器，请先说明将执行的命令并等待我的确认。

4. 对 uv 安装的 CLI，按安装文档运行 Skill 自带的 scripts/ensure_cli_path.py --repair，验证移除临时 PATH 后，新开的交互式终端和登录终端都能找到命令。再按输出在当前执行 Shell 中启用 PATH、刷新命令缓存。后续独立工具调用也需保留该 PATH。不要把绝对路径可运行或 uv run 成功当作安装完成；若验证失败，继续检查 Shell 配置并说明未通过的项目。

5. 在当前 Shell 直接运行：
command -v runbuoy
runbuoy --version
runbuoy doctor --json
runbuoy capabilities --json

汇报 Skill 是否能以 $runbuoy 被发现、CLI 路径与版本、当前及新终端的 PATH 验证结果、local_ready 和 delivery 状态。不要启动配对、Demo、被监控命令，也不要上传日志。`,
  en: `Help me install and verify RunBuoy:

1. Use your native Skill installation mechanism to install or update the RunBuoy Skill from
https://github.com/Cabbyte/RunBuoy/tree/main/skills/runbuoy
Preserve SKILL.md, agents/openai.yaml, references/, and scripts/ in full. Do not guess an installation path.

2. Read references/installation.md from that Skill and follow its rules to detect the CLI. Start with command -v runbuoy. If it is not found and uv is available, use uv tool dir --bin to check for an existing runbuoy executable. Repair PATH for an installed CLI instead of reinstalling it. Only if it is absent and uv is available, run:
uv tool install --python 3.12 runbuoy

3. If uv or tmux is missing, or sudo, a system package manager, or a curl installer is required, explain the exact command and wait for my approval.

4. For a uv-installed CLI, follow the installation reference to run the Skill's scripts/ensure_cli_path.py --repair. Verify that fresh interactive and login shells find the command without inheriting the temporary PATH entry. Apply the reported PATH activation in the current execution shell and refresh its command cache. Keep that PATH in subsequent independent tool calls too. An absolute executable path or a successful uv run is not proof of a complete installation. If verification fails, investigate shell configuration and report the incomplete checks.

5. Run these commands directly in the current shell:
command -v runbuoy
runbuoy --version
runbuoy doctor --json
runbuoy capabilities --json

Report whether the Skill is discoverable as $runbuoy, the CLI path and version, PATH verification in the current and fresh terminals, local_ready, and delivery status. Do not start pairing, a demo, or any monitored command, and do not upload logs.`,
} as const;

export const PAIRING_PROMPT_ZH = `请帮我将这台电脑与 RunBuoy iPhone App 配对：

1. 先确认 command -v runbuoy 和 runbuoy --version 能直接运行。若已安装但 PATH 不可用，读取现有 RunBuoy Skill 的 references/installation.md，按原有流程修复并验证当前及新终端的 PATH，不要重复安装。尚未安装时先说明情况，不要把配对当作安装成功。

2. 运行 runbuoy device status --check-server --json，分别检查 paired、pairing_pending 与 server_reachable。已经配对时报告现有连接状态，不要重新配对或解除配对；服务器不可达不代表未配对。

3. 如果已有待完成会话，先询问我是否已扫码；确认后优先运行 runbuoy device pair --resume。仅在命令明确报告会话已过期时重新发起，不要删除凭证来重置会话。

4. 尚未配对且没有待完成会话时，运行 runbuoy device pair --no-wait。展示命令实际输出的二维码或短期配对码，不要猜测或生成代码。提示我在 iPhone 打开 RunBuoy → 设置 → 配对新电脑，扫码并确认电脑身份；无法扫码时可选择使用配对码。不要代替我在 iPhone 上确认。

5. 等我确认已扫码后，运行 runbuoy device pair --resume，然后运行 runbuoy device status --check-server --json 和 runbuoy doctor --json。分别汇报本地配对状态、服务器可达性与 delivery 状态，不要把服务器健康等同于 iPhone 已收到任务消息。

不要启动 Demo、被监控任务或上传日志，不要解除现有配对。`;
