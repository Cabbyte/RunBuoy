import { useEffect, useRef, useState } from 'react';
import { useLang } from '@rspress/core/runtime';
import { Button, Link, copyToClipboard } from '@rspress/core/theme-original';
import { AppStoreLogo, ArrowRight, Check, Cloud, Copy, DeviceMobile, Laptop, MagicWand, ShieldCheck } from '@phosphor-icons/react';
import { localizeHref } from '../../../utils/localizeHref';
import { AGENT_PROMPTS } from '../installPrompts';
import './index.css';

const INSTALL = `uv tool install --python 3.12 runbuoy
uv tool update-shell
export PATH="$(uv tool dir --bin):$PATH"
hash -r
command -v runbuoy
runbuoy --version`;
const PAIR = 'runbuoy device pair';
const DEMO = 'runbuoy demo live-activity';
const copy = {
  zh: {
    storyEyebrow: '从 Agent 到脚本，从训练到构建。',
    storyTitle: '任务分头跑，\n进展一处看。',
    storyLead: '几台电脑，各自工作。任务状态、阶段与消息，在 iPhone 集中查看。',
    scenarios: [
      ['Agent 与自动化脚本', '接入 Skill 或 Python API，让任务报阶段、传结果，需关注时发消息。'],
      ['模型训练与实验', '看轮次、样本数与阶段，出门后也能掌握训练状态。'],
      ['编译、测试与构建', '知道构建还在执行，或是已经成功、失败。'],
      ['数据处理与备份', '把脚本报告的进度带到手边，减少来回查看。'],
    ],
    progressNote: '百分比与预计完成时间来自任务显式报告。普通命令也能跟踪状态和结果，不会自动推算百分比。',
    progressLink: '如何接入真实进度',
    setupEyebrow: '安装交给 Agent，状态带到手边。',
    setupTitle: '使用 Agent 安装 RunBuoy。',
    setupLead: '复制安装提示词，交给 Codex 或其他支持 Skill 的 Agent。',
    steps: [
      ['在 iPhone 下载', '从 App Store 安装 RunBuoy，打开 App 完成引导。'],
      ['在电脑安装', '先准备 uv 与 tmux。以下命令适用于 Bash / Zsh；完成后在新终端验证 runbuoy --version。'],
      ['配对你的电脑', '在终端运行配对命令，用 App 扫描二维码并确认电脑身份。'],
      ['看到第一条动态', '配对后运行演示，确认 iPhone 收到状态，再接入自己的长任务。'],
    ],
    download: 'App Store 下载', dependencies: '准备依赖与完整安装说明',
    guide: '完整配对与使用指南',
    agentTitle: '安装 Skill 与 CLI',
    agentLead: 'Agent 会安装并验证 RunBuoy Skill 与 CLI。完成后，继续配对手机与运行任务。',
    manualSummary: '手动安装与配对步骤', promptCopy: '复制安装提示词',
    promptNote: '这条提示词只安装和验证，不会自动配对、启动任务或上传日志。',
    boundaryEyebrow: '数据边界，清清楚楚', boundaryTitle: '电脑跑任务，手机看状态。',
    boundaryLead: '命令、源码、环境变量与完整日志默认留在本机。你可以显式启用经过清理的日志摘要。',
    nodes: [['Mac / Linux', '执行任务 · 保留完整日志'], ['RunBuoy Server', '转发阶段、进度与结果'], ['iPhone', '查看状态 · 接收提醒']],
    readonly: '手机端只读：不启动、停止或重试电脑任务。',
    privacy: '了解隐私与数据保留规则',
    finalTitle: 'Agent 帮你装，RunBuoy 帮你看。',
    finalLead: '复制提示词，接入你的电脑。下次任务开始，状态随身带走。',
    finalSecondary: '连接我的电脑', copied: '已复制', copy: '复制', copyFailed: '复制失败，请选择下方文字手动复制。',
    screenshotAlt: '新版任务详情预览：展示数据为 78% 进度、训练阶段和安全消息',
  },
  en: {
    storyEyebrow: 'For the work worth waiting for',
    storyTitle: 'Your computer is busy.\nYou don’t have to be.',
    storyLead: 'Bring tasks from your computers into one view. See more than “still running”: know which phase they have reached.',
    scenarios: [
      ['Model training & experiments', 'Follow epochs, sample counts, and phases while you step away.'],
      ['Compiles, tests & builds', 'Know whether a build is still running, succeeded, or failed.'],
      ['Data processing & backups', 'Keep the progress your scripts report within reach. Check back less.'],
    ],
    progressNote: 'Percentages and time estimates come from explicit task reports. Ordinary commands still report status and results; RunBuoy does not invent a percentage.',
    progressLink: 'Connect real progress',
    setupEyebrow: 'From your computer to your pocket',
    setupTitle: 'Install RunBuoy with your agent.',
    setupLead: 'Copy the installation prompt into Codex or another Skill-enabled agent.',
    steps: [
      ['Get RunBuoy on iPhone', 'Download from the App Store and follow the in-app introduction.'],
      ['Install on your computer', 'Set up uv and tmux. Use these commands in Bash / Zsh, then verify runbuoy --version in a new terminal.'],
      ['Pair your computer', 'Run the pairing command, scan the QR code in the app, and confirm the computer.'],
      ['See your first update', 'Run the demo after pairing. Once it reaches your iPhone, connect your own long-running work.'],
    ],
    download: 'Get on the App Store', dependencies: 'Dependencies and installation guide',
    guide: 'Full pairing and usage guide',
    agentTitle: 'Install the Skill and CLI',
    agentLead: 'Your agent installs and verifies the RunBuoy Skill and CLI. Then pair your phone and start a task.',
    manualSummary: 'Manual installation and pairing', promptCopy: 'Copy installation prompt',
    promptNote: 'This prompt only installs and verifies. It does not pair devices, start tasks, or upload logs.',
    boundaryEyebrow: 'Clear data boundaries', boundaryTitle: 'Take the status. Keep the work local.',
    boundaryLead: 'Commands, source code, environment variables, and full logs stay on your computer by default. Sanitized log excerpts are an explicit opt-in.',
    nodes: [['Mac / Linux', 'Runs tasks · Keeps full logs'], ['RunBuoy Server', 'Relays phases, progress & results'], ['iPhone', 'Shows status · Receives alerts']],
    readonly: 'The phone is read-only. It cannot start, stop, or retry tasks on your computer.',
    privacy: 'Privacy and data retention',
    finalTitle: 'A little less waiting around.',
    finalLead: 'Bring the next long-running task along with you.',
    finalSecondary: 'Connect my computer', copied: 'Copied', copy: 'Copy', copyFailed: 'Copy failed. Select the text below to copy it manually.',
    screenshotAlt: 'Real task detail showing 78% sample progress, the training phase and a safe message',
  },
} as const;

