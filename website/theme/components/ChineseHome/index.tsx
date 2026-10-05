import { HomeBackground, type HomeLayoutProps, Link } from '@rspress/core/theme-original';
import { HomeHero } from './HomeHero';
import { HomeFeature } from './HomeFeature';
import { HomeContent } from './HomeContent';
import { HomeFooter } from './HomeFooter';
import './index.css';

export function ChineseHome(props: HomeLayoutProps) {
  return <>
    <HomeBackground />
    <main id="main-content">
      {props.beforeHero}
      <HomeHero beforeHeroActions={props.beforeHeroActions} afterHeroActions={props.afterHeroActions} />
      {props.afterHero}
      {props.beforeFeatures}
      <HomeFeature />
      {props.afterFeatures}
      <section className="runbuoy-zh-agents" id="agent-integration" aria-labelledby="agent-integration-heading">
        <header className="runbuoy-zh-section-header">
          <p className="runbuoy-zh-section-eyebrow">Agent 集成</p>
          <h2 id="agent-integration-heading">Agent 报状态，ChatGPT 看全貌。</h2>
        </header>
        <div className="runbuoy-zh-agents__cards">
          <article>
            <p className="runbuoy-zh-section-eyebrow">RunBuoy Skill</p>
            <h3>Agent 报告任务状态</h3>
            <p>接入 RunBuoy Skill，让 Agent 报阶段、传结果，需关注时发消息。</p>
            <Link href="#agent-install">让 Agent 安装与验证 →</Link>
          </article>
          <article>
            <p className="runbuoy-zh-section-eyebrow">ChatGPT Plugin 与交互看板 · 私人预览</p>
            <h3>问一句，查进展；<br />点一下，看全貌。</h3>
            <p>在 ChatGPT 里问任务、查进展；打开 RunBuoy 看板，看运行、翻历史、找电脑、读消息。</p>
            <p><strong>选中任务，接着聊。</strong> 在详情中点「用于对话」，把这条任务作为后续提问的上下文。</p>
            <Link href="/guide/agent-skill#chatgpt">了解看板与连接方式 →</Link>
          </article>
        </div>
        <figure>
          <img src="/marketing/zh-Hans/chatgpt-workspace.jpg" width="1280" height="720" loading="lazy" alt="RunBuoy ChatGPT 看板预览：左侧选择运行任务，右侧查看阶段、进度、消息与用于对话按钮" />
          <figcaption>ChatGPT Plugin 看板 · 示例数据 · 当前为私人预览，连接需在 iPhone 确认。</figcaption>
        </figure>
      </section>
      <HomeContent />
    </main>
    <HomeFooter />
  </>;
}
