import { CopyPrompt } from './CopyPrompt';
import { AGENT_PROMPTS, PAIRING_PROMPT_ZH } from './installPrompts';

export function InstallPrompt() {
  return <CopyPrompt id="install-prompt" title="让 Agent 完成安装" description="支持 Codex 等具备 Skill 能力的 Agent。" prompt={AGENT_PROMPTS.zh} label="复制安装提示词" disclosure="查看完整提示词" />;
}
export function PairingPrompt() {
  return <CopyPrompt id="pair-after-install" title="安装完成后，连接 iPhone" description="把配对提示词交给同一个 Agent，在 iPhone 扫码确认。" prompt={PAIRING_PROMPT_ZH} label="复制配对提示词" disclosure="查看配对提示词" secondary />;
}
