import { useEffect, useRef, useState } from 'react';
import { Check, Copy, CaretDown } from '@phosphor-icons/react';
import { Link, copyToClipboard } from '@rspress/core/theme-original';
import { AGENT_PROMPTS } from '../installPrompts';
import { SectionHeading, MASCOT, STORE_URL } from '../shared';
import './index.css';

const INSTALL = `uv tool install --python 3.12 runbuoy
uv tool update-shell
export PATH="$(uv tool dir --bin):$PATH"
hash -r
command -v runbuoy
runbuoy --version`;

export function HomeContent() {
  const [copied, setCopied] = useState(false);
  const [copyFailed, setCopyFailed] = useState(false);
  const [promptOpen, setPromptOpen] = useState(false);
  const timer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const copying = useRef(false);
  useEffect(() => () => clearTimeout(timer.current), []);
  async function copyPrompt() {
    if (copying.current) return;
    copying.current = true;
    clearTimeout(timer.current);
    try {
      const success = await copyToClipboard(AGENT_PROMPTS.zh);
      setCopied(success);
      setCopyFailed(!success);
      if (success) timer.current = setTimeout(() => setCopied(false), 2500);
      else setPromptOpen(true);
    } catch {
      setCopied(false);
      setCopyFailed(true);
      setPromptOpen(true);
    } finally { copying.current = false; }
  }
  return <>
    <section id="agent-install" className="runbuoy-zh-section runbuoy-zh-install" aria-labelledby="runbuoy-zh-install-heading">
      <span id="get-started" />
      <SectionHeading id="runbuoy-zh-install-heading" first="Agent 帮你装，" second="RunBuoy 帮你看。">复制提示词，接入电脑。下次任务开始，状态随身带走。</SectionHeading>
      <ol className="runbuoy-zh-flow">
        <li><h3><Link href={STORE_URL}>1&nbsp; 下载 App</Link></h3><p>在 iPhone 安装 RunBuoy</p></li>
        <li><h3>2&nbsp; 交给 Agent</h3><p>完成安装与验证</p></li>
        <li><h3>3&nbsp; 扫码配对</h3><p>确认电脑，带走任务状态</p></li>
      </ol>
      <div className="runbuoy-zh-agent-prompt">
        <div className="runbuoy-zh-agent-prompt__action"><div><h3>让 Agent 完成安装</h3><p>支持 Codex 等具备 Skill 能力的 Agent。</p></div><button type="button" className="runbuoy-zh-action runbuoy-zh-copy-prompt" onClick={copyPrompt}>{copied ? <Check size={21} aria-hidden="true" /> : <Copy size={21} aria-hidden="true" />}{copied ? '已复制' : '复制安装提示词'}</button></div>
        <p className={copyFailed ? 'runbuoy-zh-copy-error' : 'runbuoy-zh-sr-only'} role="status" aria-live="polite">{copyFailed ? '复制未成功，请在下方选择提示词并手动复制。' : copied ? '安装提示词已复制' : ''}</p>
        <details className="runbuoy-zh-disclosure" open={promptOpen} onToggle={event => setPromptOpen(event.currentTarget.open)}>
          <summary>查看完整提示词<CaretDown size={19} aria-hidden="true" /></summary>
          <pre tabIndex={0} className="runbuoy-zh-prompt-text">{AGENT_PROMPTS.zh}</pre>
        </details>
        <details id="manual-install" className="runbuoy-zh-disclosure">
          <summary>手动安装与配对<CaretDown size={19} aria-hidden="true" /></summary>
          <div className="runbuoy-zh-manual-content">
            <h3>准备依赖</h3><p>安装 uv 与 tmux，然后安装 RunBuoy CLI。</p><Link className="runbuoy-zh-text-link" href="/guide/install">准备依赖与完整安装说明 →</Link>
            <h3>安装并验证</h3><p>以下命令适用于 Bash / Zsh。完成后，新开终端验证 runbuoy --version。</p><pre tabIndex={0}><code>{INSTALL}</code></pre>
            <h3>扫码配对</h3><pre tabIndex={0}><code>runbuoy device pair</code></pre><p>在 iPhone 扫码，确认电脑身份。</p>
            <h3>看到第一条动态</h3><pre tabIndex={0}><code>runbuoy demo live-activity</code></pre>
            <Link className="runbuoy-zh-text-link" href="/guide/pairing">完整配对与使用指南 →</Link>
          </div>
        </details>
      </div>
    </section>
    <section className="runbuoy-zh-section runbuoy-zh-privacy" aria-labelledby="runbuoy-zh-privacy-heading">
      <div><h2 id="runbuoy-zh-privacy-heading">电脑跑任务，手机看状态。</h2><p>源码与完整日志，默认留在本机。</p><Link className="runbuoy-zh-text-link" href="/privacy">了解隐私 →</Link></div>
      <img src={MASCOT} width="1254" height="1254" alt="" loading="lazy" />
    </section>
  </>;
}
