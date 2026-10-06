import { Link } from '@rspress/core/theme-original';
import { HomeAction, SectionHeading } from './shared';

export function AgentIntegration() {
  return <section className="runbuoy-zh-agents" id="agent-integration" aria-labelledby="agent-integration-heading">
    <div className="runbuoy-zh-section">
      <SectionHeading id="agent-integration-heading" first="Agent 报状态，" second="ChatGPT 看全貌。">问一句，查进展；点一下，看全貌。</SectionHeading>
      <div className="runbuoy-zh-agents__types">
        <div><h3>RunBuoy Skill</h3><p>任务报阶段，结果带消息。</p></div>
        <div><h3>ChatGPT Plugin · 私人预览</h3><p>选中任务，接着聊。</p></div>
      </div>
      <figure className="runbuoy-zh-agents__workspace"><img src="/marketing/zh-Hans/chatgpt-workspace.jpg" width="1280" height="1337" loading="lazy" alt="ChatGPT 中的 RunBuoy 交互看板：选择任务，查看进度与消息" /></figure>
      <div className="runbuoy-zh-agents__focus">
        <h3>运行中 · 模型训练</h3><p>Studio GPU</p>
        <div className="runbuoy-zh-agents__phase"><span>Epoch 34 of 50</span><span>68%</span></div>
        <div className="runbuoy-zh-agents__track" role="progressbar" aria-label="模型训练进度" aria-valuenow={68} aria-valuemin={0} aria-valuemax={100}><span /></div>
        <p>验证损失降至 0.042，正在保存检查点。</p>
      </div>
      <div className="runbuoy-zh-agents__conversation"><h3>选中任务，接着聊。</h3><HomeAction href="/guide/agent-skill#chatgpt">用于对话</HomeAction></div>
      <p className="runbuoy-zh-agents__readonly">只读查看，连接由 iPhone 确认。</p>
      <Link className="runbuoy-zh-text-link" href="/guide/agent-skill">了解 Agent 集成 →</Link>
    </div>
  </section>;
}
