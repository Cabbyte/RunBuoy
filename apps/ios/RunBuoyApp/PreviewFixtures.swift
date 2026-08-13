import Foundation

enum PreviewFixtures {
    static let baseDate = Date(timeIntervalSince1970: 1_785_076_800)

    static let activeRun = RunSnapshot(
        id: UUID(uuidString: "018f0d8a-8c0a-7000-8000-000000000001")!,
        machineID: "machine_mac_studio",
        machineName: "Mac Studio",
        title: "Gurobi experiment",
        source: "cli",
        executionStatus: .running,
        healthStatus: .healthy,
        attentionStatus: .none,
        progress: RunProgress(
            kind: .determinate,
            current: 72,
            total: 100,
            fraction: 0.72,
            unit: "items",
            source: "explicit"
        ),
        phase: "Optimizing",
        safeMessage: "Solver gap reached 2.1%.",
        startedAt: baseDate.addingTimeInterval(-620),
        updatedAt: baseDate,
        endedAt: nil,
        estimatedEndAt: baseDate.addingTimeInterval(240),
        exitCode: nil,
        safeLogTail: nil,
        sequence: 42
    )

    static let failedRun = RunSnapshot(
        id: UUID(uuidString: "018f0d8a-8c0a-7000-8000-000000000002")!,
        machineID: "machine_ci",
        machineName: "CI Builder",
        title: "Release build",
        source: "webhook",
        executionStatus: .failed,
        healthStatus: .offline,
        attentionStatus: .warning,
        progress: RunProgress(
            kind: .indeterminate,
            current: nil,
            total: nil,
            fraction: nil,
            unit: nil,
            source: "unknown"
        ),
        phase: "Signing",
        safeMessage: "Release build stopped during signing.",
        startedAt: baseDate.addingTimeInterval(-1_800),
        updatedAt: baseDate.addingTimeInterval(-900),
        endedAt: baseDate.addingTimeInterval(-900),
        estimatedEndAt: nil,
        exitCode: 65,
        safeLogTail: [
            "[redacted] signing identity was unavailable",
            "Build finished with exit code 65"
        ],
        sequence: 18
    )

    static let heroActionRequiredRun = RunSnapshot(
        id: UUID(uuidString: "018f0d8a-8c0a-7000-8000-000000000301")!,
        machineID: "machine_mac_studio",
        machineName: "Mac Studio",
        title: "Release approval required",
        source: "cli",
        executionStatus: .running,
        healthStatus: .healthy,
        attentionStatus: .actionRequired,
        progress: RunProgress(
            kind: .determinate,
            current: 45,
            total: 100,
            fraction: 0.45,
            unit: "items",
            source: "explicit"
        ),
        phase: "Waiting for approval",
        safeMessage: "A release approval is required.",
        startedAt: baseDate.addingTimeInterval(-900),
        updatedAt: baseDate.addingTimeInterval(-120),
        endedAt: nil,
        estimatedEndAt: nil,
        exitCode: nil,
        safeLogTail: nil,
        sequence: 30
    )

    static let heroWarningRun = RunSnapshot(
        id: UUID(uuidString: "018f0d8a-8c0a-7000-8000-000000000302")!,
        machineID: "machine_ci",
        machineName: "CI Builder",
        title: "Release build warning",
        source: "webhook",
        executionStatus: .running,
        healthStatus: .healthy,
        attentionStatus: .warning,
        progress: RunProgress(
            kind: .determinate,
            current: 78,
            total: 100,
            fraction: 0.78,
            unit: "items",
            source: "explicit"
        ),
        phase: "Checking signing",
        safeMessage: "The signing check needs attention.",
        startedAt: baseDate.addingTimeInterval(-600),
        updatedAt: baseDate.addingTimeInterval(-30),
        endedAt: nil,
        estimatedEndAt: nil,
        exitCode: nil,
        safeLogTail: nil,
        sequence: 31
    )

