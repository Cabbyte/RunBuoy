# RunBuoy 宣传文案逐条审阅

这份文档是讨论稿，保留当前原文，不代表文案已经定稿。可以直接按编号提出修改，例如「H01 改为……」「A05.S 不要强调 CLI」。除用户已明确的安装层级外，本轮不替换主标题、卖点排序或商店宣传图。

## 已经确定的调整

Agent 是主要安装方式。官网安装区现在先展示 Agent 提示词和复制按钮，手动安装默认折叠；下载页、快速开始同步这个顺序。安装提示词原有的执行范围不变。修改前的原文保存在 `before-agent-priority.json`。

「Agent 是主要安装方式」并不自动等于「RunBuoy 只面向 Agent 任务」。后者是尚未确认的定位，不会替用户作结论。

2026-10-05 补充：用户明确将 ChatGPT Plugin 及交互 UI 归入「Agent 集成」子项。新版卖点分别表达 Skill 的接入／上报与 Plugin 的对话查询／看板／选中任务继续聊，详见 [Agent 集成卖点 v3](agent-integration-v3.md)。下方 190 条仍对应当前成品原文，新增候选单独保留。

## 我对上一版的具体反思

1. 主标题、功能区、场景区、收尾和分享图都在反复说「离开电脑／在手边」，没有层层补充新信息。
2. 过度使用「看进度」，把状态、阶段、结果、消息和需要关注的情况压成一个百分比概念。也没有清楚区分查看与显式消息／提醒。
3. 把训练、构建、备份当成默认优先场景，Agent 只排在第三个功能项。这是我自行作出的市场排序，依据不足。
4. 把 Agent 安装放在折叠区，反而把底层 CLI 命令作为主要使用门槛，这与用户明确的安装路径相反。
5. 「给每一段等待，一个交代」「让等待，轻一点」「清清楚楚」等句子增加了情绪性描述，缺少产品信息。
6. 部分英文没有准确对应中文：`Finished? Failed?` 不是两个互斥状态；`iPhone keeps you in view` 没有表达只读。「始终」「就知道跑到哪」也比实际状态与进度条件更绝对。

## 产品事实与营销判断分开看

代码和产品定义支持的事实是：RunBuoy 将电脑上经接入的任务状态、阶段、进度、消息与结果带到 iPhone；支持 App、锁屏实时活动和灵动岛展示；支持 Skill 的 Agent 可以参与安装、验证与经用户授权的任务接入；执行留在电脑，手机只读。百分比、ETA 和关注状态需要相应上报，不能理解为自动读懂任何 Agent 的全部工作。

事实依据：[产品定义](../../../docs/product/prd.md)、[Skill](../../../skills/runbuoy/SKILL.md)、[SDK 的消息与 attention 接口](../../../cli/src/runbuoy/sdk.py)、[CLI 的后台交接与 notify](../../../cli/src/runbuoy/cli/app.py)。这里读取项目 Skill 只为核对产品行为，不是在执行安装。

需要由用户决定的营销判断包括：第一核心用户是谁；是否以 Agent 工作流为第一场景；第一收益是后台持续执行、随身查看、重要消息提醒，还是这些能力的组合；多机、隐私应该排在什么位置。下文把这些标为待讨论，不伪装成已确认卖点。

## 清单范围

覆盖这轮官网首页的全部自写文字（含按钮、图注、替代文字和反馈）、页脚与顶部导航、下载页与快速开始完整中英文本、安装提示词、六张 App Store 图的标题／副标题／脚注／额外图中文字，以及分享卡片文字。相同导航标签合并记录来源；App Store 的流水编号 01–06 属于排版编号。

App 截图内的原生界面文本来自 main，不是本轮改写的宣传文案；旧审查报告里的候选文案也没有混入当前成品。它们分别保留在原图和 research 中。

「表达意图」描述我写那句话时想表达什么；「审阅备注」指出含混、重复、排序或事实边界问题，不是已经获准的新文案。中文和英文均保留原文，避免改中文后遗留旧英文。


本清单共 **192 条**，中英文使用同一个编号；技术指令按完整语义段保留，不截断、不省略。

## 首页首屏

### H01 · 主标题

**中文原文**

> 离开电脑，
> 也知道任务跑到哪了。

**English**

> Step away.
> Stay in the know.

表达意图：说明离开电脑后仍能获知任务状态。

审阅备注：它只表达结果，没有直接说明服务哪些任务、通过什么接入；也是上一版重复最多的意思。

状态：待用户审阅。

来源：[website/docs/zh/index.mdx:6](../../../website/docs/zh/index.mdx)，[website/docs/en/index.mdx:6](../../../website/docs/en/index.mdx)

### H02 · 首屏说明

**中文原文**

> 训练模型、等待构建、处理数据。让 Mac 与 Linux 上的长任务继续跑，在 iPhone 上看进度、等结果。

**English**

> Training a model. Waiting on a build. Processing data. Let your Mac or Linux machine keep working, and follow its progress from your iPhone.

表达意图：给出使用场景与 Mac/Linux → iPhone 的方向。

审阅备注：场景先列训练、构建、处理数据，Agent 没有出现；这未经用户确认，不应默认为核心场景排序。

状态：待用户审阅。

来源：[website/docs/zh/index.mdx:9](../../../website/docs/zh/index.mdx)，[website/docs/en/index.mdx:9](../../../website/docs/en/index.mdx)

### H03 · 页面描述 / 搜索摘要

**中文原文**

> 离开电脑，也知道任务跑到哪了。RunBuoy 将 Mac 与 Linux 的长任务状态、阶段和结果，带到 iPhone 的锁定屏幕、灵动岛和 App。

**English**

> Step away from your computer. Keep long-running Mac and Linux tasks in sight with RunBuoy on your iPhone Lock Screen, Dynamic Island, and in the app.

表达意图：搜索与分享时说明产品用途。

审阅备注：需要与最终核心定位一致；目前仍围绕进度与长任务。

状态：待用户审阅。

来源：[website/docs/zh/index.mdx:3](../../../website/docs/zh/index.mdx)，[website/docs/en/index.mdx:3](../../../website/docs/en/index.mdx)

### H04 · 首屏按钮 1

**中文原文**

> App Store 下载

**English**

> Get on the App Store

表达意图：获取 iPhone App。

审阅备注：暂未标出具体语言问题，仍待用户审阅。

状态：待用户审阅。

来源：[website/docs/zh/index.mdx:12](../../../website/docs/zh/index.mdx)，[website/docs/en/index.mdx:12](../../../website/docs/en/index.mdx)

### H05 · 首屏按钮 2

**中文原文**

> 连接我的电脑

**English**

> Connect my computer

表达意图：进入已改为 Agent 优先的安装区。

审阅备注：暂未标出具体语言问题，仍待用户审阅。

状态：待用户审阅。

来源：[website/docs/zh/index.mdx:15](../../../website/docs/zh/index.mdx)，[website/docs/en/index.mdx:15](../../../website/docs/en/index.mdx)

## 首页首屏辅助文字

### HX01 · 系统要求

**中文原文**

> 免费 · iOS 18 及以上 · 需在 Mac / Linux 安装 CLI

**English**

> Free · iOS 18+ · CLI setup on Mac or Linux required

表达意图：说明价格、设备要求和电脑端安装要求。

审阅备注：CLI 是实现依赖；安装方式应由 Agent 优先的入口解释。

状态：待用户审阅。

来源：[website/theme/components/HomeHero/index.tsx:36](../../../website/theme/components/HomeHero/index.tsx)

### HX02 · 任务列表替代文字

**中文原文**

> RunBuoy 运行中：Mac Studio 上的训练、MacBook 上的构建、Linux 上的备份

**English**

> RunBuoy active runs: training on Mac Studio, a MacBook build and a Linux backup

表达意图：为读屏用户描述示例图。

审阅备注：示例数据不是用户真实任务；“真实界面”与“真实业务数据”要区分。

状态：待用户审阅。

来源：[website/theme/components/HomeHero/index.tsx:43](../../../website/theme/components/HomeHero/index.tsx)

### HX03 · 锁屏图注

**中文原文**

> 锁屏一瞥，进度在这里

**English**

> A glance at your Lock Screen

表达意图：指出锁屏中的状态展示。

审阅备注：“进度在这里”仍与主标题重复。

状态：待用户审阅。

来源：[website/theme/components/HomeHero/index.tsx:46](../../../website/theme/components/HomeHero/index.tsx)

### HX04 · 实时活动替代文字

**中文原文**

> 真实实时活动：任务进度 72%，显示当前阶段与运行时间

**English**

> Real Live Activity showing 72% progress, the current phase and elapsed time

表达意图：为读屏用户描述实时活动截图。

审阅备注：72% 是构造的演示数据。

状态：待用户审阅。

来源：[website/theme/components/HomeHero/index.tsx:47](../../../website/theme/components/HomeHero/index.tsx)

## 首页功能区

### F01 · 区块眉题

**中文原文**

> 从开始，到结束

**English**

> From the first step to the final result

表达意图：引出任务从开始到结束的过程。

审阅备注：抽象过渡句，没有新增产品信息。

状态：待用户审阅。

来源：[website/theme/components/HomeFeature/index.tsx:75](../../../website/theme/components/HomeFeature/index.tsx)

### F02 · 区块标题

**中文原文**

> 不用守着终端，也能心里有数。

**English**

> Less checking. More knowing.

表达意图：强调减少反复查看。

审阅备注：与 H01 重复，没有说明哪些状态变化值得关注。

状态：待用户审阅。

来源：[website/theme/components/HomeFeature/index.tsx:78](../../../website/theme/components/HomeFeature/index.tsx)

### F03 · 区块说明

**中文原文**

> 正在跑、跑到哪、结果如何。需要的状态，就在手边。

**English**

> Running, making progress, or finished. The state that matters stays within reach.

表达意图：列出运行状态、进度和结果。

审阅备注：没有提到任务消息与显式关注提醒。

状态：待用户审阅。

来源：[website/theme/components/HomeFeature/index.tsx:82](../../../website/theme/components/HomeFeature/index.tsx)

### F04 · 功能 1 标题

**中文原文**

> 进度，就在锁屏上

**English**

> Progress on your Lock Screen

表达意图：锁屏与灵动岛展示。

审阅备注：“不用反复看终端”较泛，应说明用户能获知的具体信息。

状态：待用户审阅。

来源：[website/docs/zh/index.mdx:18](../../../website/docs/zh/index.mdx)，[website/docs/en/index.mdx:18](../../../website/docs/en/index.mdx)

### F05 · 功能 1 说明

**中文原文**

> 用实时活动和灵动岛查看阶段、进度与运行时间，不必反复切回终端。

**English**

> See the current phase, progress, and elapsed time in Live Activities and Dynamic Island. Fewer trips back to the terminal.

表达意图：锁屏与灵动岛展示。

