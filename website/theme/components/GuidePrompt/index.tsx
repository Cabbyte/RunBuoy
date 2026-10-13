import { InstallPrompt, PairingPrompt } from '../ChineseHome/SetupPrompts';
import './index.css';
export function GuidePrompt({ kind }: { kind: 'install' | 'pair' }) {
  return <div className="runbuoy-guide-prompt">{kind === 'install' ? <InstallPrompt /> : <PairingPrompt />}</div>;
}