    static let heroNewestHealthyRun = RunSnapshot(
        id: UUID(uuidString: "018f0d8a-8c0a-7000-8000-000000000303")!,
        machineID: "machine_mac_studio",
        machineName: "Mac Studio",
        title: "Newest healthy run",
        source: "cli",
        executionStatus: .running,
        healthStatus: .healthy,
        attentionStatus: .none,
        progress: RunProgress(
            kind: .determinate,
            current: 92,
            total: 100,
            fraction: 0.92,
            unit: "items",
            source: "explicit"
        ),
        phase: "Uploading artifacts",
        safeMessage: "Artifacts are uploading.",
        startedAt: baseDate.addingTimeInterval(-300),
        updatedAt: baseDate,
        endedAt: nil,
        estimatedEndAt: nil,
        exitCode: nil,
        safeLogTail: nil,
        sequence: 32
    )

    static let machine = MachineSnapshot(
        id: "machine_mac_studio",
        displayName: "Mac Studio",
        platform: "macOS",
        architecture: "arm64",
        cliVersion: "1.0.0",
        lastSeenAt: baseDate,
        pairedAt: baseDate.addingTimeInterval(-86_400),
        subscriptionID: "subscription_1",
        isSubscribed: true
    )

    static let ciMachine = MachineSnapshot(
        id: "machine_ci",
        displayName: "CI Builder in the release engineering laboratory",
        platform: "Linux",
        architecture: "x86_64",
        cliVersion: "1.0.0",
        lastSeenAt: baseDate.addingTimeInterval(-900),
        pairedAt: baseDate.addingTimeInterval(-172_800),
        subscriptionID: "subscription_2",
        isSubscribed: true
    )

    static let message = RichMessage(
        id: "notification_1",
        machineID: machine.id,
        title: "Dataset ready",
        subtitle: "Training artifacts",
        body: "The sanitized dataset summary is available on Mac Studio.",
        level: "success",
        fields: [.init(name: "Rows", value: "12,840")],
        createdAt: baseDate,
        expiresAt: nil
    )

    static let ciMessage = RichMessage(
        id: "notification_2",
        machineID: ciMachine.id,
        title: "Release build needs attention",
        subtitle: "Signing",
        body: "The release build stopped during signing.",
        level: "warning",
        fields: [],
        createdAt: baseDate.addingTimeInterval(-900),
        expiresAt: nil
    )

    static let events: [RunFeedEvent] = [
        RunFeedEvent(
            id: UUID(uuidString: "018f0d8a-8c0a-7000-8000-000000000010")!,
            sequence: 1,
            type: "run.started",
            occurredAt: activeRun.startedAt,
            phase: nil,
            message: "Run started",
            progress: nil
        ),
        RunFeedEvent(
            id: UUID(uuidString: "018f0d8a-8c0a-7000-8000-000000000011")!,
            sequence: 41,
            type: "run.progress",
            occurredAt: baseDate,
            phase: "Optimizing",
            message: "Processing item 72",
            progress: activeRun.progress
        )
    ]

    // App Store screenshots use a dedicated launch scenario so the richer
    // sample content never changes the fixtures used by the UI test suite.
    static let showcaseDate = Date()

    static let showcasePrimaryRun = RunSnapshot(
        id: UUID(uuidString: "018f0d8a-8c0a-7000-8000-000000000101")!,
        machineID: "showcase_mac_studio",
        machineName: "工作室 Mac Studio",
        title: "大模型微调 · 第 8 轮",
        source: "cli",
        executionStatus: .running,
        healthStatus: .healthy,
        attentionStatus: .none,
        progress: RunProgress(
            kind: .determinate,
            current: 7_800,
            total: 10_000,
            fraction: 0.78,
            unit: "steps",
            source: "explicit"
        ),
        phase: "训练第 8 / 10 个 Epoch",
        safeMessage: "验证集损失持续下降，预计约 7 分钟后完成。",
        startedAt: showcaseDate.addingTimeInterval(-47 * 60),
        updatedAt: showcaseDate.addingTimeInterval(-4),
        endedAt: nil,
        estimatedEndAt: showcaseDate.addingTimeInterval(7 * 60),
        exitCode: nil,
        safeLogTail: nil,
        sequence: 86
    )

