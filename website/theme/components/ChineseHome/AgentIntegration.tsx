import { Link } from '@rspress/core/theme-original';
import { ArrowRight, ChartBar, ChatCircle, Desktop, Note, ShieldCheck } from '@phosphor-icons/react';
import { ProgressBar, SectionHeading, TaskStatus } from './shared';

export function AgentIntegration() {
  return <section className="runbuoy-zh-agents" id="agent-integration" aria-labelledby="agent-integration-heading">
    <div className="runbuoy-zh-section runbuoy-zh-agents__layout">
      <div className="runbuoy-zh-agents__copy">
        <SectionHeading id="agent-integration-heading" first="Agent 报状态，" second="ChatGPT 看全貌。">问一句，查进展；点一下，看全貌。</SectionHeading>
        <div className="runbuoy-zh-skill"><ChartBar size={28} aria-hidden="true" /><div><h3>RunBuoy Skill</h3><p>任务报阶段，结果带消息。</p></div></div>
        <p className="runbuoy-zh-agents__description">接入 Skill，让 Agent 报告任务进展；连接 ChatGPT，查看任务、接着聊。</p>
        <Link className="runbuoy-zh-text-link" href="/guide/agent-skill">了解 Agent 集成 <ArrowRight aria-hidden="true" /></Link>
      </div>
      <div className="runbuoy-zh-plugin">
        <div className="runbuoy-zh-plugin__heading"><div><ChatCircle size={24} aria-hidden="true" /><h3>ChatGPT Plugin</h3></div><span>私人预览</span></div>
        <figure className="runbuoy-zh-agents__focus" aria-label="ChatGPT 中 RunBuoy 任务详情的关键内容">
          <div className="runbuoy-zh-plugin__task"><h3>模型训练</h3><TaskStatus /></div>
          <p className="runbuoy-zh-task__machine"><Desktop size={19} aria-hidden="true" />Studio GPU</p>
          <div className="runbuoy-zh-run__phase"><span>Epoch 34 of 50</span><strong>68%</strong></div>
          <ProgressBar value={68} label="ChatGPT 中的模型训练进度" />
          <div className="runbuoy-zh-plugin__message"><Note size={23} aria-hidden="true" /><p>验证损失降至 0.042，正在保存检查点。</p></div>
          <figcaption><ShieldCheck size={18} aria-hidden="true" />只读查看，连接由 iPhone 确认。</figcaption>
        </figure>
        <div className="runbuoy-zh-plugin__links"><Link className="runbuoy-zh-text-link" href="/guide/agent-skill#chatgpt">了解 ChatGPT 接入 <ArrowRight aria-hidden="true" /></Link><a href="/marketing/zh-Hans/chatgpt-workspace.jpg" target="_blank" rel="noreferrer">查看完整界面</a></div>
      </div>
    </div>
  </section>;
}