审阅备注：“不用反复看终端”较泛，应说明用户能获知的具体信息。

状态：待用户审阅。

来源：[website/docs/zh/index.mdx:19](../../../website/docs/zh/index.mdx)，[website/docs/en/index.mdx:19](../../../website/docs/en/index.mdx)

### F06 · 功能 2 标题

**中文原文**

> 结束了，知道结果

**English**

> Know how it finished

表达意图：显示任务结果与历史。

审阅备注：只写查看结果，主动提醒与显式关注消息没有讲清。

状态：待用户审阅。

来源：[website/docs/zh/index.mdx:22](../../../website/docs/zh/index.mdx)，[website/docs/en/index.mdx:22](../../../website/docs/en/index.mdx)

### F07 · 功能 2 说明

**中文原文**

> 任务成功还是失败，一眼分清。回到 App，还能查看历史与阶段记录。

**English**

> Tell success from failure at a glance. Open the app to revisit past runs and the phases along the way.

表达意图：显示任务结果与历史。

审阅备注：只写查看结果，主动提醒与显式关注消息没有讲清。

状态：待用户审阅。

来源：[website/docs/zh/index.mdx:23](../../../website/docs/zh/index.mdx)，[website/docs/en/index.mdx:23](../../../website/docs/en/index.mdx)

### F08 · 功能 3 标题

**中文原文**

> Agent 工作，也看得见

**English**

> Keep your agent in view

表达意图：让支持 Skill 的 Agent 接入 RunBuoy。

审阅备注：Agent 被放在第三个功能项；默认安装方式已明确，但是否也是第一核心场景还需用户定义。

状态：待用户审阅。

来源：[website/docs/zh/index.mdx:26](../../../website/docs/zh/index.mdx)，[website/docs/en/index.mdx:26](../../../website/docs/en/index.mdx)

### F09 · 功能 3 说明

**中文原文**

> 为 Codex 等支持 Skill 的 Agent 接入 RunBuoy，让它按阶段报告长任务的状态。

**English**

> Give Codex or another Skill-enabled agent the RunBuoy Skill so it can report the phases of your long-running work.

表达意图：让支持 Skill 的 Agent 接入 RunBuoy。

审阅备注：Agent 被放在第三个功能项；默认安装方式已明确，但是否也是第一核心场景还需用户定义。

状态：待用户审阅。

来源：[website/docs/zh/index.mdx:27](../../../website/docs/zh/index.mdx)，[website/docs/en/index.mdx:27](../../../website/docs/en/index.mdx)

## 使用场景

### S01 · 场景区眉题

**中文原文**

> 给每一段等待，一个交代

**English**

> For the work worth waiting for

表达意图：引入等待场景。

审阅备注：“给等待一个交代”含义抽象，不能帮助理解产品。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:19](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:55](../../../website/theme/components/HomeContent/index.tsx)

### S02 · 场景区标题

**中文原文**

> 电脑继续忙，
> 你可以先离开。

**English**

> Your computer is busy.
> You don’t have to be.

表达意图：说明电脑任务可继续执行。

审阅备注：“你可以先离开”仍重复 H01；未呈现 Agent/任务与 RunBuoy 的关系。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:20](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:56](../../../website/theme/components/HomeContent/index.tsx)

### S03 · 场景区说明

**中文原文**

> 多台电脑的任务集中在一处。需要知道的不只是“还在跑”，还有现在跑到哪一步。

**English**

> Bring tasks from your computers into one view. See more than “still running”: know which phase they have reached.

表达意图：将多机任务放到一个视图。

审阅备注：“不只是还在跑”容易暗示所有任务都有细粒度进度；须有显式上报。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:21](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:57](../../../website/theme/components/HomeContent/index.tsx)

### S04 · 场景 1 标题

**中文原文**

> 模型训练与实验

**English**

> Model training & experiments

表达意图：说明一个具体任务场景或接入方式。

审阅备注：训练、构建、备份的优先顺序尚未作为产品定位得到确认。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:23](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:59](../../../website/theme/components/HomeContent/index.tsx)

### S05 · 场景 1 说明

**中文原文**

> 看轮次、样本数与阶段，出门后也能掌握训练状态。

**English**

> Follow epochs, sample counts, and phases while you step away.

表达意图：说明一个具体任务场景或接入方式。

审阅备注：训练、构建、备份的优先顺序尚未作为产品定位得到确认。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:23](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:59](../../../website/theme/components/HomeContent/index.tsx)

### S06 · 场景 2 标题

**中文原文**

> 编译、测试与构建

**English**

> Compiles, tests & builds

表达意图：说明一个具体任务场景或接入方式。

审阅备注：训练、构建、备份的优先顺序尚未作为产品定位得到确认。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:24](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:60](../../../website/theme/components/HomeContent/index.tsx)

### S07 · 场景 2 说明

**中文原文**

> 知道构建还在执行，或是已经成功、失败。

**English**

> Know whether a build is still running, succeeded, or failed.

表达意图：说明一个具体任务场景或接入方式。

审阅备注：训练、构建、备份的优先顺序尚未作为产品定位得到确认。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:24](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:60](../../../website/theme/components/HomeContent/index.tsx)

### S08 · 场景 3 标题

**中文原文**

> 数据处理与备份

**English**

> Data processing & backups

表达意图：说明一个具体任务场景或接入方式。

审阅备注：训练、构建、备份的优先顺序尚未作为产品定位得到确认。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:25](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:61](../../../website/theme/components/HomeContent/index.tsx)

### S09 · 场景 3 说明

**中文原文**

> 把脚本报告的进度带到手边，减少来回查看。

**English**

> Keep the progress your scripts report within reach. Check back less.

表达意图：说明一个具体任务场景或接入方式。

审阅备注：训练、构建、备份的优先顺序尚未作为产品定位得到确认。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:25](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:61](../../../website/theme/components/HomeContent/index.tsx)

### S10 · 进度能力条件

**中文原文**

> 百分比与预计完成时间来自任务显式报告。普通命令也能跟踪状态和结果，不会自动推算百分比。

**English**

> Percentages and time estimates come from explicit task reports. Ordinary commands still report status and results; RunBuoy does not invent a percentage.

表达意图：限定百分比与 ETA 的来源。

审阅备注：是功能解释，放在主要卖点下面只能补充，不能修复主标题的绝对承诺。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:27](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:63](../../../website/theme/components/HomeContent/index.tsx)

### S11 · 进度接入链接

**中文原文**

> 如何接入真实进度

**English**

> Connect real progress

表达意图：说明一个具体任务场景或接入方式。

审阅备注：训练、构建、备份的优先顺序尚未作为产品定位得到确认。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:28](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:64](../../../website/theme/components/HomeContent/index.tsx)

## 安装区

### I01 · 安装区眉题

**中文原文**

> 从电脑到手边

**English**

> From your computer to your pocket

表达意图：引导安装、配对或查看操作说明。

审阅备注：Agent 默认展开；手动安装相关内容默认折叠。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:29](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:65](../../../website/theme/components/HomeContent/index.tsx)

### I02 · 安装区标题

**中文原文**

> 使用 Agent 安装 RunBuoy。

**English**

> Install RunBuoy with your agent.

表达意图：把 Agent 安装设为主路径。

审阅备注：本轮已按用户明确要求修改。

状态：已按 Agent 优先调整；措辞仍待审阅。

本轮调整前：下载，然后
连接你的电脑。 / Get the app. Connect your computer.

来源：[website/theme/components/HomeContent/index.tsx:30](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:66](../../../website/theme/components/HomeContent/index.tsx)

### I03 · 安装区说明

**中文原文**

> 复制安装提示词，交给 Codex 或其他支持 Skill 的 Agent。

**English**

> Copy the installation prompt into Codex or another Skill-enabled agent.

表达意图：说明把提示词交给什么工具。

审阅备注：不承诺所有 Agent 都支持 Skill。

状态：已按 Agent 优先调整；措辞仍待审阅。

本轮调整前：iPhone 负责展示。任务仍从 Mac 或 Linux 启动。 / Your iPhone shows the status. Tasks still start on your Mac or Linux machine.

来源：[website/theme/components/HomeContent/index.tsx:31](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:67](../../../website/theme/components/HomeContent/index.tsx)

### I04 · 手动步骤 1 标题

**中文原文**

> 在 iPhone 下载

**English**

> Get RunBuoy on iPhone

表达意图：引导安装、配对或查看操作说明。

审阅备注：Agent 默认展开；手动安装相关内容默认折叠。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:33](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:69](../../../website/theme/components/HomeContent/index.tsx)

### I05 · 手动步骤 1 说明

**中文原文**

> 从 App Store 安装 RunBuoy，打开 App 完成引导。

**English**

> Download from the App Store and follow the in-app introduction.

表达意图：引导安装、配对或查看操作说明。

审阅备注：Agent 默认展开；手动安装相关内容默认折叠。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:33](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:69](../../../website/theme/components/HomeContent/index.tsx)

### I06 · 手动步骤 2 标题

**中文原文**

> 在电脑安装

**English**

> Install on your computer

表达意图：引导安装、配对或查看操作说明。

审阅备注：Agent 默认展开；手动安装相关内容默认折叠。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:34](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:70](../../../website/theme/components/HomeContent/index.tsx)

### I07 · 手动步骤 2 说明

**中文原文**

> 先准备 uv 与 tmux。以下命令适用于 Bash / Zsh；完成后在新终端验证 runbuoy --version。

**English**

> Set up uv and tmux. Use these commands in Bash / Zsh, then verify runbuoy --version in a new terminal.

表达意图：引导安装、配对或查看操作说明。

审阅备注：Agent 默认展开；手动安装相关内容默认折叠。

状态：已按 Agent 优先调整；措辞仍待审阅。

本轮调整前：先准备 uv 与 tmux，再安装 CLI。支持 macOS 和 Linux。 / Set up uv and tmux, then install the CLI. Works on macOS and Linux.

来源：[website/theme/components/HomeContent/index.tsx:34](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:70](../../../website/theme/components/HomeContent/index.tsx)

### I08 · 手动步骤 3 标题

**中文原文**

> 配对你的电脑

**English**

> Pair your computer

表达意图：引导安装、配对或查看操作说明。

审阅备注：Agent 默认展开；手动安装相关内容默认折叠。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:35](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:71](../../../website/theme/components/HomeContent/index.tsx)

### I09 · 手动步骤 3 说明

**中文原文**

> 在终端运行配对命令，用 App 扫描二维码并确认电脑身份。

**English**

> Run the pairing command, scan the QR code in the app, and confirm the computer.

表达意图：引导安装、配对或查看操作说明。

审阅备注：Agent 默认展开；手动安装相关内容默认折叠。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:35](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:71](../../../website/theme/components/HomeContent/index.tsx)

### I10 · 手动步骤 4 标题

