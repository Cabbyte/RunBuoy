---
description: Agent 报状态，ChatGPT 看全貌。用 Skill 安装、接入与上报任务，在 ChatGPT Plugin 的交互看板中查询进展。
---

# Agent 集成

**Agent 报状态，ChatGPT 看全貌。**

RunBuoy Skill 帮助 Agent 安装、接入任务并上报状态；ChatGPT Plugin 提供只读查询与交互看板。两者属于同一套 Agent 集成，也可以分别使用。

## Agent 报告任务状态

接入 RunBuoy Skill，让 Agent 报阶段、传结果，需关注时发消息。先把下方完整提示词交给支持 Skill 的 Agent，安装 Skill 与 CLI，验证当前会话和新终端均可直接运行 `runbuoy`。

## 前置条件

- Agent 支持从源码安装或导入 Skill；具体机制由 Agent 自己决定。
- 电脑运行 macOS 或 Linux；RunBuoy 本地运行需要 Python 3.12+ 与 `tmux`。
- 如果缺少 `uv` 或 `tmux`，Agent 会先说明需要执行的系统命令并等待确认。

Skill 源码位于 [GitHub 上的 `skills/runbuoy`](https://github.com/Cabbyte/RunBuoy/tree/main/skills/runbuoy)，必须完整保留 `SKILL.md`、`agents/openai.yaml`、`references/` 和 `scripts/` 目录。

## 复制完整安装提示词

复制下面整段提示词并粘贴给支持 Skill 的 Agent：

```text
请帮我安装并验证 RunBuoy：

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

汇报 Skill 是否能以 $runbuoy 被发现、CLI 路径与版本、当前及新终端的 PATH 验证结果、local_ready 和 delivery 状态。不要启动配对、Demo、被监控命令，也不要上传日志。
```

提示词不写死任何 Agent 产品的安装目录，因此可以交给 Codex 或其他支持 Skill 的 Agent。若 Agent 不支持安装 Skill，它应说明自身支持的手动方式，而不是猜测安装路径。

## 安全边界

- 已安装的 CLI 会先被检测，不会重复安装。
- `sudo`、系统包管理器与 curl 安装器都需要先获得你的确认。
- 安装时修复 PATH，并分别验证当前会话与新终端；随后读取版本、`local_ready` 与 `delivery` 状态。
- 安装过程不配对 iPhone、不运行 Demo、不启动被监控命令，也不上传日志。

## 安装后使用

在支持 Skill 调用的对话中，可以使用现有默认文案：

```text
Use $runbuoy to monitor this command safely from my iPhone.
```

然后在同一条请求中提供需要运行的完整命令。Agent 应先执行 RunBuoy 预检，保留 `--` 后的原命令，并且除非你明确要求，不上传完整日志或共享日志尾部。

安装不等于开始监控所有任务。安装完成后，按[配对指南](/guide/pairing)连接 iPhone，再明确告诉 Agent 要运行哪个命令。百分比与预计完成时间需要任务显式报告；普通命令仍可查看运行状态与结果。

<span id="chatgpt"></span>

## ChatGPT Plugin 与交互看板

**问一句，查进展；点一下，看全貌。**

在 ChatGPT 里问任务、查进展；打开 RunBuoy 看板，看运行、翻历史、找电脑、读消息。

![RunBuoy ChatGPT 看板示例，包含运行列表与任务详情](/marketing/zh-Hans/chatgpt-workspace.jpg)

*图为本地产品界面预览，使用示例数据。Plugin 当前为私人预览，尚未在公共目录全面开放。*

可以从这些问题开始：

- 「训练跑到哪一步了？」
- 「哪些任务需要我关注？」
- 「这台电脑最近完成了什么？」

**选中任务，接着聊。** 在详情中点「用于对话」，把这条任务作为后续提问的上下文，再输入你的问题。该按钮不会自动发送消息或执行命令。

### 连接与授权

已获得私人预览访问权限时，在 ChatGPT 中添加 RunBuoy Plugin，按连接流程使用 iPhone 扫描或打开授权链接，核对工作区与只读权限后确认。可在 iPhone 的 Agent 连接管理中撤销授权。尚无预览权限时，可以先使用 Skill 与 iPhone；[访问源码与预览说明](https://github.com/Cabbyte/RunBuoy/tree/main/plugins/runbuoy)。

Plugin 与 iPhone 查看同一工作区的数据。看板展示最近确认的状态，并定期刷新；实时活动与系统通知由 iPhone 提供。Plugin 不能启动、停止或重试任务，也不代替任务上报。
