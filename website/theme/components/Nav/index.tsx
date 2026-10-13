import { useEffect, useRef, useState } from 'react';
import { useFrontmatter, useLang, useLocation, usePage } from '@rspress/core/runtime';
import { Nav as OriginalNav, type NavProps, Link, Search } from '@rspress/core/theme-original';
import { CaretDown, Check, List, X } from '@phosphor-icons/react';
import { SwitchAppearance } from '../SwitchAppearance';
import { MASCOT } from '../ChineseHome/shared';
import './index.css';

function ChineseNav({ home }: { home: boolean }) {
  const { pathname } = useLocation();
  const { page } = usePage();
  const [mobileOpen, setMobileOpen] = useState(false);
  const [languageOpen, setLanguageOpen] = useState(false);
  const root = useRef<HTMLElement>(null);
  const language = useRef<HTMLDivElement>(null);
  const languageButton = useRef<HTMLButtonElement>(null);
  const menuButton = useRef<HTMLButtonElement>(null);
  const englishPath = page.pageType === '404' || pathname === '/' ? '/en/' : `/en${pathname}`;
  const quickStart = /^\/guide\/(?:index(?:\.html)?)?$/.test(pathname);
  const download = /^\/download(?:\.html)?\/?$/.test(pathname);
  const close = () => { setMobileOpen(false); setLanguageOpen(false); };

  useEffect(close, [pathname]);
  useEffect(() => {
    const outside = (event: PointerEvent) => {
      if ((event.target as Element).closest('.rp-search-panel__modal')) return;
      if (!language.current?.contains(event.target as Node)) setLanguageOpen(false);
      if (!root.current?.contains(event.target as Node)) setMobileOpen(false);
    };
    const escape = (event: KeyboardEvent) => {
      if (event.key !== 'Escape') return;
      if ((event.target as Element).closest('.rp-search-panel__modal')) {
        requestAnimationFrame(() => root.current?.querySelector<HTMLButtonElement>('.rp-search-button')?.focus());
        return;
      }
      if (!root.current?.contains(event.target as Node)) return;
      if (languageOpen) { event.preventDefault(); setLanguageOpen(false); languageButton.current?.focus(); }
      else if (mobileOpen) { event.preventDefault(); setMobileOpen(false); menuButton.current?.focus(); }
    };
    document.addEventListener('pointerdown', outside);
    document.addEventListener('keydown', escape);
    return () => { document.removeEventListener('pointerdown', outside); document.removeEventListener('keydown', escape); };
  }, [languageOpen, mobileOpen]);
  useEffect(() => {
    const breakpoint = window.matchMedia('(max-width: 1000px)');
    const reset = () => { setMobileOpen(false); setLanguageOpen(false); };
    breakpoint.addEventListener('change', reset);
    return () => breakpoint.removeEventListener('change', reset);
  }, []);

  return <header ref={root} className={`runbuoy-site-nav ${home ? 'runbuoy-site-nav--home' : 'rp-nav runbuoy-site-nav--docs'}`} onClick={event => { if ((event.target as Element).closest('a')) close(); }}>
    <Link href="/" className="runbuoy-site-nav__brand" aria-label="RunBuoy 首页"><img src={MASCOT} width="36" height="36" alt="" /><strong>RunBuoy</strong></Link>
    <Link href="/download" className="runbuoy-site-nav__download runbuoy-site-nav__mobile-cta" aria-current={download ? 'page' : undefined}>下载 App</Link>
    <button ref={menuButton} type="button" className="runbuoy-site-nav__toggle" aria-label={mobileOpen ? '关闭导航' : '打开导航'} aria-expanded={mobileOpen} aria-controls="runbuoy-site-menu" onClick={() => setMobileOpen(!mobileOpen)}>{mobileOpen ? <X size={23} /> : <List size={23} />}</button>
    <div id="runbuoy-site-menu" className={`runbuoy-site-nav__panel ${mobileOpen ? 'is-open' : ''}`} onBlur={event => { if (event.relatedTarget && !(event.relatedTarget as Element).closest('.rp-search-panel__modal') && !root.current?.contains(event.relatedTarget as Node)) close(); }}>
      {!home && <div className="runbuoy-site-nav__search"><Search /></div>}
      <nav aria-label="主导航">
        <Link href="/guide/" aria-current={quickStart ? 'page' : undefined}>快速开始</Link>
        <Link href="/docs/" aria-current={!home && !quickStart && !download ? 'page' : undefined}>使用文档</Link>
        <div className="runbuoy-site-nav__language" ref={language} onBlur={event => { if (event.relatedTarget && !event.currentTarget.contains(event.relatedTarget as Node)) setLanguageOpen(false); }}>
          <button type="button" ref={languageButton} aria-expanded={languageOpen} aria-controls="runbuoy-language-options" onClick={() => setLanguageOpen(!languageOpen)}>简体中文<CaretDown size={15} aria-hidden="true" /></button>
          {languageOpen && <div id="runbuoy-language-options" className="runbuoy-site-nav__languages"><span lang="zh-Hans">简体中文<Check size={17} aria-label="当前语言" /></span><Link href={englishPath} lang="en" hrefLang="en" rel="alternate">English</Link></div>}
        </div>
        <Link href="/download" className="runbuoy-site-nav__download runbuoy-site-nav__desktop-cta" aria-current={download ? 'page' : undefined}>下载 App</Link>
        <div className="runbuoy-site-nav__mobile-language"><span>简体中文 <Check size={16} aria-label="当前语言" /></span><Link href={englishPath} lang="en" hrefLang="en" rel="alternate">English</Link></div>
      </nav>
      {!home && <div className="runbuoy-site-nav__appearance"><SwitchAppearance /></div>}
      <div className="runbuoy-site-nav__mobile-extra"><Link href="/support">支持</Link><Link href="/privacy">隐私</Link></div>
    </div>
  </header>;
}

export function Nav(props: NavProps) {
  const lang = useLang();
  const { frontmatter } = useFrontmatter();
  return lang.startsWith('zh') ? <ChineseNav home={frontmatter.pageType === 'home'} /> : <OriginalNav {...props} />;
}
