import { useFrontmatter, useLang } from '@rspress/core/runtime';
import { Button, renderHtmlOrText } from '@rspress/core/theme-original';
import { AppStoreLogo, ArrowRight } from '@phosphor-icons/react';
import { localizeHref } from '../../../utils/localizeHref';
import './index.css';

interface HomeHeroProps {
  beforeHeroActions?: React.ReactNode;
  afterHeroActions?: React.ReactNode;
  image?: React.ReactNode;
}

function isAppStoreLink(href: string): boolean {
  try {
    const url = new URL(href, 'https://www.runbuoy.cloud');
    return url.protocol === 'https:' && url.hostname === 'apps.apple.com';
  } catch {
    return false;
  }
}

function HomeHero({ beforeHeroActions, afterHeroActions, image }: HomeHeroProps) {
  const { frontmatter } = useFrontmatter();
  const lang = useLang();
  const zh = lang.startsWith('zh');
  const hero = frontmatter.hero;
  const locale = zh ? 'zh-Hans' : 'en-US';
  return (
    <section className="runbuoy-zh-home-hero" aria-labelledby="runbuoy-zh-hero-title">
      <div className="runbuoy-zh-home-hero__copy">
        <p className="runbuoy-zh-section-eyebrow">MAC / LINUX <span aria-hidden="true">→</span> IPHONE</p>
        <h1 id="runbuoy-zh-hero-title" className="runbuoy-zh-home-hero__subtitle">
          {hero?.text?.toString().split('\n').filter(Boolean).map(line => <span key={line}>{line}</span>)}
        </h1>
        <p className="runbuoy-zh-home-hero__tagline" {...renderHtmlOrText(hero?.tagline ?? '')} />
        {beforeHeroActions}
        <div className="runbuoy-zh-home-hero__actions">
          {hero?.actions?.map(action => (
            <Button type="a" key={action.link} href={localizeHref(action.link, lang)} theme={action.theme} className="runbuoy-zh-home-hero__action">
              {isAppStoreLink(action.link) ? <AppStoreLogo size={21} weight="bold" aria-hidden="true" /> : <ArrowRight size={20} aria-hidden="true" />}
              <span {...renderHtmlOrText(action.text)} />
            </Button>
          ))}
        </div>
        <p className="runbuoy-zh-home-hero__requirements">{zh ? 'iOS 18 及以上 · Mac / Linux · 界面为新版预览，任务为示例数据' : 'Free · iOS 18+ · CLI setup on Mac or Linux required'}</p>
        {afterHeroActions}
      </div>
      <div className="runbuoy-zh-home-hero__visual">
        {image ?? <>
          <div className="runbuoy-zh-hero-orbit" aria-hidden="true" />
          <div className="runbuoy-zh-phone">
            <img src={`/marketing/${locale}/active-runs.jpg`} width="660" height="1434" fetchPriority="high" alt={zh ? 'RunBuoy 运行中：Mac Studio 上的训练、MacBook 上的构建、Linux 上的备份' : 'RunBuoy active runs: training on Mac Studio, a MacBook build and a Linux backup'} />
          </div>
          <figure className="runbuoy-zh-hero-activity">
            <figcaption>{zh ? '锁屏看进展，手边知状态' : 'A glance at your Lock Screen'}</figcaption>
            <img src={`/marketing/${locale}/live-activity.png`} width="1200" height="290" alt={zh ? '实时活动示例：展示数据为 72% 进度、当前阶段与运行时间' : 'Real Live Activity showing 72% progress, the current phase and elapsed time'} />
          </figure>
        </>}
      </div>
    </section>
  );
}
export { HomeHero };