function HomeContent() {
  const lang = useLang();
  const zh = lang.startsWith('zh');
  const value = zh ? copy.zh : copy.en;
  const locale = zh ? 'zh-Hans' : 'en-US';
  const storeURL = `https://apps.apple.com/${zh ? 'cn' : 'us'}/app/runbuoy/id6795591930`;
  const [copied, setCopied] = useState<string | null>(null);
  const [copyFailed, setCopyFailed] = useState(false);
  const timer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  useEffect(() => () => clearTimeout(timer.current), []);
  async function copyText(id: string, text: string) {
    try {
      const success = await copyToClipboard(text);
      if (!success) {
        setCopied(null);
        setCopyFailed(true);
        return;
      }
      setCopied(id);
      setCopyFailed(false);
      clearTimeout(timer.current);
      timer.current = setTimeout(() => setCopied(null), 2500);
    } catch {
      setCopied(null);
      setCopyFailed(true);
    }
  }
  const icons = [Laptop, Cloud, DeviceMobile];
  const commands = [null, INSTALL, PAIR, DEMO];
  return (
    <div className="runbuoy-zh-home-content">
      <section className="runbuoy-zh-story" aria-labelledby="runbuoy-zh-story-heading">
        <div className="runbuoy-zh-story__visual">
          <img src={`/marketing/${locale}/run-detail.jpg`} width="660" height="1120" alt={value.screenshotAlt} loading="lazy" />
        </div>
        <div className="runbuoy-zh-story__copy">
          <header className="runbuoy-zh-section-header">
            <p className="runbuoy-zh-section-eyebrow">{value.storyEyebrow}</p>
            <h2 id="runbuoy-zh-story-heading">{value.storyTitle.split('\n').map(line => <span key={line}>{line}</span>)}</h2>
            <p>{value.storyLead}</p>
          </header>
          <dl className="runbuoy-zh-scenarios">
            {value.scenarios.map(([title, detail], index) => <div key={title}><span aria-hidden="true">0{index + 1}</span><div><dt>{title}</dt><dd>{detail}</dd></div></div>)}
          </dl>
          <p className="runbuoy-zh-progress-note">{value.progressNote} <Link href={localizeHref('/guide/progress', lang)}>{value.progressLink} <ArrowRight size={14} aria-hidden="true" /></Link></p>
        </div>
      </section>

      <section id="get-started" className="runbuoy-zh-start" aria-labelledby="runbuoy-zh-start-heading">
        <header className="runbuoy-zh-section-header">
          <p className="runbuoy-zh-section-eyebrow">{value.setupEyebrow}</p>
          <h2 id="runbuoy-zh-start-heading">{value.setupTitle.split('\n').map(line => <span key={line}>{line}</span>)}</h2>
          <p>{value.setupLead}</p>
        </header>
        <aside id="agent-install" className="runbuoy-zh-agent-install">
          <div className="runbuoy-zh-agent-install__heading"><MagicWand size={25} aria-hidden="true" /><div><h3>{value.agentTitle}</h3><p>{value.agentLead}</p></div></div>
          <div className="runbuoy-zh-agent-prompt">
            <button type="button" className="runbuoy-zh-copy-prompt" onClick={() => copyText('agent', AGENT_PROMPTS[zh ? 'zh' : 'en'])}>{copied === 'agent' ? <Check size={18} aria-hidden="true" /> : <Copy size={18} aria-hidden="true" />}{copied === 'agent' ? value.copied : value.promptCopy}</button>
            <pre tabIndex={0}>{AGENT_PROMPTS[zh ? 'zh' : 'en']}</pre>
            <p>{value.promptNote} <Link href={localizeHref('/guide/#agent-install', lang)}>{zh ? '使用指南' : 'Read the guide'}</Link></p>
          </div>
        </aside>
        <p className="runbuoy-zh-copy-status" role="status" aria-live="polite">{copyFailed ? value.copyFailed : copied ? value.copied : ''}</p>
        <p className="runbuoy-zh-setup-link"><Link href={localizeHref('/guide/pairing', lang)}>{value.guide}<ArrowRight size={17} aria-hidden="true" /></Link></p>
        <details id="manual-install" className="runbuoy-zh-manual-install">
          <summary>{value.manualSummary}</summary>
          <ol className="runbuoy-zh-flow">
          {value.steps.map(([title, detail], index) => <li key={title}>
            <span className="runbuoy-zh-step-number" aria-hidden="true">{index + 1}</span>
            <div>
              <h3>{title}</h3><p>{detail}</p>
              {index === 0 ? <Link className="runbuoy-zh-inline-link" href={storeURL}><AppStoreLogo size={18} aria-hidden="true" />{value.download}<ArrowRight size={16} aria-hidden="true" /></Link> : <div className="runbuoy-zh-command"><code>{commands[index]}</code><button type="button" aria-label={`${value.copy}: ${commands[index]}`} onClick={() => copyText(`step-${index}`, commands[index]!)}>{copied === `step-${index}` ? <Check size={18} /> : <Copy size={18} />}</button></div>}
              {index === 1 && <Link className="runbuoy-zh-small-link" href={localizeHref('/guide/install', lang)}>{value.dependencies}</Link>}
            </div>
          </li>)}
          </ol>
        </details>
      </section>

      <section className="runbuoy-zh-boundary" aria-labelledby="runbuoy-zh-boundary-heading">
        <header className="runbuoy-zh-section-header">
          <p className="runbuoy-zh-section-eyebrow"><ShieldCheck size={18} aria-hidden="true" />{value.boundaryEyebrow}</p>
          <h2 id="runbuoy-zh-boundary-heading">{value.boundaryTitle}</h2>
          <p>{value.boundaryLead}</p>
        </header>
        <ol className="runbuoy-zh-boundary__flow">
          {value.nodes.map(([title, detail], index) => { const Icon = icons[index]; return <li key={title}><Icon size={30} weight="duotone" aria-hidden="true" /><strong>{title}</strong><p>{detail}</p>{index < 2 && <ArrowRight className="runbuoy-zh-flow-arrow" size={22} aria-hidden="true" />}</li>; })}
        </ol>
        <p className="runbuoy-zh-readonly">{value.readonly}</p>
        <Link className="runbuoy-zh-inline-link" href={localizeHref('/privacy', lang)}>{value.privacy}<ArrowRight size={16} aria-hidden="true" /></Link>
      </section>

      <section className="runbuoy-zh-final-cta" aria-labelledby="runbuoy-zh-final-heading">
        <img src="/marketing/buoy-calm-water.jpg" width="1536" height="1024" alt="" loading="lazy" />
        <div><h2 id="runbuoy-zh-final-heading">{value.finalTitle}</h2><p>{value.finalLead}</p><div className="runbuoy-zh-home-hero__actions"><Button type="a" theme="brand" href={storeURL} className="runbuoy-zh-home-hero__action"><AppStoreLogo size={21} aria-hidden="true" />{value.download}</Button><Link href="#get-started" className="runbuoy-zh-inline-link">{value.finalSecondary}<ArrowRight size={18} aria-hidden="true" /></Link></div></div>
      </section>
    </div>
  );
}
export { HomeContent };