    static let showcaseBuildRun = RunSnapshot(
        id: UUID(uuidString: "018f0d8a-8c0a-7000-8000-000000000102")!,
        machineID: "showcase_macbook",
        machineName: "出差 MacBook Pro",
        title: "iOS Release 构建",
        source: "cli",
        executionStatus: .running,
        healthStatus: .healthy,
        attentionStatus: .none,
        progress: RunProgress(
            kind: .determinate,
            current: 46,
            total: 100,
            fraction: 0.46,
            unit: "targets",
            source: "regex"
        ),
        phase: "正在编译 RunBuoyApp",
        safeMessage: "归档构建正在按计划进行。",
        startedAt: showcaseDate.addingTimeInterval(-14 * 60),
        updatedAt: showcaseDate.addingTimeInterval(-9),
        endedAt: nil,
        estimatedEndAt: showcaseDate.addingTimeInterval(8 * 60),
        exitCode: nil,
        safeLogTail: nil,
        sequence: 31
    )

    static let showcaseBackupRun = RunSnapshot(
        id: UUID(uuidString: "018f0d8a-8c0a-7000-8000-000000000103")!,
        machineID: "showcase_linux",
        machineName: "GPU 工作站",
        title: "实验数据增量备份",
        source: "cli",
        executionStatus: .running,
        healthStatus: .healthy,
        attentionStatus: .none,
        progress: RunProgress(
            kind: .determinate,
            current: 128,
            total: 400,
            fraction: 0.32,
            unit: "GB",
            source: "explicit"
        ),
        phase: "正在校验增量快照",
        safeMessage: "备份在后台安全运行。",
        startedAt: showcaseDate.addingTimeInterval(-8 * 60),
        updatedAt: showcaseDate.addingTimeInterval(-12),
        endedAt: nil,
        estimatedEndAt: nil,
        exitCode: nil,
        safeLogTail: nil,
        sequence: 14
    )

    static let showcaseSucceededRun = RunSnapshot(
        id: UUID(uuidString: "018f0d8a-8c0a-7000-8000-000000000201")!,
        machineID: "showcase_mac_studio",
        machineName: "工作室 Mac Studio",
        title: "模型评估报告",
        source: "cli",
        executionStatus: .succeeded,
        healthStatus: .healthy,
        attentionStatus: .none,
        progress: RunProgress(
            kind: .determinate,
            current: 2_400,
            total: 2_400,
            fraction: 1,
            unit: "samples",
            source: "explicit"
        ),
        phase: "评估完成",
        safeMessage: "全部 2,400 个样本已完成评估。",
        startedAt: showcaseDate.addingTimeInterval(-38 * 60),
        updatedAt: showcaseDate.addingTimeInterval(-25 * 60),
        endedAt: showcaseDate.addingTimeInterval(-25 * 60),
        estimatedEndAt: nil,
        exitCode: 0,
        safeLogTail: nil,
        sequence: 52
    )

    static let showcaseDeployRun = RunSnapshot(
        id: UUID(uuidString: "018f0d8a-8c0a-7000-8000-000000000202")!,
        machineID: "showcase_macbook",
        machineName: "出差 MacBook Pro",
        title: "文档站点部署",
        source: "webhook",
        executionStatus: .succeeded,
        healthStatus: .healthy,
        attentionStatus: .none,
        progress: RunProgress(
            kind: .determinate,
            current: 100,
            total: 100,
            fraction: 1,
            unit: "%",
            source: "explicit"
        ),
        phase: "部署完成",
        safeMessage: "文档站点已更新。",
        startedAt: showcaseDate.addingTimeInterval(-2 * 60 * 60),
        updatedAt: showcaseDate.addingTimeInterval(-105 * 60),
        endedAt: showcaseDate.addingTimeInterval(-105 * 60),
        estimatedEndAt: nil,
        exitCode: 0,
        safeLogTail: nil,
        sequence: 27
    )

