# 本轮验证记录

完成日期：2026-10-03。素材与网站基线为 `main` 的 `9ad8405`，隔离工作分支 `codex/marketing-launch`。

## 最新修订：Agent 安装 PATH 验证

2026-10-05：安装提示词、Skill 和官网说明增加 PATH 修复与当前／新终端验证。见 [修复与验证记录](agent-install-path.md)、[实际 CLI 安装结果](agent-install-path-smoke.json)及 [网站构建检查](agent-install-path-website-check.txt)。当前文案清单同步至 192 条；新增 G07，保留原有提示词审阅编号。本次未发布网站或 Skill。

## 上一轮：Agent 安装优先与文案审阅

- 官网首页、下载页、快速开始的中英文页面均以 Agent 安装为主要路径；提示词默认可见，手动安装默认折叠。生产 HTML 的六页结构检查与浏览器交互记录见 [agent-priority-checks.json](agent-priority-checks.json)。
- 桌面 1280 × 900 和手机 390 × 844 已检查；手动步骤可展开、收起，复制按钮显示成功反馈，手机页面无横向溢出。快速开始页面也验证了 Agent 提示词位于折叠区外、手动内容能展开。
- 最新网站检查通过，日志见 [agent-priority-website-check.txt](agent-priority-website-check.txt)。[190 条文案清单](../copy-review/copy-review.md)保留原文、来源及逐条问题，尚不代表文案定稿。本次未重新生成 App Store 宣传图，也未开启 iOS 模拟器。
- 最新安装区截图：[桌面](agent-priority-home-desktop.jpg)、[手机](agent-priority-home-mobile.jpg)。下方早期网页截图保留为迭代记录，涉及安装层级时以本节为准。

## 第一轮素材制作验证

- iOS Debug 模拟器构建成功；构建日志摘录见 [ios-build.txt](ios-build.txt)。中英文各六张原图来自运行中的 App / ActivityKit。复查中发现的启动画面已重新捕获替换。
- 两套 App Store 总览已逐张目视检查标题、语言、阶段、裁切、任务结果与配对入口。最终均为 1320 × 2868、8-bit RGB、不含透明通道。生成器检查文字框高度，校验脚本检查原图哈希及官网副本一致性，结果见 [export-validation.json](export-validation.json)。
- 官网 `npm run check` 成功，包含 TypeScript、生产构建、双语页面对等和站内链接／静态资源检查。输出见 [website-check.txt](website-check.txt)。
- 浏览器检查中文与英文页面：桌面 1280 × 720、手机 390 × 844，以及 320px 窄屏。记录的页面宽度等于视口宽度，无横向页面溢出。修复了安装卡片的 Grid 最小宽度，完整命令改为自然换行。
- 浅色和深色展示、两种语言的切换、下载链接目标、连接电脑锚点、Agent 提示词展开和复制后的状态反馈已检查。复制反馈成功；浏览器自动化的独立剪贴板读取未返回系统剪贴板内容，因此不将其计为系统粘贴验收。
- 中英文 Open Graph 图片均为 1200 × 630，并核对生产 HTML 各自引用对应语言的文件。
- 截图结束后关闭全部 iOS 模拟器，`simctl list devices booted -j` 返回空设备列表。

## 视觉记录

| 内容 | 文件 |
| --- | --- |
| 中文商店六图 | [app-store-zh-Hans-overview.jpg](app-store-zh-Hans-overview.jpg) |
| 英文商店六图 | [app-store-en-US-overview.jpg](app-store-en-US-overview.jpg) |
| 中文桌面首屏 | [website-zh-desktop-hero.jpg](website-zh-desktop-hero.jpg) |
| 英文桌面首屏 | [website-en-desktop-hero.jpg](website-en-desktop-hero.jpg) |
| 中文手机首屏 | [website-zh-mobile-hero.jpg](website-zh-mobile-hero.jpg) |
| 英文手机首屏 | [website-en-mobile-hero.jpg](website-en-mobile-hero.jpg) |
| 中文手机安装区 | [website-zh-mobile-setup.jpg](website-zh-mobile-setup.jpg) |
| 英文深色手机页 | [website-en-mobile-dark.jpg](website-en-mobile-dark.jpg) |
| 英文手机品牌段 | [website-en-mobile-closing.jpg](website-en-mobile-closing.jpg) |

同目录的 `*-full.jpg` 是完整网页记录。浏览器截图保留 JPEG 原始格式，App Store 成品使用 PNG。

## 验证范围

本轮是宣传素材与官网落地：没有部署生产网站、上传 App Store Connect、归档签名或完成新版 App 的发布验收。没有把本地 ActivityKit 展示等同于远程推送、真机或网络稳定性验证。新版 App 原有的真机、大字体、VoiceOver 与发布门槛仍按项目流程执行。

浏览器控制台仍报告原有 Rspress 导航中主题按钮嵌套于按钮的 HTML 警告，来自基线已有的 `NavHamburger` / `SwitchAppearance` 组合。本轮验证主题及语言操作可用，未扩展为导航组件重构。