**中文原文**

> 看到第一条动态

**English**

> See your first update

表达意图：引导安装、配对或查看操作说明。

审阅备注：Agent 默认展开；手动安装相关内容默认折叠。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:36](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:72](../../../website/theme/components/HomeContent/index.tsx)

### I11 · 手动步骤 4 说明

**中文原文**

> 配对后运行演示，确认 iPhone 收到状态，再接入自己的长任务。

**English**

> Run the demo after pairing. Once it reaches your iPhone, connect your own long-running work.

表达意图：引导安装、配对或查看操作说明。

审阅备注：Agent 默认展开；手动安装相关内容默认折叠。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:36](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:72](../../../website/theme/components/HomeContent/index.tsx)

### I12 · 下载入口

**中文原文**

> App Store 下载

**English**

> Get on the App Store

表达意图：引导安装、配对或查看操作说明。

审阅备注：Agent 默认展开；手动安装相关内容默认折叠。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:38](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:74](../../../website/theme/components/HomeContent/index.tsx)

### I13 · 依赖说明链接

**中文原文**

> 准备依赖与完整安装说明

**English**

> Dependencies and installation guide

表达意图：引导安装、配对或查看操作说明。

审阅备注：Agent 默认展开；手动安装相关内容默认折叠。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:38](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:74](../../../website/theme/components/HomeContent/index.tsx)

### I14 · 配对指南链接

**中文原文**

> 完整配对与使用指南

**English**

> Full pairing and usage guide

表达意图：引导安装、配对或查看操作说明。

审阅备注：Agent 默认展开；手动安装相关内容默认折叠。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:39](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:75](../../../website/theme/components/HomeContent/index.tsx)

### I15 · Agent 安装卡片标题

**中文原文**

> 安装 Skill 与 CLI

**English**

> Install the Skill and CLI

表达意图：引导安装、配对或查看操作说明。

审阅备注：Agent 默认展开；手动安装相关内容默认折叠。

状态：已按 Agent 优先调整；措辞仍待审阅。

本轮调整前：正在使用 Codex 或其他 Agent？ / Already working with Codex or another agent?

来源：[website/theme/components/HomeContent/index.tsx:40](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:76](../../../website/theme/components/HomeContent/index.tsx)

### I16 · Agent 安装卡片说明

**中文原文**

> Agent 会安装并验证 RunBuoy Skill 与 CLI。完成后，继续配对手机与运行任务。

**English**

> Your agent installs and verifies the RunBuoy Skill and CLI. Then pair your phone and start a task.

表达意图：说明 Agent 会安装与验证哪些组件。

审阅备注：安装与真正接入任务是两个步骤；不能写成粘贴后自动跟踪一切。

状态：已按 Agent 优先调整；措辞仍待审阅。

本轮调整前：也可以让支持 Skill 的 Agent 帮你安装和验证。完成后，由你继续配对与运行任务。 / A Skill-enabled agent can help install and verify RunBuoy. You then pair your phone and start a task.

来源：[website/theme/components/HomeContent/index.tsx:41](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:77](../../../website/theme/components/HomeContent/index.tsx)

### I17 · 手动安装折叠入口

**中文原文**

> 手动安装与配对步骤

**English**

> Manual installation and pairing

表达意图：将手动安装作为折叠后的备选路径。

审阅备注：本轮已按用户明确要求修改。

状态：已按 Agent 优先调整；措辞仍待审阅。

本轮调整前：无该标签 / No previous label

来源：[website/theme/components/HomeContent/index.tsx:42](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:78](../../../website/theme/components/HomeContent/index.tsx)

### I18 · 安装提示词复制按钮

**中文原文**

> 复制安装提示词

**English**

> Copy installation prompt

表达意图：引导安装、配对或查看操作说明。

审阅备注：Agent 默认展开；手动安装相关内容默认折叠。

状态：已按 Agent 优先调整；措辞仍待审阅。

本轮调整前：复制完整提示词 / Copy full prompt

来源：[website/theme/components/HomeContent/index.tsx:42](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:78](../../../website/theme/components/HomeContent/index.tsx)

### I19 · 安装提示词执行范围

**中文原文**

> 这条提示词只安装和验证，不会自动配对、启动任务或上传日志。

**English**

> This prompt only installs and verifies. It does not pair devices, start tasks, or upload logs.

表达意图：说明安装提示词的实际执行范围。

审阅备注：配对、任务启动仍需用户主动发起；不是全自动安装到推送闭环。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:43](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:79](../../../website/theme/components/HomeContent/index.tsx)

### I99 · Agent 提示词旁的指南链接

**中文原文**

> 使用指南

**English**

> Read the guide

表达意图：打开完整安装指南。

审阅备注：暂未标出具体语言问题，仍待用户审阅。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:145](../../../website/theme/components/HomeContent/index.tsx)

## 数据与执行边界

### P01 · 数据边界眉题

**中文原文**

> 数据边界，清清楚楚

**English**

> Clear data boundaries

表达意图：引出数据范围。

审阅备注：“清清楚楚”是评价词，信息量低。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:44](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:80](../../../website/theme/components/HomeContent/index.tsx)

### P02 · 数据边界标题

**中文原文**

> 状态随身，工作留在电脑。

**English**

> Take the status. Keep the work local.

表达意图：说明状态外发与本地执行分离。

审阅备注：“工作留在电脑”过宽；不应让人误以为业务依赖的云端 AI 也变成本地执行。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:44](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:80](../../../website/theme/components/HomeContent/index.tsx)

### P03 · 数据边界说明

**中文原文**

> 命令、源码、环境变量与完整日志默认留在本机。你可以显式启用经过清理的日志摘要。

**English**

> Commands, source code, environment variables, and full logs stay on your computer by default. Sanitized log excerpts are an explicit opt-in.

表达意图：说明默认不上传的数据及日志片段例外。

审阅备注：功能边界应准确；“经过清理”不等于绝对无敏感信息。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:45](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:81](../../../website/theme/components/HomeContent/index.tsx)

### P04 · 数据流节点 1 标题

**中文原文**

> Mac / Linux

**English**

> Mac / Linux

表达意图：说明数据流与手机权限。

审阅备注：暂未标出具体语言问题，仍待用户审阅。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:46](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:82](../../../website/theme/components/HomeContent/index.tsx)

### P05 · 数据流节点 1 说明

**中文原文**

> 执行任务 · 保留完整日志

**English**

> Runs tasks · Keeps full logs

表达意图：说明数据流与手机权限。

审阅备注：暂未标出具体语言问题，仍待用户审阅。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:46](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:82](../../../website/theme/components/HomeContent/index.tsx)

### P06 · 数据流节点 2 标题

**中文原文**

> RunBuoy Server

**English**

> RunBuoy Server

表达意图：说明数据流与手机权限。

审阅备注：暂未标出具体语言问题，仍待用户审阅。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:46](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:82](../../../website/theme/components/HomeContent/index.tsx)

### P07 · 数据流节点 2 说明

**中文原文**

> 转发阶段、进度与结果

**English**

> Relays phases, progress & results

表达意图：说明数据流与手机权限。

审阅备注：暂未标出具体语言问题，仍待用户审阅。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:46](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:82](../../../website/theme/components/HomeContent/index.tsx)

### P08 · 数据流节点 3 标题

**中文原文**

> iPhone

**English**

> iPhone

表达意图：说明数据流与手机权限。

审阅备注：暂未标出具体语言问题，仍待用户审阅。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:46](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:82](../../../website/theme/components/HomeContent/index.tsx)

### P09 · 数据流节点 3 说明

**中文原文**

> 查看状态 · 接收提醒

**English**

> Shows status · Receives alerts

表达意图：说明数据流与手机权限。

审阅备注：暂未标出具体语言问题，仍待用户审阅。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:46](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:82](../../../website/theme/components/HomeContent/index.tsx)

### P10 · 手机权限说明

**中文原文**

> 手机端只读：不启动、停止或重试电脑任务。

**English**

> The phone is read-only. It cannot start, stop, or retry tasks on your computer.

表达意图：说明手机的查看权限边界。

审阅备注：这是重要边界，但是否作为前列宣传卖点需要单独决定。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:47](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:83](../../../website/theme/components/HomeContent/index.tsx)

### P11 · 隐私入口

**中文原文**

> 了解隐私与数据保留规则

**English**

> Privacy and data retention

表达意图：说明数据流与手机权限。

审阅备注：暂未标出具体语言问题，仍待用户审阅。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:48](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:84](../../../website/theme/components/HomeContent/index.tsx)

## 收尾号召

### C01 · 收尾标题

**中文原文**

> 让等待，轻一点。

**English**

> A little less waiting around.

表达意图：收尾情绪性号召。

审阅备注：“让等待轻一点”过泛，无法区分 RunBuoy。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:49](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:85](../../../website/theme/components/HomeContent/index.tsx)

### C02 · 收尾说明

**中文原文**

> 下一次开始长任务，就把进度带在身边。

**English**

> Bring the next long-running task along with you.

表达意图：引导下一次任务接入。

审阅备注：仍重复“带在身边”，没有给出 Agent 的具体使用动作。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:50](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:86](../../../website/theme/components/HomeContent/index.tsx)

### C03 · 收尾第二入口

**中文原文**

> 连接我的电脑

**English**

> Connect my computer

表达意图：辅助导航、无障碍或操作反馈。

审阅备注：不承担核心卖点。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:51](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:87](../../../website/theme/components/HomeContent/index.tsx)

## 辅助与反馈

### U01 · 复制成功反馈

**中文原文**

> 已复制

**English**

> Copied

表达意图：辅助导航、无障碍或操作反馈。

审阅备注：不承担核心卖点。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:51](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:87](../../../website/theme/components/HomeContent/index.tsx)

### U02 · 复制按钮辅助标签

**中文原文**

> 复制

**English**

> Copy

表达意图：辅助导航、无障碍或操作反馈。

审阅备注：不承担核心卖点。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:51](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:87](../../../website/theme/components/HomeContent/index.tsx)

### U03 · 复制失败反馈

**中文原文**

> 复制失败，请选择下方文字手动复制。

**English**

> Copy failed. Select the text below to copy it manually.

表达意图：辅助导航、无障碍或操作反馈。

审阅备注：不承担核心卖点。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:51](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:87](../../../website/theme/components/HomeContent/index.tsx)

### U04 · 详情截图替代文字

**中文原文**

> 任务详情显示 78% 的真实示例进度、训练阶段和安全消息

**English**

> Real task detail showing 78% sample progress, the training phase and a safe message

表达意图：为读屏用户描述任务详情。

审阅备注：“真实示例进度”容易混淆：实际界面、构造的任务数据。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/index.tsx:52](../../../website/theme/components/HomeContent/index.tsx)，[website/theme/components/HomeContent/index.tsx:88](../../../website/theme/components/HomeContent/index.tsx)