    static let showcaseFailedRun = RunSnapshot(
        id: UUID(uuidString: "018f0d8a-8c0a-7000-8000-000000000203")!,
        machineID: "showcase_linux",
        machineName: "GPU 工作站",
        title: "夜间基准测试",
        source: "cli",
        executionStatus: .failed,
        healthStatus: .healthy,
        attentionStatus: .warning,
        progress: RunProgress(
            kind: .determinate,
            current: 18,
            total: 24,
            fraction: 0.75,
            unit: "cases",
            source: "explicit"
        ),
        phase: "GPU 压力测试",
        safeMessage: "第 19 个测试用例未通过，其余结果已保存。",
        startedAt: showcaseDate.addingTimeInterval(-4 * 60 * 60),
        updatedAt: showcaseDate.addingTimeInterval(-3 * 60 * 60 - 42 * 60),
        endedAt: showcaseDate.addingTimeInterval(-3 * 60 * 60 - 42 * 60),
        estimatedEndAt: nil,
        exitCode: 1,
        safeLogTail: ["benchmark case 19 failed", "results saved safely"],
        sequence: 39
    )

    static let showcaseMachines: [MachineSnapshot] = [
        MachineSnapshot(
            id: "showcase_mac_studio",
            displayName: "工作室 Mac Studio",
            platform: "macOS",
            architecture: "arm64",
            cliVersion: "1.4.0",
            lastSeenAt: showcaseDate.addingTimeInterval(-4),
            pairedAt: showcaseDate.addingTimeInterval(-31 * 86_400),
            subscriptionID: "showcase_subscription_1",
            isSubscribed: true
        ),
        MachineSnapshot(
            id: "showcase_macbook",
            displayName: "出差 MacBook Pro",
            platform: "macOS",
            architecture: "arm64",
            cliVersion: "1.4.0",
            lastSeenAt: showcaseDate.addingTimeInterval(-9),
            pairedAt: showcaseDate.addingTimeInterval(-12 * 86_400),
            subscriptionID: "showcase_subscription_2",
            isSubscribed: true
        ),
        MachineSnapshot(
            id: "showcase_linux",
            displayName: "GPU 工作站",
            platform: "Linux",
            architecture: "x86_64",
            cliVersion: "1.4.0",
            lastSeenAt: showcaseDate.addingTimeInterval(-12),
            pairedAt: showcaseDate.addingTimeInterval(-64 * 86_400),
            subscriptionID: "showcase_subscription_3",
            isSubscribed: true
        )
    ]

    static let showcaseMessages: [RichMessage] = [
        RichMessage(
            id: "showcase_message_1",
            machineID: "showcase_mac_studio",
            title: "模型检查点已保存",
            subtitle: "大模型微调",
            body: "第 7 轮检查点已安全保存，可随时继续训练。",
            level: "success",
            fields: [.init(name: "验证损失", value: "0.218")],
            createdAt: showcaseDate.addingTimeInterval(-18 * 60),
            expiresAt: nil
        ),
        RichMessage(
            id: "showcase_message_2",
            machineID: "showcase_linux",
            title: "基准测试需要关注",
            subtitle: "GPU 压力测试",
            body: "第 19 个测试用例未通过，其余结果已保存。",
            level: "warning",
            fields: [.init(name: "已完成", value: "18 / 24")],
            createdAt: showcaseDate.addingTimeInterval(-3 * 60 * 60 - 42 * 60),
            expiresAt: nil
        )
    ]

