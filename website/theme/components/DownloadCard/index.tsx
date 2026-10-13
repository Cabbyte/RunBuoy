import { AppStoreLogo } from '@phosphor-icons/react';
import { STORE_URL } from '../ChineseHome/shared';
import './index.css';
export function DownloadCard() {
  return <div className="runbuoy-download-card">
    <div><h2>把进展带到 iPhone</h2><p className="runbuoy-download-card__desktop-copy">用 iPhone 相机扫描二维码，或直接打开 App Store。</p><p className="runbuoy-download-card__mobile-copy">在 iPhone 安装 RunBuoy，随身查看任务进展。</p><a href={STORE_URL}><AppStoreLogo size={23} aria-hidden="true" />App Store 下载</a></div>
    <figure><img src="/marketing/zh-Hans/app-store-qr.png" alt="RunBuoy App Store 下载二维码；也可使用旁边的下载链接" width="196" height="196" /><figcaption>iPhone 扫码下载</figcaption></figure>
  </div>;
}