## 页脚与导航

### N01 · 页脚产品概括

**中文原文**

> 让 Mac 与 Linux 长任务的进度，始终在手边。

**English**

> Keep long-running work on Mac and Linux within reach.

表达意图：概括产品用途。

审阅备注：“始终”比当前确认/过期状态的实际语义更绝对。

状态：待用户审阅。

来源：[website/theme/components/HomeFooter/index.tsx:10](../../../website/theme/components/HomeFooter/index.tsx)，[website/theme/components/HomeFooter/index.tsx:25](../../../website/theme/components/HomeFooter/index.tsx)

### N02 · 页脚产品分组

**中文原文**

> 产品

**English**

> Product

表达意图：导航标签。

审阅备注：暂未标出具体语言问题，仍待用户审阅。

状态：待用户审阅。

来源：[website/theme/components/HomeFooter/index.tsx:11](../../../website/theme/components/HomeFooter/index.tsx)，[website/theme/components/HomeFooter/index.tsx:26](../../../website/theme/components/HomeFooter/index.tsx)

### N03 · 页脚资源分组

**中文原文**

> 资源

**English**

> Resources

表达意图：导航标签。

审阅备注：暂未标出具体语言问题，仍待用户审阅。

状态：待用户审阅。

来源：[website/theme/components/HomeFooter/index.tsx:12](../../../website/theme/components/HomeFooter/index.tsx)，[website/theme/components/HomeFooter/index.tsx:27](../../../website/theme/components/HomeFooter/index.tsx)

### N04 · 快速开始入口

**中文原文**

> 快速开始

**English**

> Quick Start

表达意图：导航标签。

审阅备注：暂未标出具体语言问题，仍待用户审阅。

状态：待用户审阅。

来源：[website/theme/components/HomeFooter/index.tsx:13](../../../website/theme/components/HomeFooter/index.tsx)，[website/theme/components/HomeFooter/index.tsx:28](../../../website/theme/components/HomeFooter/index.tsx)，[website/docs/zh/_nav.json:7](../../../website/docs/zh/_nav.json)，[website/docs/en/_nav.json:7](../../../website/docs/en/_nav.json)

### N05 · 下载入口

**中文原文**

> 下载 App

**English**

> Get the app

表达意图：导航标签。

审阅备注：暂未标出具体语言问题，仍待用户审阅。

状态：待用户审阅。

来源：[website/theme/components/HomeFooter/index.tsx:14](../../../website/theme/components/HomeFooter/index.tsx)，[website/theme/components/HomeFooter/index.tsx:29](../../../website/theme/components/HomeFooter/index.tsx)，[website/docs/zh/_nav.json:3](../../../website/docs/zh/_nav.json)，[website/docs/en/_nav.json:3](../../../website/docs/en/_nav.json)

### N06 · 文档入口

**中文原文**

> 使用文档

**English**

> Docs

表达意图：导航标签。

审阅备注：暂未标出具体语言问题，仍待用户审阅。

状态：待用户审阅。

来源：[website/theme/components/HomeFooter/index.tsx:15](../../../website/theme/components/HomeFooter/index.tsx)，[website/theme/components/HomeFooter/index.tsx:30](../../../website/theme/components/HomeFooter/index.tsx)，[website/docs/zh/_nav.json:11](../../../website/docs/zh/_nav.json)，[website/docs/en/_nav.json:11](../../../website/docs/en/_nav.json)

### N07 · 隐私入口

**中文原文**

> 隐私

**English**

> Privacy

表达意图：导航标签。

审阅备注：暂未标出具体语言问题，仍待用户审阅。

状态：待用户审阅。

来源：[website/theme/components/HomeFooter/index.tsx:16](../../../website/theme/components/HomeFooter/index.tsx)，[website/theme/components/HomeFooter/index.tsx:31](../../../website/theme/components/HomeFooter/index.tsx)，[website/docs/zh/_nav.json:16](../../../website/docs/zh/_nav.json)，[website/docs/en/_nav.json:16](../../../website/docs/en/_nav.json)

### N08 · 安全入口

**中文原文**

> 安全

**English**

> Security

表达意图：导航标签。

审阅备注：暂未标出具体语言问题，仍待用户审阅。

状态：待用户审阅。

来源：[website/theme/components/HomeFooter/index.tsx:17](../../../website/theme/components/HomeFooter/index.tsx)，[website/theme/components/HomeFooter/index.tsx:32](../../../website/theme/components/HomeFooter/index.tsx)

### N09 · 服务状态入口

**中文原文**

> 服务状态

**English**

> Service status

表达意图：导航标签。

审阅备注：暂未标出具体语言问题，仍待用户审阅。

状态：待用户审阅。

来源：[website/theme/components/HomeFooter/index.tsx:18](../../../website/theme/components/HomeFooter/index.tsx)，[website/theme/components/HomeFooter/index.tsx:33](../../../website/theme/components/HomeFooter/index.tsx)

### N10 · 支持入口

**中文原文**

> 支持

**English**

> Support

表达意图：导航标签。

审阅备注：暂未标出具体语言问题，仍待用户审阅。

状态：待用户审阅。

来源：[website/theme/components/HomeFooter/index.tsx:19](../../../website/theme/components/HomeFooter/index.tsx)，[website/theme/components/HomeFooter/index.tsx:34](../../../website/theme/components/HomeFooter/index.tsx)，[website/docs/zh/_nav.json:20](../../../website/docs/zh/_nav.json)，[website/docs/en/_nav.json:20](../../../website/docs/en/_nav.json)

### N11 · 自托管入口

**中文原文**

> 自托管

**English**

> Self-hosting

表达意图：导航标签。

审阅备注：暂未标出具体语言问题，仍待用户审阅。

状态：待用户审阅。

来源：[website/theme/components/HomeFooter/index.tsx:20](../../../website/theme/components/HomeFooter/index.tsx)，[website/theme/components/HomeFooter/index.tsx:35](../../../website/theme/components/HomeFooter/index.tsx)

### N12 · 源码入口

**中文原文**

> GitHub

**English**

> GitHub

表达意图：导航标签。

审阅备注：暂未标出具体语言问题，仍待用户审阅。

状态：待用户审阅。

来源：[website/theme/components/HomeFooter/index.tsx:21](../../../website/theme/components/HomeFooter/index.tsx)，[website/theme/components/HomeFooter/index.tsx:36](../../../website/theme/components/HomeFooter/index.tsx)

### N13 · 版权与品牌声明

**中文原文**

> © 2026 RunBuoy。开源、可审计，并以隐私为先。

**English**

> © 2026 RunBuoy. Open source, auditable, and privacy-first.

表达意图：品牌署名与开源、隐私定位。

审阅备注：“隐私为先”是定位表态；需要由默认数据范围来支撑。

状态：待用户审阅。

来源：[website/theme/components/HomeFooter/index.tsx:22](../../../website/theme/components/HomeFooter/index.tsx)，[website/theme/components/HomeFooter/index.tsx:37](../../../website/theme/components/HomeFooter/index.tsx)

## App Store 宣传图

### A01.T · 第 1 张标题

**中文原文**

> 离开电脑，
> 进度仍在眼前。

**English**

> Step away.
> Stay in the know.

表达意图：展示锁屏状态。

审阅备注：首张仍强调“看进度”；Agent 接入和重要消息没有体现，“就知道跑到哪”也依赖任务上报。

状态：待用户审阅。

来源：[assets/marketing/sources/copy.json:4](../../../assets/marketing/sources/copy.json)

### A01.S · 第 1 张副标题

**中文原文**

> 抬手看锁屏，就知道任务跑到哪了。

**English**

> Your task’s progress. Right on your Lock Screen.

表达意图：展示锁屏状态。

审阅备注：首张仍强调“看进度”；Agent 接入和重要消息没有体现，“就知道跑到哪”也依赖任务上报。

状态：待用户审阅。

来源：[assets/marketing/sources/copy.json:4](../../../assets/marketing/sources/copy.json)

### A01.N · 第 1 张脚注

**中文原文**

> Mac / Linux 长任务，在 iPhone 随身看

**English**

> Long-running Mac & Linux tasks, within reach

表达意图：示例说明或兼容性/功能条件。

审阅备注：检查是否把理解主卖点必需的条件藏进小字。

状态：待用户审阅。

来源：[assets/marketing/sources/copy.json:4](../../../assets/marketing/sources/copy.json)

### A02.T · 第 2 张标题

**中文原文**

> 成了，还是出错了？
> 看一眼就知道。

**English**

> Finished? Failed?
> Know at a glance.

表达意图：展示成功/失败与历史。

审阅备注：“成了/出错了”口语风格需确认；英文 Finished 包含失败结束，二者不是互斥结果。

状态：待用户审阅。

来源：[assets/marketing/sources/copy.json:5](../../../assets/marketing/sources/copy.json)

### A02.S · 第 2 张副标题

**中文原文**

> 成功、失败与历史记录，清清楚楚。

**English**

> Clear results. A history you can come back to.

表达意图：展示成功/失败与历史。

审阅备注：“成了/出错了”口语风格需确认；英文 Finished 包含失败结束，二者不是互斥结果。

状态：待用户审阅。

来源：[assets/marketing/sources/copy.json:5](../../../assets/marketing/sources/copy.json)

### A02.N · 第 2 张脚注

**中文原文**

> 示例任务与演示数据

**English**

> Sample tasks and demonstration data

表达意图：示例说明或兼容性/功能条件。

审阅备注：检查是否把理解主卖点必需的条件藏进小字。

状态：待用户审阅。

来源：[assets/marketing/sources/copy.json:5](../../../assets/marketing/sources/copy.json)

### A03.T · 第 3 张标题

**中文原文**

> 几台电脑，
> 一处看清。

**English**

> Your computers.
> One clear view.

表达意图：展示多机任务。

审阅备注：默认展示训练/构建/备份，未体现 Agent；多机是否值得占第三张还需确认。

状态：待用户审阅。

来源：[assets/marketing/sources/copy.json:6](../../../assets/marketing/sources/copy.json)

### A03.S · 第 3 张副标题

**中文原文**

> 模型训练、构建、备份，集中查看。

**English**

> Training, builds, and backups — all together.

表达意图：展示多机任务。

审阅备注：默认展示训练/构建/备份，未体现 Agent；多机是否值得占第三张还需确认。

状态：待用户审阅。

来源：[assets/marketing/sources/copy.json:6](../../../assets/marketing/sources/copy.json)

### A03.N · 第 3 张脚注

**中文原文**

> 支持 macOS 与 Linux · 电脑需安装 RunBuoy CLI

**English**

> macOS & Linux · RunBuoy CLI required on your computer

表达意图：示例说明或兼容性/功能条件。

审阅备注：检查是否把理解主卖点必需的条件藏进小字。

状态：待用户审阅。