    static let showcaseEvents: [RunFeedEvent] = [
        RunFeedEvent(
            id: UUID(uuidString: "018f0d8a-8c0a-7000-8000-000000000301")!,
            sequence: 1,
            type: "run.started",
            occurredAt: showcasePrimaryRun.startedAt,
            phase: nil,
            message: "训练任务已启动",
            progress: nil
        ),
        RunFeedEvent(
            id: UUID(uuidString: "018f0d8a-8c0a-7000-8000-000000000302")!,
            sequence: 20,
            type: "run.phase_changed",
            occurredAt: showcaseDate.addingTimeInterval(-39 * 60),
            phase: "数据准备完成",
            message: nil,
            progress: nil
        ),
        RunFeedEvent(
            id: UUID(uuidString: "018f0d8a-8c0a-7000-8000-000000000303")!,
            sequence: 61,
            type: "run.message",
            occurredAt: showcaseDate.addingTimeInterval(-18 * 60),
            phase: "训练第 7 / 10 个 Epoch",
            message: "验证集损失降至 0.218",
            progress: nil
        ),
        RunFeedEvent(
            id: UUID(uuidString: "018f0d8a-8c0a-7000-8000-000000000304")!,
            sequence: 86,
            type: "run.progress",
            occurredAt: showcasePrimaryRun.updatedAt,
            phase: showcasePrimaryRun.phase,
            message: "训练稳定运行中",
            progress: showcasePrimaryRun.progress
        )
    ]

    static let showcaseSnapshot = CachedSnapshot(
        runs: [
            showcasePrimaryRun,
            showcaseBuildRun,
            showcaseBackupRun,
            showcaseSucceededRun,
            showcaseDeployRun,
            showcaseFailedRun
        ],
        machines: showcaseMachines,
        messages: showcaseMessages,
        savedAt: showcaseDate
    )

    static let showcaseEnglishPrimaryRun = englishShowcaseRun(
        showcasePrimaryRun,
        machineName: "Studio Mac Studio",
        title: "LLM Fine-Tuning · Epoch 8",
        phase: "Training epoch 8 of 10",
        safeMessage: "Validation loss is trending down. About 7 minutes remaining."
    )

    static let showcaseEnglishBuildRun = englishShowcaseRun(
        showcaseBuildRun,
        machineName: "Travel MacBook Pro",
        title: "iOS Release Build",
        phase: "Compiling RunBuoyApp",
        safeMessage: "The archive build is progressing on schedule."
    )

    static let showcaseEnglishBackupRun = englishShowcaseRun(
        showcaseBackupRun,
        machineName: "GPU Workstation",
        title: "Incremental Dataset Backup",
        phase: "Verifying incremental snapshot",
        safeMessage: "The backup is running safely in the background."
    )

    static let showcaseEnglishSucceededRun = englishShowcaseRun(
        showcaseSucceededRun,
        machineName: "Studio Mac Studio",
        title: "Model Evaluation Report",
        phase: "Evaluation complete",
        safeMessage: "All 2,400 samples were evaluated successfully."
    )

    static let showcaseEnglishDeployRun = englishShowcaseRun(
        showcaseDeployRun,
        machineName: "Travel MacBook Pro",
        title: "Documentation Site Deployment",
        phase: "Deployment complete",
        safeMessage: "The documentation site is up to date."
    )

    static let showcaseEnglishFailedRun = englishShowcaseRun(
        showcaseFailedRun,
        machineName: "GPU Workstation",
        title: "Nightly Benchmark Suite",
        phase: "GPU stress test",
        safeMessage: "Test case 19 failed. The remaining results were saved."
    )

    static let showcaseEnglishMachines: [MachineSnapshot] = [
        englishShowcaseMachine(showcaseMachines[0], displayName: "Studio Mac Studio"),
        englishShowcaseMachine(showcaseMachines[1], displayName: "Travel MacBook Pro"),
        englishShowcaseMachine(showcaseMachines[2], displayName: "GPU Workstation")
    ]

