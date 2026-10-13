# RunBuoy 中文首页 · 网页化改版

日期：2026-10-06。分支：`codex/homepage-figma`。本轮仅交付本地审阅版本，未同步 Figma、推送或部署。

## 设计决策

- 四张已选效果图作为品牌风格参考，按实际浏览器窗口重新编排，不逐像素复刻海报。
- 居中首屏保留浮标、水面、手机与突出的大卡片。任务文字为网页内容，装饰与截图独立分层。
- 1160px 内容容器，桌面正文 18px，区块标题 36px；移动端正文 16–18px。手机布局在 768px 以下重排。
- 功能区用两台电脑任务、消息、锁屏三种证据替换重复训练卡。窄屏锁屏卡用可读的原生内容替代缩小截图。
- Agent 区域左侧介绍 Skill，右侧展示 ChatGPT 任务详情的关键字段；完整原始看板可点击查看。只读、私人预览与 iPhone 确认说明保留。
- 安装提示词与 PATH 修复内容未修改；完整提示词与手动安装默认折叠。网页 CTA“用于对话”改为“了解 ChatGPT 接入”。
- 按钮保持蓝紫渐变，颜色稍加深以确保白色文字对比度；蓝色正文链接同样加深。

## 审阅文件

- `1280-hero.jpg`、`1440-hero.jpg`：桌面首屏。
- `1440-page.jpg`：桌面整页；`390-page.jpg`：手机整页。
- `768-*`、`320-*`：平板与窄手机检查。
- `features-desktop.jpg`、`agents-desktop.jpg`、`install-desktop.jpg`：关键区块。
- `mobile-lock-and-agents.jpg`：窄屏锁屏卡片。
- `comparison.html`、`comparison.jpg`：四张效果图与网页的并排对照。HTML 中引用的原图已在项目内保存。
- `copy-success.jpg`、`copy-failure.jpg`、`keyboard-focus.jpg`：交互证据。
- `iteration-1/`：中间版本，仅供设计迭代对照；最终验收使用本目录文件。
- `asset-manifest.json`：来源、尺寸及 SHA-256。四张设计参考与用户上传文件的 SHA-256 一致。
- `viewport-checks.json`、`interaction-checks.json`、`build-check.txt`：验收记录。
- 完整视觉验收见 `website/design-qa.md`。

## 本地预览

```sh
cd website
npm run check
npm run preview -- --host 127.0.0.1 --port 4322
```

访问 http://127.0.0.1:4322/ 。英文首页与文档继续使用原有导航和主题。