来源：[assets/marketing/sources/copy.json:6](../../../assets/marketing/sources/copy.json)

### A04.T · 第 4 张标题

**中文原文**

> 不只知道在跑，
> 还知道跑到哪。

**English**

> See which phase.
> Know how far.

表达意图：展示阶段、进度与消息。

审阅备注：与第 1 张高度重复；“真实”指上报来源，截图数据本身是示例。

状态：待用户审阅。

来源：[assets/marketing/sources/copy.json:7](../../../assets/marketing/sources/copy.json)

### A04.S · 第 4 张副标题

**中文原文**

> 阶段、真实进度和任务消息，随时查看。

**English**

> Follow real progress, phases, and task messages.

表达意图：展示阶段、进度与消息。

审阅备注：与第 1 张高度重复；“真实”指上报来源，截图数据本身是示例。

状态：待用户审阅。

来源：[assets/marketing/sources/copy.json:7](../../../assets/marketing/sources/copy.json)

### A04.N · 第 4 张脚注

**中文原文**

> 百分比与时间估计来自任务显式报告

**English**

> Percentages and time estimates require explicit task reports

表达意图：示例说明或兼容性/功能条件。

审阅备注：检查是否把理解主卖点必需的条件藏进小字。

状态：待用户审阅。

来源：[assets/marketing/sources/copy.json:7](../../../assets/marketing/sources/copy.json)

### A05.T · 第 5 张标题

**中文原文**

> 扫一下，
> 连接你的电脑。

**English**

> Scan. Pair.
> You’re connected.

表达意图：展示配对路径。

审阅备注：副标题直接让用户安装 CLI，没有表达 Agent 是主要安装手段；等核心文案确认后一起重出图片。

状态：待用户审阅。

来源：[assets/marketing/sources/copy.json:8](../../../assets/marketing/sources/copy.json)

### A05.S · 第 5 张副标题

**中文原文**

> 安装 CLI，扫码配对，再启动任务。

**English**

> Install the CLI, pair your phone, then start a task.

表达意图：展示配对路径。

审阅备注：副标题直接让用户安装 CLI，没有表达 Agent 是主要安装手段；等核心文案确认后一起重出图片。

状态：待用户审阅。

来源：[assets/marketing/sources/copy.json:8](../../../assets/marketing/sources/copy.json)

### A05.N · 第 5 张脚注

**中文原文**

> iOS 18 及以上 · macOS / Linux · 需联网

**English**

> iOS 18+ · macOS / Linux · Internet connection required

表达意图：示例说明或兼容性/功能条件。

审阅备注：检查是否把理解主卖点必需的条件藏进小字。

状态：待用户审阅。

来源：[assets/marketing/sources/copy.json:8](../../../assets/marketing/sources/copy.json)

### A06.T · 第 6 张标题

**中文原文**

> 工作留在电脑，
> 状态带在身边。

**English**

> Take the status.
> Keep the work local.

表达意图：说明本地执行与数据边界。

审阅备注：“工作留在电脑”边界过宽；具体可证明的是 RunBuoy 不上传默认排除字段、手机只读。

状态：待用户审阅。

来源：[assets/marketing/sources/copy.json:9](../../../assets/marketing/sources/copy.json)

### A06.S · 第 6 张副标题

**中文原文**

> 命令、源码与完整日志默认留在本机。

**English**

> Commands, source code, and full logs stay local by default.

表达意图：说明本地执行与数据边界。

审阅备注：“工作留在电脑”边界过宽；具体可证明的是 RunBuoy 不上传默认排除字段、手机只读。

状态：待用户审阅。

来源：[assets/marketing/sources/copy.json:9](../../../assets/marketing/sources/copy.json)

### A06.N · 第 6 张脚注

**中文原文**

> 可选安全日志摘要需显式启用 · 手机端只读

**English**

> Sanitized log excerpts are opt-in · Your phone is read-only

表达意图：示例说明或兼容性/功能条件。

审阅备注：检查是否把理解主卖点必需的条件藏进小字。

状态：待用户审阅。

来源：[assets/marketing/sources/copy.json:9](../../../assets/marketing/sources/copy.json)

### A01.L · 第一张功能标签

**中文原文**

> 实时活动 · 灵动岛

**English**

> Live Activities · Dynamic Island

表达意图：标识 iOS 展示形式。

审阅备注：图片实际展示锁屏；灵动岛是能力标签，不是该图实截。

状态：待用户审阅。

来源：[assets/marketing/scripts/render.swift:114](../../../assets/marketing/scripts/render.swift)

### A06.D1 · 数据流 1

**中文原文**

> 电脑执行任务

**English**

> Your computer runs it

表达意图：说明执行位置。

审阅备注：暂未标出具体语言问题，仍待用户审阅。

状态：待用户审阅。

来源：[assets/marketing/scripts/render.swift:128](../../../assets/marketing/scripts/render.swift)

### A06.D2 · 数据流 2

**中文原文**

> Server 转发状态

**English**

> Server relays status

表达意图：说明服务端职责。

审阅备注：Server 是实现术语；用户是否需要在宣传图理解它值得讨论。

状态：待用户审阅。

来源：[assets/marketing/scripts/render.swift:128](../../../assets/marketing/scripts/render.swift)

### A06.D3 · 数据流 3

**中文原文**

> iPhone 只读展示

**English**

> iPhone keeps you in view

表达意图：说明手机职责。

审阅备注：英文没有明确表达只读，与中文语义不完全一致。

状态：待用户审阅。

来源：[assets/marketing/scripts/render.swift:128](../../../assets/marketing/scripts/render.swift)

### A06.L · 权限说明

**中文原文**

> 不在手机上启动、停止或重试任务。

**English**

> No remote start, stop, or retry.

表达意图：说明手机不执行控制操作。

审阅备注：暂未标出具体语言问题，仍待用户审阅。

状态：待用户审阅。

来源：[assets/marketing/scripts/render.swift:136](../../../assets/marketing/scripts/render.swift)

## 分享卡片

### O01 · 主标题

**中文原文**

> 离开电脑，
> 进度就在手边。

**English**

> Step away.
> Stay in the know.

表达意图：分享时概括使用收益。

审阅备注：仍重复离开电脑/在手边；需要跟随最终定位。

状态：待用户审阅。

来源：[assets/marketing/scripts/render.swift:150](../../../assets/marketing/scripts/render.swift)

### O02 · 平台说明

**中文原文**

> Mac / Linux → iPhone

**English**

> Mac / Linux → iPhone

表达意图：说明平台与方向。

审阅备注：暂未标出具体语言问题，仍待用户审阅。

状态：待用户审阅。

来源：[assets/marketing/scripts/render.swift:151](../../../assets/marketing/scripts/render.swift)

## 通用固定文字

### H00 · 品牌名

**中文原文**

> RunBuoy

**English**

> RunBuoy

表达意图：现有品牌名。

审阅备注：暂未标出具体语言问题，仍待用户审阅。

状态：待用户审阅。

来源：[assets/marketing/scripts/render.swift:85](../../../assets/marketing/scripts/render.swift)

### H06 · 首屏平台眉题

**中文原文**

> MAC / LINUX → IPHONE

**English**

> MAC / LINUX → IPHONE

表达意图：说明平台与方向。

审阅备注：暂未标出具体语言问题，仍待用户审阅。

状态：待用户审阅。

来源：[website/theme/components/HomeHero/index.tsx](../../../website/theme/components/HomeHero/index.tsx)

## Agent 安装提示词

### G01 · 提示词段落 1

**中文原文**

> 请帮我安装并验证 RunBuoy：

**English**

> Help me install and verify RunBuoy:

表达意图：界定安装并验证的请求。

审阅备注：这是可执行安装指令，不是对外卖点；首页与快速开始复用同一份内容，并通过一致性检查。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/installPrompts.ts:2](../../../website/theme/components/ChineseHome/installPrompts.ts)

### G02 · 提示词段落 2

**中文原文**

> 1. 使用你原生支持的 Skill 安装机制，从
> https://github.com/Cabbyte/RunBuoy/tree/main/skills/runbuoy
> 安装或更新 RunBuoy Skill，完整保留 SKILL.md、agents/openai.yaml、references/ 和 scripts/ 目录，不要猜测安装路径。

**English**

> 1. Use your native Skill installation mechanism to install or update the RunBuoy Skill from
> https://github.com/Cabbyte/RunBuoy/tree/main/skills/runbuoy
> Preserve SKILL.md, agents/openai.yaml, references/, and scripts/ in full. Do not guess an installation path.

表达意图：安装或更新 Skill，完整保留脚本与参考。

审阅备注：这是可执行安装指令，不是对外卖点；首页与快速开始复用同一份内容，并通过一致性检查。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/installPrompts.ts:4](../../../website/theme/components/ChineseHome/installPrompts.ts)

### G03 · 提示词段落 3

**中文原文**

> 2. 读取该 Skill 的 references/installation.md，按其中的规则检测 CLI。先检查 command -v runbuoy；找不到命令且 uv 已可用时，用 uv tool dir --bin 检查实际目录中是否已有 runbuoy。已安装但不在 PATH 中时修复路径，不要重复安装；确实未安装且 uv 已可用时，执行：
> uv tool install --python 3.12 runbuoy

**English**

> 2. Read references/installation.md from that Skill and follow its rules to detect the CLI. Start with command -v runbuoy. If it is not found and uv is available, use uv tool dir --bin to check for an existing runbuoy executable. Repair PATH for an installed CLI instead of reinstalling it. Only if it is absent and uv is available, run:
> uv tool install --python 3.12 runbuoy

表达意图：区分 CLI 未安装与 PATH 缺失，避免重复安装。

审阅备注：这是可执行安装指令，不是对外卖点；首页与快速开始复用同一份内容，并通过一致性检查。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/installPrompts.ts:8](../../../website/theme/components/ChineseHome/installPrompts.ts)

### G04 · 提示词段落 4

**中文原文**

> 3. 如果缺少 uv、tmux，或者需要 sudo、系统包管理器或 curl 安装器，请先说明将执行的命令并等待我的确认。

**English**

> 3. If uv or tmux is missing, or sudo, a system package manager, or a curl installer is required, explain the exact command and wait for my approval.

表达意图：处理缺失系统依赖与需要额外确认的命令。

审阅备注：这是可执行安装指令，不是对外卖点；首页与快速开始复用同一份内容，并通过一致性检查。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/installPrompts.ts:11](../../../website/theme/components/ChineseHome/installPrompts.ts)

### G07 · 提示词段落 5

**中文原文**

> 4. 对 uv 安装的 CLI，按安装文档运行 Skill 自带的 scripts/ensure_cli_path.py --repair，验证移除临时 PATH 后，新开的交互式终端和登录终端都能找到命令。再按输出在当前执行 Shell 中启用 PATH、刷新命令缓存。后续独立工具调用也需保留该 PATH。不要把绝对路径可运行或 uv run 成功当作安装完成；若验证失败，继续检查 Shell 配置并说明未通过的项目。