    static let showcaseEnglishMessages: [RichMessage] = [
        RichMessage(
            id: "showcase_message_1",
            machineID: "showcase_mac_studio",
            title: "Model checkpoint saved",
            subtitle: "LLM fine-tuning",
            body: "The epoch 7 checkpoint was saved safely and is ready to resume.",
            level: "success",
            fields: [.init(name: "Validation loss", value: "0.218")],
            createdAt: showcaseDate.addingTimeInterval(-18 * 60),
            expiresAt: nil
        ),
        RichMessage(
            id: "showcase_message_2",
            machineID: "showcase_linux",
            title: "Benchmark needs attention",
            subtitle: "GPU stress test",
            body: "Test case 19 failed. The remaining results were saved.",
            level: "warning",
            fields: [.init(name: "Completed", value: "18 / 24")],
            createdAt: showcaseDate.addingTimeInterval(-3 * 60 * 60 - 42 * 60),
            expiresAt: nil
        )
    ]

    static let showcaseEnglishEvents: [RunFeedEvent] = [
        RunFeedEvent(
            id: UUID(uuidString: "018f0d8a-8c0a-7000-8000-000000000301")!,
            sequence: 1,
            type: "run.started",
            occurredAt: showcaseEnglishPrimaryRun.startedAt,
            phase: nil,
            message: "Training run started",
            progress: nil
        ),
        RunFeedEvent(
            id: UUID(uuidString: "018f0d8a-8c0a-7000-8000-000000000302")!,
            sequence: 20,
            type: "run.phase_changed",
            occurredAt: showcaseDate.addingTimeInterval(-39 * 60),
            phase: "Data preparation complete",
            message: nil,
            progress: nil
        ),
        RunFeedEvent(
            id: UUID(uuidString: "018f0d8a-8c0a-7000-8000-000000000303")!,
            sequence: 61,
            type: "run.message",
            occurredAt: showcaseDate.addingTimeInterval(-18 * 60),
            phase: "Training epoch 7 of 10",
            message: "Validation loss reached 0.218",
            progress: nil
        ),
        RunFeedEvent(
            id: UUID(uuidString: "018f0d8a-8c0a-7000-8000-000000000304")!,
            sequence: 86,
            type: "run.progress",
            occurredAt: showcaseEnglishPrimaryRun.updatedAt,
            phase: showcaseEnglishPrimaryRun.phase,
            message: "Training is running smoothly",
            progress: showcaseEnglishPrimaryRun.progress
        )
    ]

    static let showcaseEnglishSnapshot = CachedSnapshot(
        runs: [
            showcaseEnglishPrimaryRun,
            showcaseEnglishBuildRun,
            showcaseEnglishBackupRun,
            showcaseEnglishSucceededRun,
            showcaseEnglishDeployRun,
            showcaseEnglishFailedRun
        ],
        machines: showcaseEnglishMachines,
        messages: showcaseEnglishMessages,
        savedAt: showcaseDate
    )

    private static func englishShowcaseRun(
        _ run: RunSnapshot,
        machineName: String,
        title: String,
        phase: String,
        safeMessage: String
    ) -> RunSnapshot {
        RunSnapshot(
            id: run.id,
            machineID: run.machineID,
            machineName: machineName,
            title: title,
            source: run.source,
            executionStatus: run.executionStatus,
            healthStatus: run.healthStatus,
            attentionStatus: run.attentionStatus,
            progress: run.progress,
            phase: phase,
            safeMessage: safeMessage,
            createdAt: run.createdAt,
            startedAt: run.startedAt,
            updatedAt: run.updatedAt,
            endedAt: run.endedAt,
            estimatedEndAt: run.estimatedEndAt,
            exitCode: run.exitCode,
            safeLogTail: run.safeLogTail,
            sequence: run.sequence
        )
    }

    private static func englishShowcaseMachine(
        _ machine: MachineSnapshot,
        displayName: String
    ) -> MachineSnapshot {
        MachineSnapshot(
            id: machine.id,
            displayName: displayName,
            platform: machine.platform,
            architecture: machine.architecture,
            cliVersion: machine.cliVersion,
            lastSeenAt: machine.lastSeenAt,
            pairedAt: machine.pairedAt,
            subscriptionID: machine.subscriptionID,
            isSubscribed: machine.isSubscribed
        )
    }

