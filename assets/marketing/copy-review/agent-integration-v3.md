# Agent 集成：Skill + ChatGPT Plugin 与交互看板

日期：2026-10-05。按用户要求，将 ChatGPT Plugin 及其 UI 纳入 Agent 集成的子项目。本稿是对 v2 的增补；H01「扫一眼，掌握任务的进展。」、F08「Agent 报告任务状态」保留原句。官网代码和宣传图暂不替换。

## 卖点层级

**Agent 集成**

- **RunBuoy Skill：Agent 报告任务状态。** 负责主要安装路径、任务接入与阶段／结果／重要消息上报。
- **ChatGPT Plugin 与交互看板：问一句，查进展；点一下，看全貌。** 在对话里查询任务，在看板中展开详情，再围绕选中的任务继续聊。

## 之前与之后

| 编号／位置 | 之前（v2） | 之后（本轮建议） |
| --- | --- | --- |
| AG01 · Agent 集成总标题 | 尚未单独概括两个子项 | Agent 报状态，ChatGPT 看全貌。 |
| F08 · Skill 子项标题 | Agent 报告任务状态 | Agent 报告任务状态 |
| F09 · Skill 子项说明 | 接入 RunBuoy Skill，Agent 报阶段、传结果，需关注时发消息；连上 Plugin，对话里查任务、看历史、读消息。 | 接入 RunBuoy Skill，让 Agent 报阶段、传结果，需关注时发消息。 |
| CP01 · Plugin 子项名称 | 仅在 F09 句末提到 Plugin | ChatGPT Plugin 与交互看板 |
| CP02 · Plugin 子项标题 | 对话里查任务、看历史、读消息。 | 问一句，查进展；点一下，看全貌。 |
| CP03 · Plugin 子项说明 | 未体现交互 UI | 在 ChatGPT 里问任务、查进展；打开 RunBuoy 看板，看运行、翻历史、找电脑、读消息。 |
| CP04 · 从界面继续聊 | 未提及 | 选中任务，接着聊。 |
| CP05 · 对话衔接说明 | 未提及 | 在详情中点「用于对话」，把这条任务作为后续提问的上下文。 |
| A07.T · 候选新增宣传图标题 | 未单独展示 ChatGPT Plugin | 对话问进展，看板看全貌。 |
| A07.S · 候选新增宣传图副标题 | 未单独展示 Plugin UI | 在 ChatGPT 里查看 RunBuoy，任务、历史、消息一处看；选中任务，接着聊。 |

## 适合配在画面旁的提问示例

- 「训练跑到哪一步了？」
- 「哪些任务需要我关注？」
- 「这台电脑最近完成了什么？」

这些是能力示例，不是伪造的真实对话或自动生成结论。

## 官网与宣传图的安排

官网在「Agent 集成」中给 Skill、ChatGPT Plugin 各一个子项；Plugin 配完整看板实截，并保留「用于对话」按钮所在的细节。Skill 仍负责安装主入口，手动步骤继续折叠。

候选新增宣传图 A07 归在 Agent 集成主题下。画面说明写清「ChatGPT Plugin」，以 iPhone 授权连接入口与实际 Plugin 看板呼应；目前保存的是看板原图与候选文案，尚未生成新宣传图。前六张的编号与原图不变。

Plugin 当前仍按项目的 private preview 定位说明。公开投放时按实际开放范围标注；不把查看授权写成任务控制权限，不暗示未知进度可自动算出百分比。

功能依据与证据见 [Plugin 产品理解](../research/chatgpt-plugin-understanding.md)，可复用截图见 [Plugin 原图](../sources/chatgpt-plugin/README.md)。本轮补充取代 v2 把 Plugin 混在 F09 末尾的写法，其余 v2 文案继续保留待审阅。
