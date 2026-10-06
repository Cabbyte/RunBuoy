# 中文首页实现 · 2026-10-06

实现分支：`codex/homepage-figma`，从 `main` 创建。

## 设计来源

- Figma 文件：[RunBuoy 中文官网原型](https://www.figma.com/design/XeFw4ascc1qPtA3fIbcXvS)
- 桌面节点 `6:70`，手机节点 `6:198`。高保真设计上下文已保存在 `../../figma/homepage-2026-10-06/`。
- 采用项目已有 React / Rspress、Button、Link、copyToClipboard；没有新增运行时依赖。
- 中文首页使用设计稿的浅色营销样式；英文和文档继续使用原有主题与导航。

## 内容和行为

- 居中标题、独立吉祥物与水面图层、实际 iPhone 截图，以及可访问的原生大任务卡片。
- 桌面完整 ChatGPT 看板；手机采用设计稿中的可读任务摘要。
- Agent 安装优先，完整提示词与手动安装默认折叠；原安装提示词未修改，包含 PATH 修复与新终端验证。
- 复制成功有状态反馈；失败自动展开提示词供手动选择。
- “用于对话”链接到 ChatGPT 连接说明，不在营销页执行真实 Plugin 操作。
- 手机页尾保留使用文档与 English 入口；桌面语言菜单可切换英文。
- 不展示“示例数据”“新版预览”营销脚注。

## 验证

- `cd website && npm ci && npm run check`：TypeScript、生产构建、语言页面对应关系、静态内容与全站内部链接通过。
- 浏览器检查宽度：320、390、768、1024、1440；所有视口无页面横向溢出，768 宽度额外检查组件内部溢出。
- 1440 桌面与 390 手机完整页面按 Figma 核对，图片加载与实际尺寸已检查，全部图片为本地素材。
- 桌面和手机点击“连接我的电脑”可跳转；复制后回读剪贴板与 902 字符原文一致，含 `ensure_cli_path.py --repair`。
- 提示词和手动安装支持点击与 Enter 展开/关闭。
- 语言切换到 `/en/` 使用原始导航，没有中文首页；`/docs/` 保留原有文档导航。
- 生产预览 `http://127.0.0.1:4322/` 的安装跳转和复制反馈通过，控制台无警告/错误。
- 旁项记录：开发模式访问原有英文/文档导航时，NavHamburger + SwitchAppearance 有嵌套 button 警告。这两个组件与 main 相同，本次未扩展修改范围。中文新首页不包含此结构。

## 素材对应

| Figma 图层 | 本地素材 | 页面位置 |
| --- | --- | --- |
| 6:73 / 6:94 / 6:194 | `website/docs/public/marketing/zh-Hans/homepage/mascot-transparent.png` | 导航、首屏、隐私收尾 |
| 6:91 / 6:215 | `website/docs/public/marketing/zh-Hans/homepage/water-background.png` | 首屏背景 |
| 6:93 / 6:217 | `website/docs/public/marketing/zh-Hans/active-runs.jpg` | iPhone 屏幕 |
| 6:152 | `website/docs/public/marketing/zh-Hans/chatgpt-workspace.jpg` | 桌面 ChatGPT 看板 |

导出的原始 PNG 与项目内既有截图为同一设计素材；没有使用整页图片替代页面代码。

## 审阅截图

- `desktop-hero.png`：桌面首屏。
- `desktop-1440.png`：桌面完整页面。
- `mobile-390.png`：手机完整页面。
- `desktop-copy.png`：真实复制成功反馈。
- `responsive.json`：视口与溢出测量。
- `asset-manifest.json`：上线素材尺寸和 SHA-256。

## 本地运行

```sh
cd website
npm ci
npm run check
npm run preview -- --host 127.0.0.1 --port 4322
```

本次完成本地代码与生产构建验证，未推送、合并或部署线上网站。