**English**

> 4. For a uv-installed CLI, follow the installation reference to run the Skill's scripts/ensure_cli_path.py --repair. Verify that fresh interactive and login shells find the command without inheriting the temporary PATH entry. Apply the reported PATH activation in the current execution shell and refresh its command cache. Keep that PATH in subsequent independent tool calls too. An absolute executable path or a successful uv run is not proof of a complete installation. If verification fails, investigate shell configuration and report the incomplete checks.

表达意图：修复 PATH，分别验证当前会话与新终端。

审阅备注：这是可执行安装指令，不是对外卖点；首页与快速开始复用同一份内容，并通过一致性检查。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/installPrompts.ts:13](../../../website/theme/components/ChineseHome/installPrompts.ts)

### G05 · 提示词段落 6

**中文原文**

> 5. 在当前 Shell 直接运行：
> command -v runbuoy
> runbuoy --version
> runbuoy doctor --json
> runbuoy capabilities --json

**English**

> 5. Run these commands directly in the current shell:
> command -v runbuoy
> runbuoy --version
> runbuoy doctor --json
> runbuoy capabilities --json

表达意图：通过直接命令运行安装验证。

审阅备注：这是可执行安装指令，不是对外卖点；首页与快速开始复用同一份内容，并通过一致性检查。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/installPrompts.ts:15](../../../website/theme/components/ChineseHome/installPrompts.ts)

### G06 · 提示词段落 7

**中文原文**

> 汇报 Skill 是否能以 $runbuoy 被发现、CLI 路径与版本、当前及新终端的 PATH 验证结果、local_ready 和 delivery 状态。不要启动配对、Demo、被监控命令，也不要上传日志。

**English**

> Report whether the Skill is discoverable as $runbuoy, the CLI path and version, PATH verification in the current and fresh terminals, local_ready, and delivery status. Do not start pairing, a demo, or any monitored command, and do not upload logs.

表达意图：汇报路径验证结果，并限定本次执行范围。

审阅备注：这是可执行安装指令，不是对外卖点；首页与快速开始复用同一份内容，并通过一致性检查。

状态：待用户审阅。

来源：[website/theme/components/HomeContent/installPrompts.ts:21](../../../website/theme/components/ChineseHome/installPrompts.ts)

## 下载页全文

### D01 · 页面描述

**中文原文**

> 在 App Store 免费下载 RunBuoy，用 iPhone 查看 Mac 与 Linux 长任务的状态、进度和结果。

**English**

> Get RunBuoy free on the App Store. Follow the status, progress, and results of long-running Mac and Linux tasks from your iPhone.

表达意图：搜索与分享摘要。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/download.md:2](../../../website/docs/zh/download.md)，[website/docs/en/download.md:2](../../../website/docs/en/download.md)

### D02 · 标题

**中文原文**

> # 下载 RunBuoy

**English**

> # Get RunBuoy

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/download.md:5](../../../website/docs/zh/download.md)，[website/docs/en/download.md:5](../../../website/docs/en/download.md)

### D03 · 正文

**中文原文**

> 离开电脑，也知道任务跑到哪了。

**English**

> Step away. Stay in the know.

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/download.md:7](../../../website/docs/zh/download.md)，[website/docs/en/download.md:7](../../../website/docs/en/download.md)

### D04 · 正文

**中文原文**

> **[在 App Store 下载 RunBuoy](https://apps.apple.com/cn/app/runbuoy/id6795591930)**

**English**

> **[Download RunBuoy on the App Store](https://apps.apple.com/us/app/runbuoy/id6795591930)**

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/download.md:9](../../../website/docs/zh/download.md)，[website/docs/en/download.md:9](../../../website/docs/en/download.md)

### D05 · 正文

**中文原文**

> RunBuoy 免费下载，需要 **iOS 18 或更新版本**。带有灵动岛的机型也可以在灵动岛查看任务；其他支持的 iPhone 可以使用 App 和锁屏实时活动。

**English**

> RunBuoy is free to download and requires **iOS 18 or later**. Dynamic Island is available on supported models. Other supported iPhones can use the app and Lock Screen Live Activities.

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/download.md:11](../../../website/docs/zh/download.md)，[website/docs/en/download.md:11](../../../website/docs/en/download.md)

### D06 · 标题

**中文原文**

> ## 下载后，连接你的电脑

**English**

> ## Next, connect your computer

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/download.md:13](../../../website/docs/zh/download.md)，[website/docs/en/download.md:13](../../../website/docs/en/download.md)

### D07 · 正文

**中文原文**

> RunBuoy 的任务从 **macOS 或 Linux** 启动。推荐把[安装提示词](https://www.runbuoy.cloud/guide/#agent-install)交给 Codex 或其他支持 Skill 的 Agent，安装并验证 RunBuoy Skill 与 CLI。

**English**

> Tasks start on **macOS or Linux**. Use the [installation prompt](https://www.runbuoy.cloud/en/guide/#agent-install) with Codex or another Skill-enabled agent to install and verify the RunBuoy Skill and CLI.

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/download.md:15](../../../website/docs/zh/download.md)，[website/docs/en/download.md:15](../../../website/docs/en/download.md)

### D08 · 条目

**中文原文**

> 1. [使用 Agent 安装 Skill 与 CLI](https://www.runbuoy.cloud/guide/#agent-install)。

**English**

> 1. [Install the Skill and CLI with an agent](https://www.runbuoy.cloud/en/guide/#agent-install).

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/download.md:17](../../../website/docs/zh/download.md)，[website/docs/en/download.md:17](../../../website/docs/en/download.md)

### D09 · 条目

**中文原文**

> 2. 在电脑运行 `runbuoy device pair`，用 App 扫码并确认电脑身份。

**English**

> 2. Run `runbuoy device pair` on your computer. Scan the QR code in the app and confirm the computer.

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/download.md:18](../../../website/docs/zh/download.md)，[website/docs/en/download.md:18](../../../website/docs/en/download.md)

### D10 · 条目

**中文原文**

> 3. 主动运行 `runbuoy demo live-activity`，确认手机能收到演示状态。

**English**

> 3. Run `runbuoy demo live-activity` yourself to check that the demo reaches your phone.

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/download.md:19](../../../website/docs/zh/download.md)，[website/docs/en/download.md:19](../../../website/docs/en/download.md)

### D11 · 条目

**中文原文**

> 4. [接入自己的命令](https://www.runbuoy.cloud/guide/run)；如果需要百分比或预计完成时间，再[接入显式进度](https://www.runbuoy.cloud/guide/progress)。

**English**

> 4. [Connect your own command](https://www.runbuoy.cloud/en/guide/run). To show percentages or time estimates, [report explicit progress](https://www.runbuoy.cloud/en/guide/progress).

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/download.md:20](../../../website/docs/zh/download.md)，[website/docs/en/download.md:20](../../../website/docs/en/download.md)

### D12 · 正文

**中文原文**

> [查看完整配对指南](https://www.runbuoy.cloud/guide/pairing)

**English**

> [Read the full pairing guide](https://www.runbuoy.cloud/en/guide/pairing)

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/download.md:22](../../../website/docs/zh/download.md)，[website/docs/en/download.md:22](../../../website/docs/en/download.md)

### D13 · 条目

**中文原文**

> :::info 服务区域

**English**

> :::info Service region

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/download.md:24](../../../website/docs/zh/download.md)，[website/docs/en/download.md:24](../../../website/docs/en/download.md)

### D14 · 正文

**中文原文**

> 当前官方端到端流程使用 `Global` 服务。iPhone 只展示状态，不远程启动、停止或重试任务。首次接入需要联网。

**English**

> The official end-to-end flow currently uses the `Global` service. Your iPhone displays status; it cannot remotely start, stop, or retry a task. Initial setup requires an internet connection.

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/download.md:25](../../../website/docs/zh/download.md)，[website/docs/en/download.md:25](../../../website/docs/en/download.md)

### D15 · 折叠入口

**中文原文**

> 手动安装 CLI

**English**

> Manual CLI installation

表达意图：将手动方式作为备选入口。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/download.md:29](../../../website/docs/zh/download.md)，[website/docs/en/download.md:29](../../../website/docs/en/download.md)

### D16 · 正文

**中文原文**

> 不使用 Agent 时，可通过 `uv` 安装 CLI，并准备好 `tmux`。uv 会管理所需的 Python 3.12 环境。

**English**

> Without an agent, install the CLI with `uv` and make sure `tmux` is available. uv manages the required Python 3.12 environment.

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/download.md:31](../../../website/docs/zh/download.md)，[website/docs/en/download.md:31](../../../website/docs/en/download.md)

### D17 · 命令或提示词

**中文原文**

> ```bash
> uv tool install --python 3.12 runbuoy
> ```

**English**

> ```bash
> uv tool install --python 3.12 runbuoy
> ```

表达意图：提供可执行的安装/配对/示例指令。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/download.md:33](../../../website/docs/zh/download.md)，[website/docs/en/download.md:33](../../../website/docs/en/download.md)

### D18 · 正文

**中文原文**

> [依赖准备与完整安装说明](https://www.runbuoy.cloud/guide/install)

**English**

> [Dependencies and full installation guide](https://www.runbuoy.cloud/en/guide/install)

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/download.md:37](../../../website/docs/zh/download.md)，[website/docs/en/download.md:37](../../../website/docs/en/download.md)

### D19 · 标题

**中文原文**

> ## 源码与进阶使用

**English**

> ## Source and advanced setup

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/download.md:41](../../../website/docs/zh/download.md)，[website/docs/en/download.md:41](../../../website/docs/en/download.md)

### D20 · 条目

**中文原文**

