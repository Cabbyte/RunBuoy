# ChatGPT Plugin UI 原图

捕获日期：2026-10-05（Asia/Shanghai）。源码：`main` 的 `45930228b7d59c4352b738f0daad51f67f3b76ae`，`apps/chatgpt`。

这些截图由本地开发预览直接渲染，使用项目内置 `demo.ts` 示例数据。界面为中文，fixture 的任务名与消息保留英文。未重绘界面，没有 ChatGPT 宿主外框，也不是本轮真实宿主的视觉验收。全部保留为可复用参考原图，尚未进入 `promoted`。

| 文件 | 内容 |
| --- | --- |
| [inline-zh.jpg](inline-zh.jpg) | 对话内紧凑卡片，运行概览与展开入口 |
| [workspace-detail-zh.jpg](workspace-detail-zh.jpg) | 展开工作台、选中训练任务、详情及「用于对话」按钮 |
| [history-zh.jpg](history-zh.jpg) | 任务历史 |
| [machines-zh.jpg](machines-zh.jpg) | 多台电脑及其任务 |
| [messages-zh.jpg](messages-zh.jpg) | 消息与关联任务入口 |

默认捕获视口为 1280 × 720，使用整页截图，因此原图高度随内容变化。文件哈希和来源见 [capture-manifest.json](capture-manifest.json)。

复现：在对应源码版本中运行 `npm run dev --prefix apps/chatgpt -- --port 5179 --strictPort`，打开 `http://127.0.0.1:5179/?demo&lang=zh&mode=inline`，通过 UI 展开、选中任务及切换视图。使用完毕关闭预览进程即可，无需启动 iOS 模拟器。
