# 宣传文案审阅入口

[逐条审阅文档](copy-review.md)收录当前官网与宣传图的 192 条中英文表述。每条包含编号、原文、位置、表达意图、审阅备注和源文件链接；这是讨论稿，尚未确认新的卖点排序。

[文案建议 v1：当前表述与建议表述](copy-proposals-v1.md)对应对话中列出的 20 条重点中文文案，尚未替换成品。

[文案建议 v2：短句与对偶](copy-proposals-v2.md)保留用户指定的 H01、F08，补充 Plugin 功能，并逐条对照 v1；中文仍为审阅稿。

[Agent 集成卖点 v3](agent-integration-v3.md)进一步把 Skill 与 ChatGPT Plugin／交互看板分为同一特色下的两个子项，补充「用于对话」能力，并保留前后对照。对应的[产品理解](../research/chatgpt-plugin-understanding.md)与[界面原图](../sources/chatgpt-plugin/README.md)一并入库。

| 编号 | 内容 |
| --- | --- |
| H / HX | 官网首屏、按钮及图片说明 |
| F / S | 功能与使用场景 |
| I / G | 安装区与完整 Agent 安装提示词 |
| P / C / U | 数据边界、收尾与辅助反馈 |
| N | 导航与页脚 |
| A01–A06 | 六张 App Store 宣传图；T 为标题，S 为副标题 |
| O | 分享卡片 |
| D / Q | 下载页与快速开始 |

可以直接用「H01 改为……」「A05.S 不要强调 CLI」记录反馈。先修改对应源文案，再更新图像成品；不要仅修改生成的审阅文档。

- `review-introduction.md`：可编辑的审阅说明与产品事实边界。
- `copy-inventory.json`：同一清单的结构化版本，带源文件哈希。
- `before-agent-priority.json`：安装层级调整前的原文快照。
- `../sources/copy.json`：App Store 图及分享卡片的文案源。

在仓库根目录运行以下命令可重建清单（使用网站现有依赖）：

```sh
node assets/marketing/scripts/export-copy-review.mjs
```

2026-10-03 已按用户要求完成 Agent 安装优先、手动安装折叠。其他营销文案及 App Store 成品仍保留现状，等待逐条反馈。

2026-10-05 已补齐 Agent 安装的 PATH 修复与当前／新终端验证。新增 G07，保留原有 G01–G06 编号；清单同步到 192 条。实现与验证记录见 [PATH 修复记录](../verification/agent-install-path.md)。
