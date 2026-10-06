import type { ReactNode } from 'react';
import { Button } from '@rspress/core/theme-original';
import { Desktop, Timer, Waveform } from '@phosphor-icons/react';

export const STORE_URL = 'https://apps.apple.com/cn/app/runbuoy/id6795591930';
export const MASCOT = '/marketing/zh-Hans/homepage/mascot-transparent.png';
export const WATER = '/marketing/zh-Hans/homepage/water-background.png';

export function HomeAction({ href, secondary = false, children }: { href: string; secondary?: boolean; children: ReactNode }) {
  return <Button type="a" href={href} theme={secondary ? 'alt' : 'brand'} className={`runbuoy-zh-action${secondary ? ' runbuoy-zh-action--secondary' : ''}`}>{children}</Button>;
}

export function SectionHeading({ id, first, second, children }: { id: string; first: string; second: string; children?: ReactNode }) {
  return <header className="runbuoy-zh-section-heading">
    <h2 id={id}><span>{first}</span><span>{second}</span></h2>
    {children && <p>{children}</p>}
  </header>;
}

export function ProgressBar({ value, label }: { value: number; label: string }) {
  return <div className="runbuoy-zh-task__track" role="progressbar" aria-label={label} aria-valuenow={value} aria-valuemin={0} aria-valuemax={100}><span style={{ width: `${value}%` }} /></div>;
}

export function TaskStatus() {
  return <span className="runbuoy-zh-task-status"><Waveform size={16} aria-hidden="true" />运行中</span>;
}

export function FeaturedTask({ className = '' }: { className?: string }) {
  return <div className={`runbuoy-zh-task ${className}`}>
    <div className="runbuoy-zh-task__title"><TaskStatus /><strong>大模型微调 · 第 8 轮</strong></div>
    <p className="runbuoy-zh-task__machine"><Desktop size={20} aria-hidden="true" />工作室 Mac Studio</p>
    <div className="runbuoy-zh-task__phase"><span>训练第 8 / 10 个 Epoch</span><strong>78%</strong></div>
    <ProgressBar value={78} label="训练进度" />
    <p className="runbuoy-zh-task__count">7,800 / 10,000 steps</p>
    <div className="runbuoy-zh-task__times"><span><Timer size={18} aria-hidden="true" />已用时间 47:00</span><span><Waveform size={18} aria-hidden="true" />最后确认 5 秒前</span></div>
  </div>;
}
