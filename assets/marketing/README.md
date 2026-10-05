# RunBuoy 宣传素材

2026-10-05 中文网站发布版本已采用 v2 文案与 v3 Agent 集成方案，并加入 PATH 安装修复。英文页面和 App Store 宣传图本轮不替换；下方的双语稿、旧截图及其状态记录作为迭代历史保留。发布说明见 [中文网站发布记录](verification/website-zh-release.md)。

第一轮官网和商店截图使用「离开电脑，也知道任务跑到哪了」。素材基于 `main` 的真实原生界面与本地示例数据；App Store 素材随新版 App 一起替换。以下审阅稿记录后续的文案与卖点调整。

2026-10-03 文案进入逐条审阅，主卖点与措辞尚未定稿。完整中英文清单见 [192 条文案审阅](copy-review/copy-review.md)，可按编号反馈。已按用户明确要求把 Agent 安装设为默认展示、手动安装设为折叠；商店图暂保留原文，待文案确认后统一重出。

2026-10-05，用户明确将 ChatGPT Plugin 及其交互 UI 归入 Agent 集成子项。新增 [Agent 集成卖点 v3](copy-review/agent-integration-v3.md)、[功能理解](research/chatgpt-plugin-understanding.md)与[五张 Plugin 界面原图](sources/chatgpt-plugin/README.md)。卖点突出「询问任务、展开看板、选中后继续对话」；这些仍为候选文案和参考素材，尚未替换已生成的官网与商店图。

## 可交付文件

| 内容 | 位置 |
| --- | --- |
| 简体中文 App Store 图，按 01–06 上传 | [promoted/app-store/zh-Hans](promoted/app-store/zh-Hans) |
| 英文 App Store 图，按 01–06 上传 | [promoted/app-store/en-US](promoted/app-store/en-US) |
| 中文六图总览 | [verification/app-store-zh-Hans-overview.jpg](verification/app-store-zh-Hans-overview.jpg) |
| 英文六图总览 | [verification/app-store-en-US-overview.jpg](verification/app-store-en-US-overview.jpg) |
| 官网图片和中英分享卡片 | [promoted/web](promoted/web) |
| 官网实际代码 | [website](../../website) |
| 检查记录与网页截图 | [verification](verification/README.md) |

每种语言六张图依次介绍：锁屏进度、成功与失败、多机任务、阶段与进度、扫码配对、数据边界。导出为 **1320 × 2868、sRGB、不含透明通道的 PNG**，对应 Apple 接受的 iPhone 6.9 英寸竖图规格。[Apple 截图规范](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)（2026-10-03 核实）。

`promoted` 表示本轮选定的交付素材，**不表示已经发布**。本轮没有部署官网、上传 App Store Connect 或发布新版 App。

## 版本与素材来源

- 界面基线：`main` 的 `9ad840519fe8e5ff66ad9dd4a71c8c1b30b34177`，项目版本 `1.0.6 (1)`。配对、数据页面与本地实时活动使用 Debug 专用入口进入；不改变 Release 的功能或布局。
- 原始截图：[sources/screenshots](sources/screenshots)，中英各六张、每张 1320 × 2868。设备为 iPhone 17 Pro Max / iOS 27.0 模拟器。任务、机器名和进度均为构造的展示数据；界面由 App 和 ActivityKit 实际渲染。锁屏图只证明本地实时活动展示，不是远程 APNs 送达验证。
- 原始截图的启动参数、哈希与裁切坐标：[sources/captures.json](sources/captures.json)。排版只做裁切、缩放、加边框与标题；不重绘或替换 App 内文字。
- 可编辑宣传文案：[sources/copy.json](sources/copy.json)。图中百分比与预计时间仅用于显式上报进度的任务；普通命令仍只有状态、运行时间和结果。
- 品牌插画原图与生成提示词：[sources/generated](sources/generated/README.md)。只用于官网品牌氛围与分享卡片，不用生成图伪装 App 界面。
- 设计参考：[research/design-references](research/design-references/设计参考与落地建议.md)。保留 Flighty、Structured、Pushcut、Working Copy、Chirp 等来源及实截，供内部研究；第三方画面没有进入 `promoted`。
- 上轮审查：[research/content-audit](research/content-audit/建议报告.md)。属于 2026-10-02 的历史状态，旧的「尚未开放」等文字不代表本轮交付。
- 有复用价值但未选用的画面：[drafts](drafts/README.md)。

## 修改与重新生成

需要 macOS、Xcode 和 Python 3，不需要额外绘图库。以下命令在仓库根目录执行：

```bash
swift assets/marketing/scripts/render.swift
python3 assets/marketing/scripts/validate.py
cd website
npm ci
npm run check
```

`render.swift` 从原始截图、文案 JSON 和品牌原图生成全部交付文件、总览图及导出清单，并同步官网使用的副本至 `website/docs/public/marketing` 和 `website/docs/public/og.png`。重新生成后还需要目视检查总览及浏览器：尺寸校验不能识别空白界面、错语言、文字遮挡。

需要替换界面时，先用 Xcode 构建并安装 Debug `RunBuoy`，选择一台专用 iPhone 17 Pro Max 模拟器，再执行：

```bash
SIMULATOR_UDID=<设备 UUID> bash assets/marketing/scripts/capture.sh zh-Hans active-runs
SIMULATOR_UDID=<设备 UUID> bash assets/marketing/scripts/capture.sh en-US run-detail
```

可用页面：`active-runs`、`history`、`run-detail`、`pairing`、`data`、`lock-screen`。脚本在截图前要求确认页面已渲染，避免采到启动画面。锁屏实时活动应为运行中、72%、约 47 分钟；若未自动出现，可在 App 的本地能力演示页启动实时活动。替换原图后同步更新 `sources/captures.json` 的版本、日期、参数与 SHA-256；验证脚本会检查来源哈希。

主 App 使用启动参数切换语言；Widget Extension 跟随模拟器系统语言，因此中英文锁屏截图之间还需在该专用模拟器上切换系统语言并重启。更换设备或系统版本后，先检查原图，再调整 `render.swift` 的裁切坐标，不能直接复用旧坐标。

官网主 CTA 是 App Store 下载，第二入口进入 Agent 安装区；手动安装与配对步骤默认折叠。发布时应与提供这些新界面的 App 版本协调，避免商店旧版和宣传图不一致。
