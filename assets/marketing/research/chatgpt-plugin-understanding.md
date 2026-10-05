# ChatGPT Plugin 与交互 UI：产品理解及卖点依据

核对日期：2026-10-05（Asia/Shanghai）。源码基线：当前 `main` 的 `45930228b7d59c4352b738f0daad51f67f3b76ae`。宣传文件仍保存在 `codex/marketing-launch` 工作树内。

## 在产品中的位置

用户明确指定：ChatGPT Plugin 及其 UI 是「Agent 集成」下的一个子项目。这个分类与「Agent 作为主要安装方式、手动安装折叠」同时成立。

| 子项 | 用户能做什么 | 对应价值 |
| --- | --- | --- |
| RunBuoy Skill | 让 Agent 安装、验证、接入经授权的任务，并报告阶段、结果与需关注消息 | Agent 报告任务状态 |
| ChatGPT Plugin 与交互看板 | 用自然语言查询同一工作区的任务，打开交互界面，选中任务继续对话 | 问一句，查进展；点一下，看全貌 |

Plugin 和 iPhone 使用相同的服务端任务数据。电脑执行并上报，iPhone 与 ChatGPT 提供两种查看入口。Plugin 不是另一套任务执行器，也不会代替 iPhone 的通知和实时活动。

## 已理解的实际功能

1. **自然语言查询。** 六个只读工具覆盖打开 RunBuoy、当前概览、任务详情、事件时间线、任务与消息历史、电脑列表。可以询问「训练跑到哪一步了」「哪些任务需要关注」「这台电脑最近完成了什么」。回答依赖工具取得的实际数据。
2. **卡片与完整看板。** 对话卡片显示运行概览，可展开工作台。工作台有正在运行、历史、电脑、消息四个视图，并可按电脑筛选；任务详情包含状态、阶段、进度、确认时间、消息、事件，以及明确共享的日志片段。
3. **从界面继续对话。** 详情中的「用于对话」调用 `updateModelContext`，传递选中任务的 ID 与标题，并提示模型先读取最新详情。它让后续提问知道指的是哪条任务；按钮本身不自动发送提问、作出诊断或运行命令。
4. **两种查看入口，同一份状态。** iPhone 适合随身查看与接收系统通知；ChatGPT 适合询问、展开看板与围绕指定任务继续讨论。当前 UI 采用周期刷新，并展示最后确认时间，不能宣传为毫秒同步或所有客户端始终在线。
5. **授权与执行分开。** Plugin 的查看授权在 iPhone 确认，并可从 iPhone 撤销。工具为只读；执行、停止、重试、远程审批均不属于 Plugin 功能。

## 本轮证据

- 已通过当前安装的 RunBuoy MCP 调用 `open_runbuoy({})`，成功读取任务快照。这验证当前连接可读；未把运行记录或共享日志复制到宣传目录。
- 已读当前 `server/app/plugin_mcp.py`、`apps/chatgpt/src/Dashboard.tsx`、`bridge.ts`、`i18n.ts`、`plugins/runbuoy/plugin.json` 与 `docs/features/chatgpt.md`。
- 使用当前 main 的 `apps/chatgpt` 开发预览和内置 `demo.ts`，浏览卡片、展开看板、任务详情、历史、电脑、消息；保存了五张[示例界面原图](../sources/chatgpt-plugin/README.md)。这些图片由实际产品代码渲染，数据为 fixture。
- 本轮没有取得宿主中已展开的 MCP Apps 面板；UI 截图来自本地开发预览，不是这次 ChatGPT 宿主的视觉验收。「用于对话」的上下文传递根据源代码核对，未把 demo 的空实现当作真实模型上下文验收。
- 文档将 Plugin 标为 private preview；可写入特色能力，但不据此宣称已在公共插件目录全面开放。

## 营销落点

- 在官网「Agent 集成」之下并列展示 Skill 与 ChatGPT Plugin；保留用户指定的「Agent 报告任务状态」。
- Plugin 需要独立的小标题、说明和看板画面，不能继续挤在 F09 句末。
- 重点依次是：**能问、能看、能接着聊**。OAuth、工具数量和协议名作为资料依据，不进入主要宣传句。
- 候选 App Store 新图展示跨客户端查看能力：iPhone 的连接入口搭配 Plugin 看板，画面明确标注 ChatGPT，避免让用户误以为桌面看板就是 iPhone 原生界面。

具体文案与前后对照见 [Agent 集成卖点 v3](../copy-review/agent-integration-v3.md)。
