import { readFile, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = fileURLToPath(new URL('../../../../', import.meta.url));
const origin = 'https://www.runbuoy.cloud';
const routes = ['/', '/guide/', '/docs/', '/download', '/guide/pairing', '/guide/run', '/en/', '/en/download', '/en/guide/pairing'];
const checks = await Promise.all(routes.map(async route => {
  const response = await fetch(origin + route);
  const html = await response.text();
  if (!response.ok) throw new Error(`${route}: HTTP ${response.status}`);
  const chinese = !route.startsWith('/en/');
  if (chinese && !html.includes('runbuoy-site-nav')) throw new Error(`${route}: old navigation`);
  if (['/', '/guide/', '/guide/pairing'].includes(route) && !html.includes('复制配对提示词')) throw new Error(`${route}: missing pairing prompt`);
  if (route === '/download' && !html.includes('app-store-qr.png')) throw new Error('Missing download QR');
  return { route, status: response.status, finalUrl: response.url, sharedChineseNavigation: chinese };
}));
const assets = await Promise.all(['app-store-qr.png', 'homepage/mascot-transparent.png', 'homepage/water-background.png', 'homepage/phone-frame.png', 'homepage/lock-screen.png'].map(async asset => {
  const route = '/marketing/zh-Hans/' + asset;
  const response = await fetch(origin + route);
  const remote = Buffer.from(await response.arrayBuffer());
  const local = await readFile(path.join(root, 'website/docs/public', route));
  const hash = buffer => createHash('sha256').update(buffer).digest('hex');
  if (!response.ok || hash(remote) !== hash(local)) throw new Error(`Asset mismatch: ${route}`);
  return { route, status: response.status, sha256: hash(remote), matchesRepository: true };
}));
await writeFile(new URL('production-checks.json', import.meta.url), JSON.stringify({ checkedAt: new Date().toISOString(), origin, websiteCommit: 'fc4aa39096c09c31d35e0de6898c1580d00f2e66', pagesRun: 'https://github.com/Cabbyte/RunBuoy/actions/runs/38363799118', routes: checks, assets }, null, 2) + '\n');
console.log(`Verified ${checks.length} production routes and ${assets.length} exact asset hashes.`);
