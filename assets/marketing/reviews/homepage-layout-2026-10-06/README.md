# RunBuoy 中文首页：布局与体验审阅

审阅日期：2026-10-06  
代码基线：`codex/homepage-figma` / `db2002e`  
审阅对象：[本地首页](http://127.0.0.1:4322/)。本轮新增审阅证据和设计参考，未修改网站源代码、部署或同步 Figma。

## 结论

当前版本已解决桌面首屏装不下的问题。下一轮应调整产品画面的主次、功能区的展示方式和安装后的衔接，保留大卡片、浮标、水面、蓝白配色及已确认文案。

优先处理：Agent 安装后的配对入口；首屏手机被遮挡；ChatGPT 特色界面的辨识度。减少重复容器和处理中文断句，比继续缩小字号更有价值。

## 本次经过的流程与健康度

1. **进入首页、理解产品：需改善。** 下载及连接入口可见，1280×720 下完整大卡片可见；手机主体被卡片覆盖，视觉关系不够清楚。证据：[桌面首屏](current-1440-hero.jpg)、[笔记本首屏](current-1280-hero.jpg)。
2. **浏览任务、消息与 Agent 功能：需改善。** 内容清楚，但多层卡片重复，ChatGPT 区域缺少对话和看板上下文。证据：[任务区](current-features-desktop.jpg)、[Agent 区](current-agent-desktop.jpg)。
3. **点击连接、复制安装提示词、继续配对：存在衔接缺口。** 锚点、复制成功反馈、键盘展开与收起正常；配对下一步仅存在于手动安装折叠区。证据：[安装入口](current-install-entry.jpg)、[复制成功](current-copy-success.jpg)、[展开提示词](current-install-prompt.jpg)、[键盘展开](current-keyboard-disclosure.jpg)。
4. **手机端通读：可用，需排版精修。** 无横向溢出，大卡片可读；文案发生不理想断词，手机画面被遮住，功能区重复容器占用较多高度。证据：[390 首屏](current-390-hero.jpg)、[390 整页](current-390-page.jpg)、[320 首屏](current-320-hero.jpg)、[手机任务区](current-features-mobile.jpg)、[手机 Agent 区](current-agent-mobile.jpg)。

## 发现与建议

### F1 · P2 · Agent 安装路径缺少可见的配对下一步

- **触发**：用户点击“连接我的电脑”，复制提示词，交给 Agent 完成安装。
- **证据**：界面第三步是“扫码配对”，但安装提示词末尾明确要求“不要启动配对”。配对命令和指南链接只在默认关闭的“手动安装与配对”内。
- **影响**：Agent 安装完成后，用户还需要自行发现手动区域，才能知道如何让 iPhone 连接电脑。“Agent 为主”的流程在这一处不连贯。
- **建议**：保留安装提示词和 PATH 验证；在主流程补充“安装完成？让 Agent 显示配对码”或明确的配对指南入口。配对由用户主动进入，安装动作本身仍只负责安装和验证。
- **源代码**：`website/theme/components/ChineseHome/HomeContent/index.tsx:45`、`:59`；`website/theme/components/ChineseHome/installPrompts.ts:21`。
- **边界**：本轮没有实际安装 CLI 或启动配对；这是根据页面与提示词合同确认的流程缺口。

### F2 · P2 · 首屏的大卡片与手机争夺同一块空间

- **观察**：桌面卡片覆盖手机中部主要内容；390px 下卡片从 y≈341 至 y≈581，手机从 y≈357 至 y≈699，其上部和主要任务内容几乎完全被挡住。
- **影响**：用户看到了大卡片，但手机只剩一小段密集界面，难以建立“这张卡来自手机 App”的关系。浮标、手机和卡片也没有形成稳定的视觉重心。
- **建议**：保持卡片尺寸和可读性，将手机移至卡片侧后方，让大部分屏幕露出；用统一水面和接触阴影连接三者。手机端给大卡片独立的位置，手机只承担设备识别作用，不保留一截不可读的密集列表。
- **源代码**：`website/theme/components/ChineseHome/HomeHero/index.css:11`、`:14`、`:33`、`:36`。
- **证据**：[1440 首屏](current-1440-hero.jpg)、[390 首屏](current-390-hero.jpg)。

### F3 · P2 · ChatGPT 的独特使用方式没有被画面表达出来

- **观察**：当前展示的是孤立的“模型训练 / 68%”卡片，与前两节的任务卡高度相似；对话、任务选择和看板导航均未出现在主展示中。
- **影响**：“问一句，查进展；点一下，看全貌”主要依赖文字，用户无法一眼理解与 iPhone 查看任务的差别。
- **建议**：展示简短的对话上下文和嵌入式任务看板的关键区域，保留选中任务与导航。优先复用项目真实界面；手机端裁取关键区域或重排，避免把完整桌面截图压小。Plugin 继续作为 Agent 集成的子功能，并保留私人预览、只读、iPhone 确认说明。
- **源代码**：`website/theme/components/ChineseHome/AgentIntegration.tsx:16`。
- **证据**：[当前 Agent 区](current-agent-desktop.jpg)、[手机 Agent 区](current-agent-mobile.jpg)。

### F4 · P3 · 功能区容器层次多，内容的表达方式重复

- **观察**：任务概览外框包住任务卡；消息容器再包消息块；锁屏区域再包黑色卡片。它们和首屏、Agent 区都以进度条卡片为主。
- **影响**：页面虽然可读，但不同卖点的视觉差异弱。390px 下“任务与消息”整节约 1210px 高，较多高度用于重复标题、容器内外留白，而非新增信息。
- **建议**：任务用紧凑列表；消息与实时活动用可识别的手机锁屏上下文；集成用对话与看板。每个展示只保留必要的一层外边界，依靠栅格、背景和间距分组。
- **源代码**：`website/theme/components/ChineseHome/HomeFeature/index.tsx:15`；`website/theme/components/ChineseHome/HomeFeature/index.css:2`、`:4`、`:9`、`:14`。
- **证据**：[任务区](current-features-desktop.jpg)、[手机任务区](current-features-mobile.jpg)。

### F5 · P3 · 手机副文案的中文断句需要单独处理

- **观察**：390px 下“结果”拆成行尾“结”和下行“果”；320px 下末尾单独留下“身收。”。
- **原因**：移动端隐藏原有换行，只让整段自由换行；`text-wrap: pretty` 没有保证中文词组完整。
- **建议**：将两句副文案作为独立语义行，必要时按短语分组；不缩小字号，不对整段使用 `nowrap`。用 320、390、768 宽度逐一确认断句。
- **源代码**：`website/theme/components/ChineseHome/HomeHero/index.css:25`、`:26`。
- **证据**：[390 首屏](current-390-hero.jpg)、[320 首屏](current-320-hero.jpg)。

### F6 · P3 · 首屏装饰资源仍可优化

- **源代码事实**：水面和透明浮标两个 PNG 合计约 1.7 MiB，手机端也使用同一资源；水面、浮标和产品截图全部声明 `fetchPriority="high"`。
- **建议**：保留项目内原始素材，派生适当尺寸的网页资源，并为装饰图选择合理加载优先级。优先保持透明浮标边缘和水面渐变质量。
- **源代码**：`website/theme/components/ChineseHome/HomeHero/index.tsx:24`。
- **边界**：没有进行移动网络性能或 Core Web Vitals 测量，不能据此声称当前页面已经存在特定 LCP 延迟。

## 本轮验证

| 视口 | 横向溢出 | 大卡片底边 | 整页高度 |
|---|---|---:|---:|
| 1280×720 | 无 | 665px | 2945px |
| 1440×900 | 无 | 682px | 3022px |
| 768×1024 | 无 | 693px | 3123px |
| 390×844 | 无 | 581px | 3937px |
| 320×740 | 无 | 686px | 4267px |

- 1280×720 下标题、双入口、大卡片均完整进入首屏。
- 本轮浏览器实际复核：安装锚点、复制成功反馈、完整提示词展开/收起、Tab 焦点与 Enter 展开；焦点轮廓为 3px 蓝色。
- 浏览器记录未发现 warning/error。
- 本轮重新执行 `npm run check` 通过，包含 TypeScript、生产构建、语言对应及静态内容/内部链接检查。日志见 [build-check.log](build-check.log)。
- 未执行线上部署、Figma 同步、App Store 实际下载、真实 Agent 安装/配对、读屏及完整无障碍验收。本轮未重新注入复制失败；该分支仅复核源码，既有测试记录保留在上一轮 implementation 目录中。
- 新截图来自本轮本地页面；之前生成的效果图只作为风格参考，未被当作当前产品证据。

## 新生成的三个参考

编号严格对应本轮向用户显示的顺序。文件保存的是生成器原始输出，未缩放或修图。

1. [居中构图参考](option-1-centered.png)：延续已认可的居中标题，三件主视觉展开，手机更完整；功能区减少外层容器。优先建议从这个方向继续。
2. [左右分栏参考](option-2-split.png)：桌面空间利用更紧凑；是改变居中首屏的备选方向，需要用户选择。
3. [产品横向展开参考](option-3-product-stage.png)：大卡片居中，手机与浮标分置两侧；当前生成图的首屏比例仍偏高，且任务区保留了较多容器，不能原样实现。

**这些图是构图参考，不是新的尺寸规范或产品截图。** 第三张若按 1440px 宽等比展开，首屏约 900px，未满足现有 720px 目标，不建议直接落地。第一张和第二张也仍需按真实字体、控件与已确认响应式约束实现。生成图中的对话、设备 UI、图标与细小文案不能替代项目真实素材和最终中文校对。

下一轮建议先选定构图，再改首屏视觉位置、任务/锁屏/ChatGPT 的展示分工及配对衔接；保留正文尺度和大卡片，不通过缩字追求低高度。

## 文件索引

- `current-*-hero.jpg`：五种视口首屏
- `current-1440-page.jpg`、`current-390-page.jpg`：本轮整页截图
- `current-*-desktop.jpg`、`current-*-mobile.jpg`：区块审阅证据
- `current-install-*.jpg`、`current-copy-success.jpg`、`current-keyboard-disclosure.jpg`：交互证据
- `viewport-evidence.json`：本轮浏览器读取的尺寸
- `option-*.png`：三张新设计参考
- `image-prompts.md`：完整生成提示词
- `generated-assets.json`：生成来源、显示顺序、尺寸及 SHA-256
- `build-check.log`：本轮工程检查日志

