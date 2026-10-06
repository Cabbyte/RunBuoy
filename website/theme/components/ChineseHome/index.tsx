import type { HomeLayoutProps } from '@rspress/core/theme-original';
import { HomeHero } from './HomeHero';
import { HomeFeature } from './HomeFeature';
import { AgentIntegration } from './AgentIntegration';
import { HomeContent } from './HomeContent';
import { HomeFooter } from './HomeFooter';
import './index.css';

export function ChineseHome(props: HomeLayoutProps) {
  return <div className="runbuoy-zh-home-surface">
    <main id="main-content" className="runbuoy-zh-home">
      {props.beforeHero}
      <HomeHero beforeHeroActions={props.beforeHeroActions} afterHeroActions={props.afterHeroActions} />
      {props.afterHero}{props.beforeFeatures}
      <HomeFeature />
      {props.afterFeatures}
      <AgentIntegration />
      <HomeContent />
    </main>
    <HomeFooter />
  </div>;
}
