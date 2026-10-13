import { Link } from '@rspress/core/theme-original';
import './index.css';

export function HomeFooter() {
  return <footer className="runbuoy-zh-footer"><strong>RunBuoy</strong><nav aria-label="页脚"><Link href="/docs/">使用文档</Link><Link href="/support">支持</Link><Link href="/privacy">隐私</Link><Link href="/en/" lang="en">English</Link></nav></footer>;
}