    static let longEnglishDetail = RunDetail(
        run: RunSnapshot(
            id: activeRun.id,
            machineID: activeRun.machineID,
            machineName: "Mac Studio in the machine-learning laboratory",
            title: "Long-running constrained optimization experiment with a deliberately descriptive safe title",
            executionStatus: .running,
            healthStatus: .stale,
            attentionStatus: .information,
            progress: activeRun.progress,
            phase: "Evaluating the final group of candidate solutions without exposing source data",
            safeMessage: "The experiment is healthy. This deliberately long message verifies wrapping without revealing command arguments, directories, environment values, or full output.",
            startedAt: activeRun.startedAt,
            updatedAt: activeRun.updatedAt,
            endedAt: nil,
            estimatedEndAt: activeRun.estimatedEndAt,
            exitCode: nil,
            safeLogTail: nil,
            sequence: activeRun.sequence
        ),
        feed: events
    )

    static let longChineseDetail = RunDetail(
        run: RunSnapshot(
            id: failedRun.id,
            machineID: failedRun.machineID,
            machineName: "上海实验室的 Mac Studio 工作站",
            title: "用于验证超长简体中文标题换行和辅助功能字号的优化实验",
            executionStatus: .failed,
            healthStatus: .offline,
            attentionStatus: .actionRequired,
            progress: failedRun.progress,
            phase: "安全地汇总实验结果",
            safeMessage: "任务已结束。这是一段经过脱敏的安全摘要，不包含完整命令、目录、环境变量、源代码或完整输出。",
            startedAt: failedRun.startedAt,
            updatedAt: failedRun.updatedAt,
            endedAt: failedRun.endedAt,
            estimatedEndAt: nil,
            exitCode: failedRun.exitCode,
            safeLogTail: nil,
            sequence: failedRun.sequence
        ),
        feed: events
    )

    @MainActor
    static func store(
        scenario: UITestConfiguration.Scenario = .loaded
    ) -> RunBuoyStore {
        let loadedSnapshot = CachedSnapshot(
            runs: [activeRun, failedRun],
            machines: [machine, ciMachine],
            messages: [message, ciMessage],
            savedAt: baseDate
        )
        let snapshot: CachedSnapshot?
        let apiSnapshot: CachedSnapshot
        let apiEvents: [RunFeedEvent]
        let initialState: RunBuoyStore.LoadState?
        let failsRunDetail: Bool
        switch scenario {
        case .loaded:
            snapshot = loadedSnapshot
            apiSnapshot = loadedSnapshot
            apiEvents = events
            initialState = .loaded
            failsRunDetail = false
        case .showcase:
            snapshot = showcaseSnapshot
            apiSnapshot = showcaseSnapshot
            apiEvents = showcaseEvents
            initialState = .loaded
            failsRunDetail = false
        case .showcaseEnglish:
            snapshot = showcaseEnglishSnapshot
            apiSnapshot = showcaseEnglishSnapshot
            apiEvents = showcaseEnglishEvents
            initialState = .loaded
            failsRunDetail = false
        case .empty:
            snapshot = CachedSnapshot(
                runs: [],
                machines: [],
                messages: [],
                savedAt: baseDate
            )
            apiSnapshot = loadedSnapshot
            apiEvents = events
            initialState = .loaded
            failsRunDetail = false
        case .offline:
            snapshot = loadedSnapshot
            apiSnapshot = loadedSnapshot
            apiEvents = events
            initialState = .offline("UI test offline fixture")
            failsRunDetail = false
        case .failed:
            snapshot = nil
            apiSnapshot = loadedSnapshot
            apiEvents = events
            initialState = .failed("UI test failure fixture")
            failsRunDetail = false
        case .heroPriority:
            let prioritySnapshot = CachedSnapshot(
                runs: [heroNewestHealthyRun, heroWarningRun, heroActionRequiredRun],
                machines: [machine, ciMachine],
                messages: [],
                savedAt: baseDate
            )
            snapshot = prioritySnapshot
            apiSnapshot = prioritySnapshot
            apiEvents = []
            initialState = .loaded
            failsRunDetail = false
        case .detailUnavailable:
            snapshot = nil
            apiSnapshot = loadedSnapshot
            apiEvents = []
            initialState = .failed("UI test detail unavailable fixture")
            failsRunDetail = true
        }

        return RunBuoyStore(
            api: PreviewAPI(
                snapshot: apiSnapshot,
                events: apiEvents,
                failsRunDetail: failsRunDetail
            ),
            identityStore: PreviewIdentityStore(),
            cache: LocalCacheStore(
                fileURL: FileManager.default.temporaryDirectory
                    .appendingPathComponent("runbuoy-preview-cache.json")
            ),
            initialSnapshot: snapshot,
            initialState: initialState
        )
    }
}

