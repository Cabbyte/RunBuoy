import { Link } from '@rspress/core/theme-original';
import { BellRinging, Desktop, ArrowRight, LockSimple, Waveform } from '@phosphor-icons/react';
import { ProgressBar, SectionHeading, TaskStatus } from '../shared';
import './index.css';

const tasks = [
  { title: 'iOS Release 构建', machine: '出差 MacBook Pro', phase: '正在编译 RunBuoyApp', progress: 46 },
  { title: '实验数据增量备份', machine: 'GPU 工作站', phase: '正在校验增量快照', progress: 32 },
];

export function HomeFeature() {
  return <section className="runbuoy-zh-section runbuoy-zh-progress" aria-labelledby="runbuoy-zh-progress-heading">
    <SectionHeading id="runbuoy-zh-progress-heading" first="任务分头跑，" second="进展一处看。">几台电脑，各自工作。阶段、结果，一处掌握。</SectionHeading>
    <div className="runbuoy-zh-progress__grid">
      <div className="runbuoy-zh-overview">
        <div className="runbuoy-zh-panel-heading"><Desktop size={23} aria-hidden="true" /><h3>多台电脑，随手掌握</h3></div>
        <div className="runbuoy-zh-run-list">{tasks.map(task => <div className="runbuoy-zh-run" key={task.title}>
          <div className="runbuoy-zh-run__heading"><strong>{task.title}</strong><TaskStatus /></div>
          <p className="runbuoy-zh-task__machine"><Desktop size={18} aria-hidden="true" />{task.machine}</p>
          <div className="runbuoy-zh-run__phase"><span>{task.phase}</span><strong>{task.progress}%</strong></div>
          <ProgressBar value={task.progress} label={`${task.title}进度`} />
        </div>)}</div>
        <Link className="runbuoy-zh-text-link" href="/guide/progress">了解任务与进度 <ArrowRight aria-hidden="true" /></Link>
      </div>
      <div className="runbuoy-zh-progress__updates">
        <div className="runbuoy-zh-message-panel">
          <div className="runbuoy-zh-panel-heading"><BellRinging size={23} aria-hidden="true" /><h3>重要消息，随身收到</h3></div>
          <div className="runbuoy-zh-task-message"><strong>发布包校验完成</strong><p>校验已通过，可以开始下一步。</p></div>
          <p>任务有结果、需关注，收到它发来的消息。</p>
        </div>
        <div className="runbuoy-zh-lock-panel">
          <div className="runbuoy-zh-panel-heading"><LockSimple size={23} aria-hidden="true" /><h3>锁屏看进展，抬手知状态</h3></div>
          <div className="runbuoy-zh-live-compact"><div><Waveform size={19} aria-hidden="true" /><strong>大模型微调</strong><span>72%</span></div><ProgressBar value={72} label="锁屏实时活动进度" /><p>工作室 Mac Studio</p></div>
          <img className="runbuoy-zh-live-image" src="/marketing/zh-Hans/live-activity.png" width="1200" height="290" loading="lazy" alt="RunBuoy 锁屏实时活动：大模型微调，进度 72%" />
        </div>
      </div>
    </div>
  </section>;
}
