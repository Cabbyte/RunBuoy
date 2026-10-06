import { Link } from '@rspress/core/theme-original';
import './index.css';

export function HomeFooter() {
  return <footer className="runbuoy-zh-footer"><strong>RunBuoy</strong><nav aria-label="页脚"><Link className="runbuoy-zh-footer__mobile" href="/docs/">使用文档</Link><Link className="runbuoy-zh-footer__mobile" href="/en/" lang="en">English</Link><Link href="/support">支持</Link><span aria-hidden="true">·</span><Link href="/privacy">隐私</Link></nav></footer>;
}