private struct PreviewIdentityStore: DeviceIdentityStoring {
    func load() throws -> DeviceIdentity? {
        DeviceIdentity(deviceID: "preview-device", workspaceID: "preview-workspace", credential: "preview")
    }
    func save(_ identity: DeviceIdentity) throws {}
    func remove() throws {}
}

private struct PreviewAPI: RunBuoyAPI {
    let snapshot: CachedSnapshot
    let events: [RunFeedEvent]
    let failsRunDetail: Bool

    func bootstrap(installationID: String, appVersion: String, osVersion: String) async throws -> DeviceIdentity {
        DeviceIdentity(deviceID: "preview-device", workspaceID: "preview-workspace", credential: "preview")
    }
    func listRuns() async throws -> [RunSnapshot] { snapshot.runs }
    func runDetail(id: UUID) async throws -> RunDetail {
        if failsRunDetail {
            throw URLError(.notConnectedToInternet)
        }
        return RunDetail(
            run: snapshot.runs.first(where: { $0.id == id }) ?? snapshot.runs[0],
            feed: events
        )
    }
    func listMachines() async throws -> [MachineSnapshot] { snapshot.machines }
    func listMessages() async throws -> [RichMessage] { snapshot.messages }
    func sync(cursor: Int?) async throws -> SyncResult {
        .snapshot(
            SyncSnapshot(
                nextCursor: snapshot.syncCursor ?? 1,
                serverTime: snapshot.serverTime ?? snapshot.savedAt,
                runs: snapshot.runs,
                machines: snapshot.machines,
                notifications: snapshot.messages,
                historyRunsNextCursor: snapshot.historyRunsNextCursor,
                historyRunsHasMore: snapshot.historyRunsHasMore,
                historyNotificationsNextCursor: snapshot.historyMessagesNextCursor,
                historyNotificationsHasMore: snapshot.historyMessagesHasMore
            )
        )
    }
    func historyRuns(
        cursor: String?,
        limit: Int,
        machineID: String?
    ) async throws -> HistoryPage<RunSnapshot> {
        HistoryPage(items: [], nextCursor: nil, hasMore: false)
    }
    func historyMessages(
        cursor: String?,
        limit: Int,
        machineID: String?
    ) async throws -> HistoryPage<RichMessage> {
        HistoryPage(items: [], nextCursor: nil, hasMore: false)
    }
    func claimPairing(_ code: PairingCode) async throws {}
    func registerNotificationToken(_ token: String) async throws {}
    func registerPushToStartToken(_ token: String, generation: Int) async throws {}
    func registerActivityToken(
        _ token: String,
        activityID: String,
        runID: String,
        generation: Int
    ) async throws {}
    func syncActivities(
        _ activities: [ActivityRegistration],
        frequentPushesEnabled: Bool
    ) async throws {}
    func updatePreferences(_ preferences: DevicePreferences) async throws {}
    func deleteSubscription(_ id: String) async throws {}
    func resetDevice() async throws {}
    func revokeMachine(_ id: String) async throws {}
    func requestWorkspaceDeletionChallenge() async throws -> WorkspaceDeletionChallenge {
        WorkspaceDeletionChallenge(challenge: "preview-challenge", expiresAt: Date.distantFuture)
    }
    func deleteWorkspace(challenge: String) async throws {}
}
