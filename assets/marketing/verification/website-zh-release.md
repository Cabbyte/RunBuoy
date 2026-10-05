# 中文网站发布记录

日期：2026-10-05。开发基线 `main` / `45930228`，分支 `codex/website-zh-release`。

## 内容

- H01：扫一眼，掌握任务的进展。H02：安装交给 Agent，状态带到 iPhone。阶段、结果随手看，重要消息随身收。
- S01 / S02：从 Agent 到脚本，从训练到构建；任务分头跑，进展一处看。
- Agent 集成采用 v3：Skill 上报阶段、结果和需关注消息；ChatGPT Plugin 只读查询与交互看板，私人预览。
- 中文下载、快速开始、Agent 集成、安装、文档入口、安全与隐私说明同步。安装提示词包含 scripts/ 与 PATH 的当前／新终端验收。
- 中文分享卡片与官网使用同一主标题。实际界面来源与示例数据注明；App Store 图不在本轮发布范围。
- 中文首页使用独立组件与 CSS 前缀，英文页面、旧首页和英文分享图保持原样。

## 检查

- 网站 TypeScript、生产构建、语言路径对等、站内资源链接、中文安装提示词一致性：通过，日志见 [website-zh-release-check.txt](website-zh-release-check.txt)。
- [14 个英文页面的可见文字对比](website-zh-english-preservation.json)：与 main 基线全部一致。
- 协议与 Skill 测试：29 passed，7 skipped（本机无 Fish）；Ruff 与 Markdown 链接检查通过。
- 浏览器实测桌面与窄屏布局无横向溢出，Agent 提示词可见，手动步骤默认折叠且可展开／收起。复制按钮返回「已复制」，DOM 中完整提示词包含 PATH 修复脚本；独立剪贴板读取未作为本轮验收依据。实际 CSS 视口宽度为 1066 和 325，均无溢出。
- 官方 App Store lookup：2026-10-05 查得版本 1.0.4，最低 iOS 18.0，价格 0。官网使用新版 main 界面预览，已在画面旁标注。

本记录在提交前保存。最终提交、GitHub Pages 工作流与线上验证另记到发布结果，不以本地构建替代线上验收。
