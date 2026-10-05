import type { Feature } from '@rspress/core';
import { useFrontmatter, useLang } from '@rspress/core/runtime';
import { Link, renderHtmlOrText } from '@rspress/core/theme-original';
import {
  ArrowRight,
  Pulse,
  Robot,
  ShieldCheck,
} from '@phosphor-icons/react';
import type { Icon } from '@phosphor-icons/react';

import { localizeHref } from '../../../utils/localizeHref';
import './index.css';

function getGridClass(feature: Feature): string {
  return `runbuoy-zh-home-feature__item--span-${feature.span ?? 4}`;
}

function HomeFeatureItem({ feature }: { feature: Feature }) {
  const lang = useLang();
  const { title, details, link } = feature;
  const Icon: Icon = link?.includes('privacy')
    ? ShieldCheck
    : link?.includes('agent')
      ? Robot
      : Pulse;
  const content = (
    <article className="runbuoy-zh-home-feature__card">
      <div className="runbuoy-zh-home-feature__icon" aria-hidden="true">
        <Icon size={24} weight="duotone" />
      </div>
      <h3 className="runbuoy-zh-home-feature__title">{title}</h3>
      <p
        className="runbuoy-zh-home-feature__detail"
        {...renderHtmlOrText(details)}
      />
      {link && (
        <span className="runbuoy-zh-home-feature__more" aria-hidden="true">
          <ArrowRight size={18} weight="bold" />
        </span>
      )}
    </article>
  );

  return (
    <div className={`runbuoy-zh-home-feature__item ${getGridClass(feature)}`}>
      {link ? (
        <Link
          href={localizeHref(link, lang)}
          className="runbuoy-zh-home-feature-link"
          aria-label={title}
        >
          {content}
        </Link>
      ) : (
        content
      )}
    </div>
  );
}

function HomeFeature({ features: featuresProp }: { features?: Feature[] }) {
  const { frontmatter } = useFrontmatter();
  const lang = useLang();
  const features = featuresProp ?? frontmatter?.features;
  const zh = lang.startsWith('zh');

  return (
    <section
      className="runbuoy-zh-home-feature"
      aria-labelledby="runbuoy-zh-home-feature-heading"
    >
      <header className="runbuoy-zh-home-feature__header">
        <p className="runbuoy-zh-section-eyebrow">
          {zh ? '从开始，到结束' : 'From the first step to the final result'}
        </p>
        <h2 id="runbuoy-zh-home-feature-heading">
          {zh ? '进展随手看，消息随身收。' : 'Less checking. More knowing.'}
        </h2>
        <p>
          {zh
            ? '锁屏看阶段，结束看结果。任务需要关注时，接收它发来的重要消息。'
            : 'Running, making progress, or finished. The state that matters stays within reach.'}
        </p>
      </header>
      <div className="runbuoy-zh-home-feature__grid">
        {features?.map(feature => (
          <HomeFeatureItem key={feature.title} feature={feature} />
        ))}
      </div>
    </section>
  );
}

export { HomeFeature };
