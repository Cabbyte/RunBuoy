# 安全边界

电脑跑任务，手机看状态。RunBuoy 的查看端遵循最小权限：iPhone 与 ChatGPT Plugin 都不能远程控制电脑任务。

## 单向架构

```text
Machine → RunBuoy Server → iPhone
                        → ChatGPT Plugin（只读，私人预览）
```

iPhone 可以配对、接收通知、读取运行状态和移除自己的接收订阅，但不能：

- 启动、取消或重试电脑上的任务
- 发送信号、键盘输入或终端数据
- 批准、回复或控制 Agent
- 建立 SSH、隧道、终端流或控制 WebSocket

## 凭证

- 机器与设备使用不同作用域的随机 Bearer 凭证。
- 服务端只保存长期凭证的强哈希。
- 本地优先使用 Keychain 或 Secret Service。
- APNs 与 Live Activity Token 在服务端加密保存。
- 一次性配对挑战五分钟过期且不可重放。
- ChatGPT Plugin 使用独立的只读授权，连接需在 iPhone 确认，也可从 iPhone 撤销；不会复用机器的执行权限。

## 本地进程隔离

RunBuoy Worker 通过受保护的 manifest 启动原命令，不把用户命令拼接到 Shell 字符串。取消操作只存在于电脑本地，并作用于已记录的进程组。

完整的安全设计、威胁模型和自动化边界测试位于 [GitHub 仓库](https://github.com/Cabbyte/RunBuoy/tree/main/docs)。

发现安全问题时，请遵循[安全报告说明](https://github.com/Cabbyte/RunBuoy/security/policy)，并使用 [GitHub 私密漏洞报告](https://github.com/Cabbyte/RunBuoy/security/advisories/new)。不要在公开 Issue 中披露漏洞细节。非安全问题请前往[支持](/support)。
