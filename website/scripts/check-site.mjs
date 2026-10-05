import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const websiteRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const outputRoot = path.join(websiteRoot, 'doc_build');
const failures = [];

function walk(directory) {
  return readdirSync(directory).flatMap(name => {
    const absolute = path.join(directory, name);
    return statSync(absolute).isDirectory() ? walk(absolute) : [absolute];
  });
}

function expect(condition, message) {
  if (!condition) failures.push(message);
}

function html(relativePath) {
  const absolute = path.join(outputRoot, relativePath);
  expect(existsSync(absolute), `Missing generated page: ${relativePath}`);
  return existsSync(absolute) ? readFileSync(absolute, 'utf8') : '';
}

function count(source, expression) {
  return [...source.matchAll(expression)].length;
}

function textContent(source) {
  return source
    .replace(/<[^>]*>/g, '')
    .replace(/&quot;/g, '"')
    .replace(/&#x27;|&#39;/g, "'")
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&amp;/g, '&')
    .replace(/\s+/g, ' ');
}

function description(source) {
  return source.match(/<meta[^>]+name=["']description["'][^>]+content=["']([^"']*)/i)?.[1]
    ?? source.match(/<meta[^>]+content=["']([^"']*)["'][^>]+name=["']description["']/i)?.[1]
    ?? '';
}

expect(existsSync(outputRoot), 'doc_build is missing; run npm run build first.');

// Chinese rollout: all public installation prompts use the same verified procedure.
const zhPromptSource = readFileSync(path.join(websiteRoot, 'theme/components/ChineseHome/installPrompts.ts'), 'utf8');
const zhPrompt = zhPromptSource.match(/  zh: `([\s\S]*?)`,/)?.[1];
expect(Boolean(zhPrompt), 'Missing Chinese installation prompt.');
for (const page of ['index.mdx', 'agent-skill.md']) {
  const source = readFileSync(path.join(websiteRoot, `docs/zh/guide/${page}`), 'utf8');
  expect(zhPrompt && source.includes('```text\n' + zhPrompt + '\n```'), `${page} Chinese prompt differs from the homepage.`);
}

if (existsSync(outputRoot)) {
  const zhHome = html('index.html').replaceAll('runbuoy-zh-', 'runbuoy-');
  const enHome = html('en/index.html');
  expect(textContent(zhHome).includes('扫一眼，掌握任务的进展。'), 'Chinese hero must match approved copy.');
  expect(zhHome.includes('Agent 报状态，ChatGPT 看全貌。') && zhHome.includes('私人预览'), 'Chinese Agent integration must include Skill and private-preview ChatGPT UI.');
  expect(/<details[^>]*id="manual-install"[^>]*>/.test(zhHome) && !/<details[^>]*id="manual-install"[^>]*\bopen\b/.test(zhHome), 'Chinese manual installation must remain collapsed.');
  expect(!enHome.includes('runbuoy-zh-'), 'Chinese homepage must not render on English routes.');

  const zhQuickStart = html('guide/index.html');
  const enQuickStart = html('en/guide/index.html');
  const zhSkill = html('guide/agent-skill.html');
  const enSkill = html('en/guide/agent-skill.html');
  const zhInstall = html('guide/install.html');
  const enInstall = html('en/guide/install.html');
  const zhDownload = html('download.html');
  const enDownload = html('en/download.html');
  const zhSelfHosting = html('self-hosting.html');
  const enSelfHosting = html('en/self-hosting.html');
  const zhPrivacy = html('privacy.html');
  const enPrivacy = html('en/privacy.html');
  const zhSecurity = html('security.html');
  const enSecurity = html('en/security.html');
  const zhStatus = html('status.html');
  const enStatus = html('en/status.html');
  const zhSupport = html('support.html');
  const enSupport = html('en/support.html');
  const zhProgress = html('guide/progress.html');
  const enProgress = html('en/guide/progress.html');
  const enRun = html('en/guide/run.html');
  const zhQuickStartText = textContent(zhQuickStart);
  const enQuickStartText = textContent(enQuickStart);
  const zhProgressText = textContent(zhProgress);
  const enProgressText = textContent(enProgress);

  for (const [name, source] of [['Chinese home', zhHome], ['English home', enHome]]) {
    expect(count(source, /<main\b/g) === 1, `${name} must contain exactly one <main>.`);
    expect(count(source, /<h1\b/g) === 1, `${name} must contain exactly one <h1>.`);
    expect(source.includes('id="agent-install"'), `${name} is missing the primary agent installation prompt.`);
    expect(source.includes('id="manual-install"'), `${name} is missing the manual installation fallback.`);
    expect(source.includes('runbuoy-agent-prompt'), `${name} is missing the copyable agent prompt.`);
    expect(source.includes('runbuoy-flow'), `${name} is missing the three-step content.`);
    expect(source.includes('runbuoy-boundary__flow'), `${name} is missing the read-only architecture.`);
    expect(source.includes('runbuoy-home-feature-link'), `${name} feature cards are not real links.`);
  }

  expect(zhHome.includes('href="#agent-install"'), 'Chinese home does not prioritize the agent installation prompt.');
  expect(enHome.includes('href="#agent-install"'), 'English home does not prioritize the agent installation prompt.');
  expect(enHome.includes('href="/en/guide/#agent-install"'), 'English home Quick Start link is not locale-aware.');
  expect(enHome.includes('href="/en/guide/agent-skill"'), 'English Agent feature does not link to the English Skill page.');
  expect(!/href="\/(guide|privacy|download)(?:\/|"|#)/.test(enHome), 'English home contains a root-locale internal link.');
  expect(!/[\u3400-\u9fff]/u.test(description(enHome)), 'English home description contains Chinese text.');
  expect(!/[\u3400-\u9fff]/u.test(description(enRun)), 'English run-page description contains Chinese text.');

  expect(zhQuickStartText.includes('使用 Agent 安装（推荐）'), 'Chinese Quick Start is missing the recommended agent path.');
  expect(zhQuickStartText.includes('手动安装 · 当前可用'), 'Chinese Quick Start is missing the available manual path.');
  expect(enQuickStartText.includes('Install with an Agent (recommended)'), 'English Quick Start is missing the recommended agent path.');
  expect(enQuickStartText.includes('Manual installation · Available now'), 'English Quick Start is missing the available manual path.');
  expect(!zhQuickStart.includes('runbuoy.cloud/install.sh') && !enQuickStart.includes('runbuoy.cloud/install.sh'), 'Quick Start must not publish the planned RunBuoy installer URL.');

  for (const [name, source] of [
    ['Chinese home', zhHome],
    ['English home', enHome],
    ['Chinese Quick Start', zhQuickStart],
    ['English Quick Start', enQuickStart],
    ['Chinese install guide', zhInstall],
    ['English install guide', enInstall],
  ]) {
    const legacyChineseTerm = ['一键', '安装'].join('');
    const legacyEnglishTerm = ['one', 'click'].join('-');
    const pageText = textContent(source).toLowerCase();
    expect(!pageText.includes(legacyChineseTerm) && !pageText.includes(legacyEnglishTerm), `${name} contains a retired installer promise.`);
  }

  for (const [name, source] of [['Chinese Quick Start', zhQuickStartText], ['English Quick Start', enQuickStartText]]) {
    for (const required of [
      'brew install tmux uv',
      'sudo apt install tmux',
      'sudo dnf install tmux',
      'sudo pacman -S tmux',
      'runbuoy completion install bash',
      'runbuoy completion install zsh',
      'runbuoy completion install fish',
      'uv add --optional runbuoy runbuoy',
      'runbuoy --version',
      'runbuoy doctor',
      'runbuoy capabilities --json',
    ]) expect(source.includes(required), `${name} is missing: ${required}`);
  }

  for (const [name, source] of [['Chinese Skill page', zhSkill], ['English Skill page', enSkill]]) {
    expect(source.includes(`https://github.com/${name.startsWith('Chinese') ? 'Cabbyte' : 'TANG617'}/RunBuoy/tree/main/skills/runbuoy`), `${name} is missing the Skill source URL.`);
    expect(source.includes('SKILL.md'), `${name} is missing the required Skill files.`);
    expect(source.includes('references/installation.md'), `${name} does not route CLI installation through the Skill safety rules.`);
    expect(source.includes('runbuoy doctor --json'), `${name} is missing machine verification.`);
    expect(source.includes('$runbuoy'), `${name} is missing the invocation name.`);
    expect(source.includes('Use $runbuoy to monitor this command safely from my iPhone.'), `${name} is missing the default usage example.`);
  }

  expect(zhDownload.includes('iOS 18') && enDownload.includes('iOS 18'), 'Download pages must state the iOS 18+ requirement.');
  expect(zhDownload.includes('Global') && enDownload.includes('Global'), 'Download pages must state the current Global-only availability.');
  expect(zhSelfHosting.includes('RUNBUOY_API_BASE_URL') && enSelfHosting.includes('RUNBUOY_API_BASE_URL'), 'Self-hosting pages must configure the iOS Server URL.');
  expect(zhProgressText.includes('uv add --optional runbuoy runbuoy') && enProgressText.includes('uv add --optional runbuoy runbuoy'), 'Progress pages must install the project SDK as an optional extra.');
  expect(zhProgressText.includes('runbuoy emit') && enProgressText.includes('runbuoy emit'), 'Progress pages must include the emit fallback.');

  for (const [name, source] of [
    ['Chinese privacy', zhPrivacy],
    ['English privacy', enPrivacy],
  ]) {
    const pageText = textContent(source);
    expect(pageText.includes('24') && pageText.includes('30') && pageText.includes('90'), `${name} is missing retention windows.`);
    expect(pageText.toLowerCase().includes('live activit'), `${name} is missing the active Live Activity retention exclusion.`);
  }

  for (const [name, source] of [
    ['Chinese status', zhStatus],
    ['English status', enStatus],
  ]) {
    expect(source.includes('/healthz') && source.includes('/readyz'), `${name} is missing health/readiness definitions.`);
    expect(source.includes('api.runbuoy.cloud'), `${name} is missing the Global endpoint.`);
  }

  for (const [name, source] of [
    ['Chinese security', zhSecurity],
    ['English security', enSecurity],
    ['Chinese support', zhSupport],
    ['English support', enSupport],
  ]) {
    expect(source.includes('security/advisories/new'), `${name} is missing private vulnerability reporting.`);
  }

  const generatedFiles = new Set(walk(outputRoot).map(file => path.relative(outputRoot, file)));
  for (const file of [...generatedFiles].filter(item => item.endsWith('.html'))) {
    const source = readFileSync(path.join(outputRoot, file), 'utf8');
    for (const match of source.matchAll(/(?:href|src)=["']([^"']+)["']/g)) {
      const rawTarget = match[1];
      if (!rawTarget.startsWith('/') || rawTarget.startsWith('//')) continue;
      const pathname = decodeURIComponent(rawTarget.split(/[?#]/, 1)[0]);
      if (pathname === '/') continue;
      const relative = pathname.slice(1);
      const candidates = path.extname(relative)
        ? [relative]
        : [path.join(relative, 'index.html'), `${relative}.html`];
      expect(candidates.some(candidate => generatedFiles.has(candidate)), `Broken internal target ${rawTarget} in ${file}`);
    }
  }
}

if (failures.length > 0) {
  console.error(failures.map(failure => `- ${failure}`).join('\n'));
  process.exit(1);
}

console.log('Static content and internal-link checks passed.');
