# 中文首页：方案一实现与审阅

日期：2026-10-06。工作区 `codex/homepage-figma`。本轮只交付本地审阅版本。

## 审阅入口

- 本地网页：http://127.0.0.1:4322/
- 选定方向：`../../reviews/homepage-layout-2026-10-06/option-1-centered.png`
- 浏览器截图：`final/1280-hero.jpg`、`final/1440-page.jpg`、`final/390-hero.jpg`、`final/390-page.jpg`。
- 同宽并排对照：`final/comparison.jpg`；可复现展示文件 `comparison-final.html`。
- 第一轮过程：`iteration-1/`；上一版页面：`../homepage-web-2026-10-06/`；上一版 QA：`previous-design-qa.md`。
- 网站最新 QA：`../../../../website/design-qa.md`。

## 实现决策

首屏采用居中文字与双入口，左浮标、中间 470px 原生任务卡、右侧真实产品截图，共用水面。首屏装饰有独立尺寸约束，避免将海报整体放大。低于 1024px 将卡片与辅助视觉分行；320px 隐藏辅助手机，保留可读卡片与小浮标。

任务区移除列表大外框，使用不同电脑的两项任务；右侧在真实锁屏上下文中叠加原生通知和实时活动，保障文字可读。Agent 区域保留 Skill 主线，ChatGPT 用查询气泡与嵌入式看板展示，私人预览、只读与 iPhone 确认说明保持可见。展示控件是静态产品演示，接入链接进入现有文档。

安装与配对共用 CopyPrompt 组件，各自保存复制反馈和折叠状态。安装提示词原文与 PATH 检查保持不变；新增配对提示词独立入口，先查 CLI/配对状态，等待 iPhone 扫码确认后恢复会话，不自动解除已有配对或启动任务。两个提示词的审阅副本保存在本目录，运行时仍以 installPrompts.ts 为唯一来源。

## 证据与边界

五档视口几何记录：`viewport-checks.json`。复制、故障注入、焦点和导航：`interaction-checks.json`。构建：`build-check.log`。

参考与实现截图在比较页中都按 600px 宽等比例显示；另外保留未缩放的实际视口截图。实现为真实网页且新增配对操作，整页高度不与生成海报做逐像素匹配。真实锁屏壁纸保留产品原图，并非参考图的蓝色装饰。

浏览器验证通过不等于真机安装/配对验收；本轮没有执行实际 CLI 安装、配对、任务或 App Store 下载，没有部署或同步 Figma。