> - [GitHub 源码](https://github.com/Cabbyte/RunBuoy)

**English**

> - [Source on GitHub](https://github.com/Cabbyte/RunBuoy)

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/download.md:43](../../../website/docs/zh/download.md)，[website/docs/en/download.md:43](../../../website/docs/en/download.md)

### D21 · 条目

**中文原文**

> - [iOS 客户端源码](https://github.com/Cabbyte/RunBuoy/tree/main/apps/ios)

**English**

> - [iOS client source](https://github.com/Cabbyte/RunBuoy/tree/main/apps/ios)

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/download.md:44](../../../website/docs/zh/download.md)，[website/docs/en/download.md:44](../../../website/docs/en/download.md)

### D22 · 条目

**中文原文**

> - [自托管配置与客户端要求](https://www.runbuoy.cloud/self-hosting)

**English**

> - [Self-hosting and client requirements](https://www.runbuoy.cloud/en/self-hosting)

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/download.md:45](../../../website/docs/zh/download.md)，[website/docs/en/download.md:45](../../../website/docs/en/download.md)

## 快速开始全文

### Q01 · 页面描述

**中文原文**

> 使用 Agent 提示词或手动流程，在 macOS 或 Linux 上安装并验证 RunBuoy Skill 与 CLI。

**English**

> Install and verify the RunBuoy Skill and CLI on macOS or Linux with an agent prompt or the manual flow.

表达意图：搜索与分享摘要。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:2](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:2](../../../website/docs/en/guide/index.mdx)

### Q02 · 标题

**中文原文**

> # 快速开始

**English**

> # Quick Start

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:5](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:5](../../../website/docs/en/guide/index.mdx)

### Q03 · 正文

**中文原文**

> 先在 iPhone [从 App Store 下载 RunBuoy](https://apps.apple.com/cn/app/runbuoy/id6795591930)（iOS 18+），再在 Mac 或 Linux 安装 CLI。推荐把下面的安装提示词交给支持 Skill 的 Agent；手动安装步骤在下方折叠区。

**English**

> First, [get RunBuoy on the App Store](https://apps.apple.com/us/app/runbuoy/id6795591930) for your iPhone (iOS 18+). Use the prompt below with a Skill-enabled agent to install on your Mac or Linux computer. Manual installation is collapsed below.

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:9](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:9](../../../website/docs/en/guide/index.mdx)

### Q04 · 正文

**中文原文**

> 完整流程是：**下载 App → 安装 CLI → 配对电脑 → 运行任务**。安装与验证完成后，继续本文末尾的手机配对与演示。

**English**

> The complete flow is: **get the app → install the CLI → pair your computer → start a task**. After installation, continue to the phone pairing section below.

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:11](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:11](../../../website/docs/en/guide/index.mdx)

### Q05 · 标题

**中文原文**

> ## 使用 Agent 安装（推荐）

**English**

> ## Install with an Agent (recommended)

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:15](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:15](../../../website/docs/en/guide/index.mdx)

### Q06 · 条目

**中文原文**

> :::tip 一条提示词安装 Skill + CLI

**English**

> :::tip One prompt installs the Skill + CLI

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:17](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:17](../../../website/docs/en/guide/index.mdx)

### Q07 · 正文

**中文原文**

> Agent 会先安装 RunBuoy Skill，再读取 Skill 自带的安全规则安装和验证 CLI。涉及 `sudo`、系统包管理器或 curl 安装器时，它必须先说明命令并等待确认。

**English**

> Your agent installs the RunBuoy Skill first, then reads its built-in safety rules to install and verify the CLI. It must explain the command and wait for approval before using `sudo`, a system package manager, or a curl installer.

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:18](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:18](../../../website/docs/en/guide/index.mdx)

### Q08 · 正文

**中文原文**

> 复制下面整段提示词并粘贴给支持 Skill 的 Agent：

**English**

> Copy the complete prompt and paste it into an agent that supports Skills:

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:21](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:21](../../../website/docs/en/guide/index.mdx)

### Q09 · 命令或提示词

**中文原文**

> ```text
> 请帮我安装并验证 RunBuoy：
> 
> 1. 使用你原生支持的 Skill 安装机制，从
> https://github.com/Cabbyte/RunBuoy/tree/main/skills/runbuoy
> 安装或更新 RunBuoy Skill，完整保留 SKILL.md、agents/openai.yaml、references/ 和 scripts/ 目录，不要猜测安装路径。
> 
> 2. 读取该 Skill 的 references/installation.md，按其中的规则检测 CLI。先检查 command -v runbuoy；找不到命令且 uv 已可用时，用 uv tool dir --bin 检查实际目录中是否已有 runbuoy。已安装但不在 PATH 中时修复路径，不要重复安装；确实未安装且 uv 已可用时，执行：
> uv tool install --python 3.12 runbuoy
> 
> 3. 如果缺少 uv、tmux，或者需要 sudo、系统包管理器或 curl 安装器，请先说明将执行的命令并等待我的确认。
> 
> 4. 对 uv 安装的 CLI，按安装文档运行 Skill 自带的 scripts/ensure_cli_path.py --repair，验证移除临时 PATH 后，新开的交互式终端和登录终端都能找到命令。再按输出在当前执行 Shell 中启用 PATH、刷新命令缓存。后续独立工具调用也需保留该 PATH。不要把绝对路径可运行或 uv run 成功当作安装完成；若验证失败，继续检查 Shell 配置并说明未通过的项目。
> 
> 5. 在当前 Shell 直接运行：
> command -v runbuoy
> runbuoy --version
> runbuoy doctor --json
> runbuoy capabilities --json
> 
> 汇报 Skill 是否能以 $runbuoy 被发现、CLI 路径与版本、当前及新终端的 PATH 验证结果、local_ready 和 delivery 状态。不要启动配对、Demo、被监控命令，也不要上传日志。
> ```

**English**

> ```text
> Help me install and verify RunBuoy:
> 
> 1. Use your native Skill installation mechanism to install or update the RunBuoy Skill from
> https://github.com/Cabbyte/RunBuoy/tree/main/skills/runbuoy
> Preserve SKILL.md, agents/openai.yaml, references/, and scripts/ in full. Do not guess an installation path.
> 
> 2. Read references/installation.md from that Skill and follow its rules to detect the CLI. Start with command -v runbuoy. If it is not found and uv is available, use uv tool dir --bin to check for an existing runbuoy executable. Repair PATH for an installed CLI instead of reinstalling it. Only if it is absent and uv is available, run:
> uv tool install --python 3.12 runbuoy
> 
> 3. If uv or tmux is missing, or sudo, a system package manager, or a curl installer is required, explain the exact command and wait for my approval.
> 
> 4. For a uv-installed CLI, follow the installation reference to run the Skill's scripts/ensure_cli_path.py --repair. Verify that fresh interactive and login shells find the command without inheriting the temporary PATH entry. Apply the reported PATH activation in the current execution shell and refresh its command cache. Keep that PATH in subsequent independent tool calls too. An absolute executable path or a successful uv run is not proof of a complete installation. If verification fails, investigate shell configuration and report the incomplete checks.
> 
> 5. Run these commands directly in the current shell:
> command -v runbuoy
> runbuoy --version
> runbuoy doctor --json
> runbuoy capabilities --json
> 
> Report whether the Skill is discoverable as $runbuoy, the CLI path and version, PATH verification in the current and fresh terminals, local_ready, and delivery status. Do not start pairing, a demo, or any monitored command, and do not upload logs.
> ```

表达意图：提供可执行的安装/配对/示例指令。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:23](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:23](../../../website/docs/en/guide/index.mdx)

### Q10 · 正文

**中文原文**

> 这个流程只负责安装与验证，不会配对手机或启动任务。[了解 Agent 安装提示词的设计与使用方式](https://www.runbuoy.cloud/guide/agent-skill)。

**English**

> This flow only installs and verifies RunBuoy. It does not pair a phone or start a run. [Learn how the agent installation prompt is designed and used](https://www.runbuoy.cloud/en/guide/agent-skill).

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:46](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:46](../../../website/docs/en/guide/index.mdx)

### Q11 · 折叠入口

**中文原文**

> 手动安装 CLI 与可选 Python API

**English**

> Manual CLI installation and optional Python API

表达意图：将手动方式作为备选入口。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:49](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:49](../../../website/docs/en/guide/index.mdx)

### Q12 · 标题

**中文原文**

> ## 手动安装 CLI

**English**

> ## Install the CLI manually

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:51](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:51](../../../website/docs/en/guide/index.mdx)

### Q13 · 条目

**中文原文**

> :::tip 手动安装 · 当前可用

**English**

> :::tip Manual installation · Available now

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:53](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:53](../../../website/docs/en/guide/index.mdx)

### Q14 · 正文

**中文原文**

> 下面的 uv 流程是公开、可执行的安装方式，支持 macOS 与 Linux。

**English**

> The uv flow below is a public, executable installation path for macOS and Linux.

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:54](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:54](../../../website/docs/en/guide/index.mdx)

### Q15 · 标题

**中文原文**

> ### 1. 安装系统依赖与 uv

**English**

> ### 1. Install system dependencies and uv

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:57](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:57](../../../website/docs/en/guide/index.mdx)

### Q16 · 选项标签

**中文原文**

> macOS

**English**

> macOS

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:60](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:60](../../../website/docs/en/guide/index.mdx)

### Q17 · 命令或提示词

**中文原文**

> ```bash
> brew install tmux uv
> uv tool update-shell
> ```

**English**

> ```bash
> brew install tmux uv
> uv tool update-shell
> ```

表达意图：提供可执行的安装/配对/示例指令。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:62](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:62](../../../website/docs/en/guide/index.mdx)

### Q18 · 选项标签

**中文原文**

> Debian / Ubuntu

**English**

> Debian / Ubuntu

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:68](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:68](../../../website/docs/en/guide/index.mdx)

### Q19 · 命令或提示词

**中文原文**

> ```bash
> sudo apt update
> sudo apt install tmux
> curl -LsSf https://astral.sh/uv/install.sh | sh
> uv tool update-shell
> ```

**English**

> ```bash
> sudo apt update
> sudo apt install tmux
> curl -LsSf https://astral.sh/uv/install.sh | sh
> uv tool update-shell
> ```

表达意图：提供可执行的安装/配对/示例指令。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:70](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:70](../../../website/docs/en/guide/index.mdx)

### Q20 · 选项标签

**中文原文**

> Fedora

**English**

> Fedora

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:78](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:78](../../../website/docs/en/guide/index.mdx)

### Q21 · 命令或提示词

**中文原文**

> ```bash
> sudo dnf install tmux
> curl -LsSf https://astral.sh/uv/install.sh | sh
> uv tool update-shell
> ```

**English**

> ```bash
> sudo dnf install tmux
> curl -LsSf https://astral.sh/uv/install.sh | sh
> uv tool update-shell
> ```

表达意图：提供可执行的安装/配对/示例指令。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:80](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:80](../../../website/docs/en/guide/index.mdx)

### Q22 · 选项标签

**中文原文**

> Arch Linux

**English**

> Arch Linux

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:87](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:87](../../../website/docs/en/guide/index.mdx)

### Q23 · 命令或提示词

**中文原文**

> ```bash
> sudo pacman -S tmux
> curl -LsSf https://astral.sh/uv/install.sh | sh
> uv tool update-shell
> ```

**English**

> ```bash
> sudo pacman -S tmux
> curl -LsSf https://astral.sh/uv/install.sh | sh
> uv tool update-shell
> ```

表达意图：提供可执行的安装/配对/示例指令。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:89](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:89](../../../website/docs/en/guide/index.mdx)

### Q24 · 正文

**中文原文**

> 重启终端后继续。uv 会自动下载并管理所需的 Python 3.12；`tmux` 是必须通过系统包管理器安装的依赖。

**English**

