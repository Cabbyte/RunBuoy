# 官网内容、双语维护、构建与发布

RunBuoy 官网是位于 [`website`](../../website) 的 Rspress 2 静态站点，线上站点源地址配置为
`https://www.runbuoy.cloud`。它只负责产品介绍和文档，不承载 Server API，不读取用户的 Run，
也没有登录、配对或远程控制功能。

## 当前页面和用途

中文页面位于 `website/docs/zh`，英文镜像位于 `website/docs/en`：

| 路由 | 内容 |
| --- | --- |
| `/` | 产品首页：价值主张、Live Activity 视觉演示、三步上手、隐私和单向架构摘要 |
| `/docs/` | 使用文档入口 |
| `/guide/` | 快速开始和系统要求 |
| `/guide/install` | CLI 安装、升级、卸载、项目 Python API、tmux 和 Shell 补全 |
| `/guide/pairing` | 扫码、手工短码、暂停/恢复配对和连接检查 |
| `/guide/run` | 启动 Run、通知、本地管理、清理和日志尾部共享 |
| `/guide/progress` | structured、lines、regex、indeterminate 四种进度 |
| `/security` | 手机只读、凭证和本地进程隔离 |
| `/privacy` | 默认同步/不上传的数据、Token 和可选日志片段 |
| `/self-hosting` | Docker Compose、CLI 配置和生产注意事项 |
| `/download` | 中文下载页链接已上架的 App Store 版本，并引导 Agent 安装 |

语言切换由 `rspress.config.ts` 的 `zh`、`en` locales 提供。两种语言拥有对应 `_nav.json`
和 `guide/_meta.json`，分别控制顶部导航和指南侧栏排序。配置启用了 `languageParity`，新增或删除路径应保持两侧存在对应页面。

2026-10-05 用户明确选择先发布中文文案。中文首页独立使用 `theme/components/ChineseHome`，样式使用
`runbuoy-zh-` 前缀；英文继续使用原有组件和文档，勿将本轮中文发布扩展为英文改稿。根地址不按浏览器语言
自动跳转，英文入口仍为 `/en/`。中文分享卡片单独放在 `/marketing/zh-Hans/og.png`，不覆盖英文现用的 `/og.png`。

## 中文首页与文案来源

中文采用「扫一眼，掌握任务的进展。」；安装交给 Agent，手动安装默认折叠。
「Agent 集成」包含两个子项：Skill 负责安装与任务上报，ChatGPT Plugin 提供只读查询与交互看板，当前标注私人预览。

- 首页文案：`website/docs/zh/index.mdx` 与 `website/theme/components/ChineseHome`。
- 安装提示词：`ChineseHome/installPrompts.ts` 的 `zh`，并同步中文快速开始与 Agent 文档；`check:site` 校验一致性。
- 图片：`website/docs/public/marketing/zh-Hans`。它们来自实际产品界面与展示数据，页面明确标注新版预览。
- 可复用原图、审阅稿、脚本与发布检查：`assets/marketing`。旧双语文案清单属于历史讨论，不代表英文已发布改稿。
- 中文分享图：`swift assets/marketing/scripts/render-website-zh.swift`，仅更新中文卡片。

Agent 安装必须带上 Skill 的 `scripts/`，验证当前执行 Shell 和去掉临时 PATH 后的新用户终端。
仅 `uv tool install` 成功不能作为安装完成的依据。

英文保留原来的前端绘制演示。本轮不重新生成或上传 App Store 宣传图。

## 本地预览

要求 Node.js 和 npm。CI 当前使用 Node.js 22 和锁定的 `package-lock.json`。

```bash
cd website
npm ci
npm run dev
```

`npm run dev` 启动 Rspress 开发服务器并监听文件变化。最终提交前使用与 CI 相同的生产构建：

```bash
cd website
npm ci
npm run build
```

产物写入 `website/doc_build`。需要在本地检查生产产物时：

```bash
cd website
npm run preview
```

## 新增或修改页面

1. 在 `website/docs/zh` 和 `website/docs/en` 下创建相同相对路径的 `.md` 或 `.mdx` 文件。
2. 默认双语维护；用户明确限定语言时遵循该范围，保持另一语言的文案与显示不变，并记录差异。
3. 如果页面属于 Guide，更新两侧 `guide/_meta.json`；如果需要顶栏入口，更新两侧 `_nav.json`。
4. 页面之间使用站内绝对路由，例如 `/guide/run`，不要引用构建产物目录。
5. 图片放在 `website/docs/public`，页面以根路径引用，例如 `/brand/runbuoy-icon-light.png`。
6. 运行 `npm run build`，检查语言对等、MDX、内部路由和静态资源错误。

普通 Markdown 适合说明页；需要导入 Rspress 组件或编写 JSX 时使用 MDX。现有快速开始用
`Tabs`/`Tab` 展示不同平台和安装工具，首页用 HTML/JSX 组织三步流程。

维护 `/guide/install` 时以[安装、更新、项目接入与配对](../user-guide/installation.md)为事实来源。一键安装脚本尚未
发布时，官网使用 Agent 提示词与可折叠手动安装命令；不得提前公开不可用的 `install.sh` URL。

## 发布

`.github/workflows/pages.yml` 在以下条件发布网站：

- `main` 分支中 `website/**` 或 Pages workflow 有变更；
- 手工触发 `workflow_dispatch`。

发布过程使用 Node.js 22、`npm ci`、`npm run build`，把 `website/doc_build` 上传为 GitHub Pages
artifact，再由 `actions/deploy-pages` 发布。配置的 `siteOrigin` 是 `https://www.runbuoy.cloud`，
Open Graph 图片为 `https://www.runbuoy.cloud/og.png`。

## 写官网文案时的代码事实边界

官网文案应先复用[产品功能总览](../features/README.md)，再按目标读者压缩。尤其不要超前承诺：

- iOS 18 以下支持；当前 Xcode 部署目标是 iOS 18.0；
- 中国大陆独立托管区域；当前 App 只开放 Global；
- 手机取消、重试、批准、输入或远程终端；产品是单向只读投影；
- 自动推测百分比或 ETA；RunBuoy 只展示真实上报的数据；
- 默认上传命令、参数、环境、源码或完整日志；
- 未核实的 App Store 状态；2026-10-05 官方查询确认已上架 1.0.4，最低 iOS 18，中文下载页已更新；
- App 内可填写任意自托管地址；当前需要自有 iOS 构建配置；
- Rich Message 支持 Markdown、HTML 或可点击 `safe_link`；当前 App 按纯文本显示字段；
- Live Activity 满两条后会智能抢占；当前实现是抑制新的 start。

当代码行为和旧网页文字冲突时，以可执行代码、协议约束和测试为准，按本次授权的语言范围更新。

## 官网功能验收清单

- 中文和英文存在相同页面路径，导航均可达。
- 首页核心承诺没有越过单向只读边界。
- 示例命令与 [CLI 全命令与用法](../features/cli.md) 一致。
- 进度示例与 [进度和 SDK](../features/progress-sdk.md) 一致。
- 隐私、安全和自托管描述与 [Server 文档](../features/server.md) 一致。
- 下载状态、最低系统版本、托管区域等阶段性事实仍符合当前代码和发布状态。
- `npm run build` 成功，静态资源和站内路由无构建错误。
