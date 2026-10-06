import type { ReactNode } from 'react';
import { Button } from '@rspress/core/theme-original';

export const STORE_URL = 'https://apps.apple.com/cn/app/runbuoy/id6795591930';
export const MASCOT = '/marketing/zh-Hans/homepage/mascot-transparent.png';
export const WATER = '/marketing/zh-Hans/homepage/water-background.png';

export function HomeAction({ href, secondary = false, children }: { href: string; secondary?: boolean; children: ReactNode }) {
  return <Button type="a" href={href} theme={secondary ? 'alt' : 'brand'} className={`runbuoy-zh-action${secondary ? ' runbuoy-zh-action--secondary' : ''}`}>{children}</Button>;
}

export function SectionHeading({ id, first, second, children }: { id: string; first: string; second: string; children: ReactNode }) {
  return <header className="runbuoy-zh-section-heading">
    <h2 id={id}><span>{first}</span><span>{second}</span></h2>
    <p>{children}</p>
  </header>;
}

export function FeaturedTask({ className = '' }: { className?: string }) {
  return <div className={`runbuoy-zh-task ${className}`}>
    <div className="runbuoy-zh-task__title"><span>运行中</span><strong>大模型微调 · 第 8 轮</strong></div>
    <p className="runbuoy-zh-task__machine">工作室 Mac Studio</p>
    <div className="runbuoy-zh-task__phase"><span>训练第 8 / 10 个 Epoch</span><strong>78%</strong></div>
    <div className="runbuoy-zh-task__track" role="progressbar" aria-label="训练进度" aria-valuenow={78} aria-valuemin={0} aria-valuemax={100}><span /></div>
    <p className="runbuoy-zh-task__count">7,800 / 10,000 steps</p>
    <div className="runbuoy-zh-task__times"><span>已用时间 47:00</span><span>最后确认 5 秒前</span></div>
  </div>;
}
