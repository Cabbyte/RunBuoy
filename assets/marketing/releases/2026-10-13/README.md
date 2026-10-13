# 中文首页正式上线验收

- 线上地址：https://www.runbuoy.cloud/
- 变更 PR：https://github.com/Cabbyte/RunBuoy/pull/47
- 网站发布提交：`fc4aa39096c09c31d35e0de6898c1580d00f2e66`
- GitHub Pages：https://github.com/Cabbyte/RunBuoy/actions/runs/38363799118 （build、deploy 均成功）
- 发布日期：2026-10-13（Asia/Shanghai）。

本轮完整提交并发布已确认的中文首页、导航、文档上手流程与可复用素材；英文文案未修改。Figma 同步与 App Store 素材上传不属于本次网站发布。

## 验证

- 本地 `npm run check` 通过；仓库 Markdown 链接 620 项通过。
- 最终功能提交 `fbc61cd` 的 website、protocol-and-security、CodeQL、Python、CLI、服务端测试、operations-smoke、e2e-mock-apns 和 SBOM 检查通过。
- 归档时仓库通用 iOS 构建测试仍在运行；不将网站发布视为 iOS 发版或真机验收。
- `verify-production.mjs` 验证 9 个公网页面正常返回、新中文导航和配对入口存在，以及 5 个品牌素材与仓库 SHA-256 完全一致。数据见 `production-checks.json`。
- 浏览器实测首页 → 快速开始，安装/配对按钮、配对复制反馈、下一页运行任务及下载二维码；见 `browser-checks.json`。
- `production-home.png` 与 `production-download.png` 为部署完成后的真实线上截图。

此目录仅增加发布证据，不修改网页构建输入。
