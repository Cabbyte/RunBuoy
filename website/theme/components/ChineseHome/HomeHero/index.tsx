import type { ReactNode } from 'react';
import { AppStoreLogo, ArrowRight } from '@phosphor-icons/react';
import { useFrontmatter } from '@rspress/core/runtime';
import { HomeAction, FeaturedTask, PhonePreview, MASCOT, WATER } from '../shared';
import './index.css';

interface HomeHeroProps {
  beforeHeroActions?: ReactNode;
  afterHeroActions?: ReactNode;
}

export function HomeHero({ beforeHeroActions, afterHeroActions }: HomeHeroProps) {
  const { frontmatter } = useFrontmatter();
  const hero = frontmatter.hero;
  return <section className="runbuoy-zh-home-hero" aria-labelledby="runbuoy-zh-hero-title">
    <div className="runbuoy-zh-home-hero__copy">
      <h1 id="runbuoy-zh-hero-title">{hero?.text?.toString().split('\n').filter(Boolean).map(line => <span key={line}>{line}</span>)}</h1>
      <div className="runbuoy-zh-home-hero__tagline"><p><span>安装交给 Agent，</span><span>状态带到 iPhone。</span></p><p><span>阶段、结果随手看，</span><span>重要消息随身收。</span></p></div>
      {beforeHeroActions}
      <div className="runbuoy-zh-home-hero__actions">{hero?.actions?.map(action => <HomeAction key={action.link} href={action.link} secondary={action.theme === 'alt'}>{action.theme === 'alt' ? <ArrowRight size={21} aria-hidden="true" /> : <AppStoreLogo size={22} aria-hidden="true" />}{action.text}</HomeAction>)}</div>
      {afterHeroActions}
    </div>
    <div className="runbuoy-zh-home-hero__artwork">
      <img className="runbuoy-zh-hero-water" src={WATER} width="1891" height="831" alt="" />
      <div className="runbuoy-zh-hero-scene"><PhonePreview className="runbuoy-zh-phone" src="/marketing/zh-Hans/active-runs.jpg" alt="RunBuoy 运行中：训练、构建与备份任务集中查看" eager />
      <img className="runbuoy-zh-hero-mascot" src={MASCOT} width="1254" height="1254" alt="微笑的 RunBuoy 浮标吉祥物" />
      <FeaturedTask className="runbuoy-zh-hero-task" /></div>
    </div>
  </section>;
}
