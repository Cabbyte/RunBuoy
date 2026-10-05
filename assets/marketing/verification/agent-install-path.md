# Agent 安装 PATH 修复

2026-10-05。修复基于 `main` 的 `45930228`，工作分支 `codex/agent-install-path`；安装提示词、Skill、脚本与相关文档已同步到 `codex/marketing-launch`。尚未合并或发布。

## 复现与修复

旧提示词在 `uv tool install` 后直接调用 `runbuoy`，没有要求持久 PATH 配置和新终端验证。另一个可稳定复现的情况是：Agent 的临时 PATH 已含 uv 工具目录，`uv tool update-shell` 因此跳过配置更新；移除继承的工具目录后，新终端找不到命令。这是与用户报告一致的一条失败路径，不能据此确定每一次偶发现象都来自相同原因。

新流程先查询实际 uv bin 目录，区分“未安装”与“已安装但命令不可见”。随 Skill 分发 `scripts/ensure_cli_path.py`，以 `--repair` 调用 uv 的原生配置更新，并从不含临时工具目录的环境启动交互式、登录交互式 Shell 验证。Agent 另需在当前执行 Shell 启用 PATH、刷新缓存并直接调用 `runbuoy`；独立工具调用不能假定前一次子进程的 export 会持续生效。

新中英文提示词保留 `scripts/`，报告实际 CLI 路径及两层检查结果。官网首页、快速开始、Skill 文档的可复制提示词增加一致性检查；营销首页仍然以 Agent 为主入口，手动安装保持折叠。

## 验证

- `uv run pytest packages/protocol/tests skills/runbuoy/tests -q`：29 passed，7 skipped；跳过项均为本机未安装的 Fish。新增测试在临时 HOME 中使用真实 uv 0.12.17 与 Bash / Zsh，覆盖未注册 PATH、Agent 已有临时 PATH、含空格和中文的自定义目录、重复执行不改写配置、缺失或损坏 CLI、配置随后覆盖 PATH，保留用户配置，以及防止项目专用 PATH 被误判为全局可用。
- Ruff 检查、格式检查、skill-creator 的 Skill 结构校验通过。
- 在临时 uv 工具环境安装 main 的实际 CLI 0.1.4，使用带空格和中文的 bin 目录。Bash / Zsh 的 `-ic`、`-lic` 均直接通过版本、doctor、capabilities 检查；`local_ready=true`。详见 [实际安装检查结果](agent-install-path-smoke.json)。这次只验安装：未配对、未创建 Run、未创建 RunBuoy 配置或凭证；测试目录已清理。
- 修复分支官网的 TypeScript、生产构建、语言对等、链接检查及提示词一致性检查通过。营销工作区的同一组网站检查日志见 [网站检查](agent-install-path-website-check.txt)。

测试没有更改真实用户的 Shell 配置或 RunBuoy 安装。Fish 的运行时行为和 Linux 主机尚未在本机实测；本轮未开启 iOS 模拟器，也没有验证手机推送。

## 重跑

```sh
uv run pytest packages/protocol/tests skills/runbuoy/tests -q
uv run ruff check skills/runbuoy/scripts skills/runbuoy/tests
cd website
npm run check
```

uv 行为依据：[uv tool update-shell](https://docs.astral.sh/uv/reference/cli/#uv-tool-update-shell)、[uv tool dir](https://docs.astral.sh/uv/reference/cli/#uv-tool-dir)。