> Restart the terminal before continuing. uv downloads and manages the required Python 3.12 runtime; `tmux` is a system dependency that must come from your operating system package manager.

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:98](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:98](../../../website/docs/en/guide/index.mdx)

### Q25 · 标题

**中文原文**

> ### 2. 安装 CLI

**English**

> ### 2. Install the CLI

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:100](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:100](../../../website/docs/en/guide/index.mdx)

### Q26 · 命令或提示词

**中文原文**

> ```bash
> uv tool install --python 3.12 runbuoy
> uv tool update-shell
> export PATH="$(uv tool dir --bin):$PATH"
> hash -r
> command -v runbuoy
> ```

**English**

> ```bash
> uv tool install --python 3.12 runbuoy
> uv tool update-shell
> export PATH="$(uv tool dir --bin):$PATH"
> hash -r
> command -v runbuoy
> ```

表达意图：提供可执行的安装/配对/示例指令。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:102](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:102](../../../website/docs/en/guide/index.mdx)

### Q27 · 正文

**中文原文**

> 以上 PATH 命令适用于 Bash / Zsh；Fish 使用 `fish_add_path (uv tool dir --bin)`。安装后在新终端再次运行 `command -v runbuoy` 和 `runbuoy --version`，确认配置已保存。若仍找不到命令，请查看[PATH 排查](https://www.runbuoy.cloud/guide/install#troubleshooting)。

**English**

> The PATH commands above are for Bash / Zsh; in Fish use `fish_add_path (uv tool dir --bin)`. In a new terminal, run `command -v runbuoy` and `runbuoy --version` again to verify persistence. If the command is still missing, see [PATH troubleshooting](https://www.runbuoy.cloud/en/guide/install#troubleshooting).

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:110](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:110](../../../website/docs/en/guide/index.mdx)

### Q28 · 正文

**中文原文**

> 根据实际使用的 Shell 选择一个补全命令：

**English**

> Choose the completion command for the shell you actually use:

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:112](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:112](../../../website/docs/en/guide/index.mdx)

### Q29 · 选项标签

**中文原文**

> Bash

**English**

> Bash

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:115](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:115](../../../website/docs/en/guide/index.mdx)

### Q30 · 命令或提示词

**中文原文**

> ```bash
> runbuoy completion install bash
> ```

**English**

> ```bash
> runbuoy completion install bash
> ```

表达意图：提供可执行的安装/配对/示例指令。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:117](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:117](../../../website/docs/en/guide/index.mdx)

### Q31 · 选项标签

**中文原文**

> Zsh

**English**

> Zsh

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:122](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:122](../../../website/docs/en/guide/index.mdx)

### Q32 · 命令或提示词

**中文原文**

> ```bash
> runbuoy completion install zsh
> ```

**English**

> ```bash
> runbuoy completion install zsh
> ```

表达意图：提供可执行的安装/配对/示例指令。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:124](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:124](../../../website/docs/en/guide/index.mdx)

### Q33 · 选项标签

**中文原文**

> Fish

**English**

> Fish

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:129](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:129](../../../website/docs/en/guide/index.mdx)

### Q34 · 命令或提示词

**中文原文**

> ```bash
> runbuoy completion install fish
> ```

**English**

> ```bash
> runbuoy completion install fish
> ```

表达意图：提供可执行的安装/配对/示例指令。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:131](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:131](../../../website/docs/en/guide/index.mdx)

### Q35 · 标题

**中文原文**

> ### 3. 验证安装

**English**

> ### 3. Verify the installation

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:138](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:138](../../../website/docs/en/guide/index.mdx)

### Q36 · 命令或提示词

**中文原文**

> ```bash
> runbuoy --version
> runbuoy doctor --json
> runbuoy capabilities --json
> ```

**English**

> ```bash
> runbuoy --version
> runbuoy doctor --json
> runbuoy capabilities --json
> ```

表达意图：提供可执行的安装/配对/示例指令。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:140](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:140](../../../website/docs/en/guide/index.mdx)

### Q37 · 正文

**中文原文**

> doctor schema v2 的 `local_ready=true` 表示平台、Python、tmux 与本地存储已满足执行条件。`delivery.ready` 是独立状态；尚未配对或 Server 不可达时，本地 Run 仍完整可用。

**English**

> `local_ready=true` from doctor schema v2 confirms that the platform, Python, tmux, and local storage meet execution requirements. `delivery.ready` is separate; local Runs remain available before pairing or while the Server is unreachable.

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:146](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:146](../../../website/docs/en/guide/index.mdx)

### Q38 · 标题

**中文原文**

> ## 可选：在 Python 项目中使用 API

**English**

> ## Optional: use the Python API in a project

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:148](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:148](../../../website/docs/en/guide/index.mdx)

### Q39 · 正文

**中文原文**

> `uv tool` 创建的 CLI 环境与项目 Python 环境相互隔离。如果代码需要 `from runbuoy import progress` 等 API，请在项目根目录另行声明依赖：

**English**

> The CLI environment created by `uv tool` is isolated from your project environment. If your code imports APIs such as `from runbuoy import progress`, declare the dependency in the project root as well:

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:150](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:150](../../../website/docs/en/guide/index.mdx)

### Q40 · 命令或提示词

**中文原文**

> ```bash
> cd my-project
> uv add --optional runbuoy runbuoy
> uv sync --extra runbuoy
> ```

**English**

> ```bash
> cd my-project
> uv add --optional runbuoy runbuoy
> uv sync --extra runbuoy
> ```

表达意图：提供可执行的安装/配对/示例指令。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:152](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:152](../../../website/docs/en/guide/index.mdx)

### Q41 · 正文

**中文原文**

> 这是正常的双环境安装，不是重复配置。SDK 调用必须发生在 RunBuoy 启动的目标进程树内；详见[进度模式](https://www.runbuoy.cloud/guide/progress)。

**English**

> Installing into both environments is intentional. SDK calls must run inside the process tree started by RunBuoy; see [Progress modes](https://www.runbuoy.cloud/en/guide/progress).

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:158](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:158](../../../website/docs/en/guide/index.mdx)

### Q42 · 标题

**中文原文**

> ## 已经手动安装了 CLI？

**English**

> ## Already installed the CLI manually?

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:160](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:160](../../../website/docs/en/guide/index.mdx)

### Q43 · 正文

**中文原文**

> 仍然可以在任何时候使用上面的 Agent 提示词补装 Skill。Agent 会先运行 `command -v runbuoy`，检测到现有 CLI 后不会重复安装，只会继续验证环境。

**English**

> You can use the agent prompt above later to add the Skill. The agent checks `command -v runbuoy` first, so an existing CLI is not installed again; it simply continues with verification.

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:162](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:162](../../../website/docs/en/guide/index.mdx)

### Q44 · 标题

**中文原文**

> ## 连接手机并验证第一条动态

**English**

> ## Connect your phone and see the first update

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:166](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:166](../../../website/docs/en/guide/index.mdx)

### Q45 · 正文

**中文原文**

> 打开已安装的 App，完成引导。在电脑运行：

**English**

> Open the app and finish its introduction. On your computer, run:

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:168](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:168](../../../website/docs/en/guide/index.mdx)

### Q46 · 命令或提示词

**中文原文**

> ```bash
> runbuoy device pair
> ```

**English**

> ```bash
> runbuoy device pair
> ```

表达意图：提供可执行的安装/配对/示例指令。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:170](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:170](../../../website/docs/en/guide/index.mdx)

### Q47 · 正文

**中文原文**

> 用 App 扫描终端二维码，核对电脑身份并完成配对，然后主动运行一次演示：

**English**

> Scan the QR code in the app and confirm the computer. Then start a demo yourself:

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:174](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:174](../../../website/docs/en/guide/index.mdx)

### Q48 · 命令或提示词

**中文原文**

> ```bash
> runbuoy demo live-activity
> ```

**English**

> ```bash
> runbuoy demo live-activity
> ```

表达意图：提供可执行的安装/配对/示例指令。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:176](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:176](../../../website/docs/en/guide/index.mdx)

### Q49 · 正文

**中文原文**

> 确认 iPhone 收到演示状态后，将自己的命令放在 `runbuoy run --` 后启动。下面的脚本名需要替换为你自己的脚本：

**English**

> Once the update reaches your iPhone, put your own command after `runbuoy run --`. Replace the script name below with your own:

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:180](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:180](../../../website/docs/en/guide/index.mdx)

### Q50 · 命令或提示词

**中文原文**

> ```bash
> runbuoy run -- python3 your_task.py
> ```

**English**

> ```bash
> runbuoy run -- python3 your_task.py
> ```

表达意图：提供可执行的安装/配对/示例指令。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:182](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:182](../../../website/docs/en/guide/index.mdx)

### Q51 · 正文

**中文原文**

> 任务仍在电脑上运行，iPhone 只展示状态。普通命令提供运行状态与结果；百分比、阶段和预计完成时间需要任务显式报告。演示与真实任务都由你主动启动，安装提示词不会代你执行。

**English**

> Tasks keep running on your computer. The phone only shows status. Ordinary commands report running status and results; percentages, phases, and time estimates require explicit reports from the task. You start demos and tasks yourself; the installation prompt does not do this for you.

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:186](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:186](../../../website/docs/en/guide/index.mdx)

### Q52 · 标题

**中文原文**

> ## 下一步

**English**

> ## Next steps

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:188](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:188](../../../website/docs/en/guide/index.mdx)

### Q53 · 条目

**中文原文**

> - [完整安装、升级与卸载说明](https://www.runbuoy.cloud/guide/install)

**English**

> - [Complete installation, upgrade, and removal guide](https://www.runbuoy.cloud/en/guide/install)

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:190](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:190](../../../website/docs/en/guide/index.mdx)

### Q54 · 条目

**中文原文**

> - [配对更多电脑](https://www.runbuoy.cloud/guide/pairing)

**English**

> - [Pair more machines](https://www.runbuoy.cloud/en/guide/pairing)

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:191](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:191](../../../website/docs/en/guide/index.mdx)

### Q55 · 条目

**中文原文**

> - [运行命令与发送通知](https://www.runbuoy.cloud/guide/run)

**English**

> - [Run commands and send notifications](https://www.runbuoy.cloud/en/guide/run)

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:192](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:192](../../../website/docs/en/guide/index.mdx)

### Q56 · 条目

**中文原文**

> - [配置真实进度](https://www.runbuoy.cloud/guide/progress)

**English**

> - [Configure honest progress](https://www.runbuoy.cloud/en/guide/progress)

表达意图：说明获取、安装、验证或接入步骤。

审阅备注：操作性说明；不能据此将手动执行命令当成主要产品体验。

状态：待用户审阅。

来源：[website/docs/zh/guide/index.mdx:193](../../../website/docs/zh/guide/index.mdx)，[website/docs/en/guide/index.mdx:193](../../../website/docs/en/guide/index.mdx)
