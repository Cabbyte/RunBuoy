import { Link } from '@rspress/core/theme-original';
import { FeaturedTask, SectionHeading } from '../shared';
import './index.css';

export function HomeFeature() {
  return <section className="runbuoy-zh-section runbuoy-zh-progress" aria-labelledby="runbuoy-zh-progress-heading">
    <SectionHeading id="runbuoy-zh-progress-heading" first="任务分头跑，" second="进展一处看。">几台电脑，各自工作。<br />阶段、结果，一处掌握。</SectionHeading>
    <div className="runbuoy-zh-progress__story">
      <div className="runbuoy-zh-progress__evidence">
        <FeaturedTask />
        <div className="runbuoy-zh-task-message"><p>任务发来的重要消息</p><h3>训练第 8 / 10 个 Epoch</h3><p>验证集损失持续下降，预计约 7 分钟后完成。</p></div>
      </div>
      <div className="runbuoy-zh-progress__benefits">
        <h3>进展随手看，<br />消息随身收。</h3>
        <dl><div><dt>看阶段，也看结果</dt><dd>训练、构建、脚本，进展随时可查。</dd></div><div><dt>有消息，及时知晓</dt><dd>任务需要关注时，接收它发来的消息。</dd></div></dl>
        <Link className="runbuoy-zh-text-link" href="/guide/progress">了解任务与进度 →</Link>
      </div>
    </div>
  </section>;
}
