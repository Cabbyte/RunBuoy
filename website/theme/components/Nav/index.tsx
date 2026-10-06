import { useFrontmatter, useLang } from '@rspress/core/runtime';
import { Nav as OriginalNav, type NavProps, Link } from '@rspress/core/theme-original';
import { MASCOT, STORE_URL } from '../ChineseHome/shared';
import './index.css';

export function Nav(props: NavProps) {
  const lang = useLang();
  const { frontmatter } = useFrontmatter();
  if (!lang.startsWith('zh') || frontmatter.pageType !== 'home') return <OriginalNav {...props} />;
  return <header className="runbuoy-zh-home-surface runbuoy-zh-nav">
    <Link href="/" className="runbuoy-zh-nav__brand" aria-label="RunBuoy 首页"><img src={MASCOT} width="36" height="36" alt="" /><strong>RunBuoy</strong></Link>
    <nav aria-label="主导航">
      <Link className="runbuoy-zh-nav__desktop" href={STORE_URL}>下载 App</Link>
      <Link className="runbuoy-zh-nav__start" href="#agent-install">快速开始</Link>
      <Link className="runbuoy-zh-nav__desktop" href="/docs/">使用文档</Link>
      <details className="runbuoy-zh-nav__language runbuoy-zh-nav__desktop"><summary>简体中文<span aria-hidden="true">⌄</span></summary><Link href="/en/" lang="en">English</Link></details>
    </nav>
  </header>;
}
