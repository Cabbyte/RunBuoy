import { useEffect, useRef, useState } from 'react';
import { Check, Copy, CaretDown } from '@phosphor-icons/react';
import { copyToClipboard } from '@rspress/core/theme-original';

interface CopyPromptProps {
  id: string;
  title: string;
  description: string;
  prompt: string;
  label: string;
  disclosure: string;
  secondary?: boolean;
}

export function CopyPrompt({ id, title, description, prompt, label, disclosure, secondary = false }: CopyPromptProps) {
  const [copied, setCopied] = useState(false);
  const [failed, setFailed] = useState(false);
  const [open, setOpen] = useState(false);
  const copying = useRef(false);
  const mounted = useRef(true);
  const timer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  useEffect(() => {
    mounted.current = true;
    return () => { mounted.current = false; clearTimeout(timer.current); };
  }, []);
  async function copy() {
    if (copying.current) return;
    copying.current = true;
    clearTimeout(timer.current);
    let success = false;
    try { success = await copyToClipboard(prompt); } catch { success = false; }
    finally { copying.current = false; }
    if (!mounted.current) return;
    setCopied(success);
    setFailed(!success);
    if (success) timer.current = setTimeout(() => setCopied(false), 2500);
    else setOpen(true);
  }
  return <div id={id} className={secondary ? 'runbuoy-zh-pair-prompt' : 'runbuoy-zh-install-prompt'}>
    <div className="runbuoy-zh-agent-prompt__action">
      <div><h3>{title}</h3><p>{description}</p></div>
      <button type="button" className={'runbuoy-zh-action runbuoy-zh-copy-prompt' + (secondary ? ' runbuoy-zh-action--secondary' : '')} onClick={copy}>
        {copied ? <Check size={21} aria-hidden="true" /> : <Copy size={21} aria-hidden="true" />}{copied ? '已复制' : label}
      </button>
    </div>
    <p className={failed ? 'runbuoy-zh-copy-error' : 'runbuoy-zh-sr-only'} role="status" aria-live="polite">{failed ? '复制未成功，请在下方选择提示词并手动复制。' : copied ? label.replace('复制', '') + '已复制' : ''}</p>
    <details className="runbuoy-zh-disclosure" open={open} onToggle={event => setOpen(event.currentTarget.open)}>
      <summary>{disclosure}<CaretDown size={19} aria-hidden="true" /></summary>
      <pre tabIndex={0} className="runbuoy-zh-prompt-text">{prompt}</pre>
    </details>
  </div>;
}
