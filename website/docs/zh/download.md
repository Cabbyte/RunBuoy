---
description: 在 App Store 免费下载 RunBuoy，用 iPhone 查看 Mac 与 Linux 长任务的状态、进度和结果。
---

# 下载 RunBuoy

扫一眼，掌握任务的进展。

**[在 App Store 下载 RunBuoy](https://apps.apple.com/cn/app/runbuoy/id6795591930)**

RunBuoy 免费下载，需要 **iOS 18 或更新版本**。带有灵动岛的机型也可以在灵动岛查看任务；其他支持的 iPhone 可以使用 App 和锁屏实时活动。

## 下载后，连接你的电脑

RunBuoy 的任务从 **macOS 或 Linux** 启动。推荐把[安装提示词](/guide/#agent-install)交给 Codex 或其他支持 Skill 的 Agent，安装并验证 RunBuoy Skill 与 CLI。

1. [使用 Agent 安装 Skill 与 CLI](/guide/#agent-install)。
2. 在电脑运行 `runbuoy device pair`，用 App 扫码并确认电脑身份。
3. 主动运行 `runbuoy demo live-activity`，确认手机能收到演示状态。
4. [接入自己的命令](/guide/run)；如果需要百分比或预计完成时间，再[接入显式进度](/guide/progress)。

[查看完整配对指南](/guide/pairing)

:::info 服务区域
当前官方端到端流程使用 `Global` 服务。iPhone 只展示状态，不远程启动、停止或重试任务。首次接入需要联网。
:::

<details>
<summary>手动安装 CLI</summary>

不使用 Agent 时，可通过 `uv` 安装 CLI，并准备好 `tmux`。uv 会管理所需的 Python 3.12 环境。

```bash
uv tool install --python 3.12 runbuoy
uv tool update-shell
export PATH="$(uv tool dir --bin):$PATH"
hash -r
runbuoy --version
```

以上命令适用于 Bash / Zsh；安装后在新终端再次运行 `runbuoy --version`。Fish 与 PATH 排查见完整安装说明。

[依赖准备与完整安装说明](/guide/install)

</details>

## 源码与进阶使用

- [GitHub 源码](https://github.com/Cabbyte/RunBuoy)
- [iOS 客户端源码](https://github.com/Cabbyte/RunBuoy/tree/main/apps/ios)
- [自托管配置与客户端要求](/self-hosting)
