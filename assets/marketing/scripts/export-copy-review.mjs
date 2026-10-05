// Export exact current copy for discussion. Does not rewrite production copy.
// Run from the repository root after `cd website && npm ci`.
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { createHash } from 'node:crypto';

const root = fileURLToPath(new URL('../../../', import.meta.url));
const require = createRequire(path.join(root, 'website/package.json'));
const ts = require('typescript');
const base = path.join(root, 'assets/marketing/copy-review');
mkdirSync(base, { recursive: true });
const read = file => readFileSync(path.join(root, file), 'utf8');
const old = JSON.parse(read('assets/marketing/copy-review/before-agent-priority.json'));
const rows = [];
const sourceHashes = {};
const ref = (file, text) => {
  const src = read(file);
  sourceHashes[file] = createHash('sha256').update(src).digest('hex');
  const index = src.indexOf(text);
  return { file, line: index < 0 ? null : src.slice(0, index).split('\n').length };
};

function literals(file, variable = 'copy', override) {
  const src = override ?? read(file);
  const tree = ts.createSourceFile(file, src, ts.ScriptTarget.Latest, true, ts.ScriptKind.TSX);
  const result = {};
  function walk(node, key) {
    if (ts.isAsExpression(node)) return walk(node.expression, key);
    if (ts.isObjectLiteralExpression(node)) return node.properties.forEach(p => walk(p.initializer, [key, p.name.text].filter(Boolean).join('.')));
    if (ts.isArrayLiteralExpression(node)) return node.elements.forEach((v, i) => walk(v, `${key}.${i}`));
    if (ts.isStringLiteral(node) || ts.isNoSubstitutionTemplateLiteral(node)) {
      result[key] = { text: node.text, line: tree.getLineAndCharacterOfPosition(node.getStart(tree)).line + 1 };
      return;
    }
    throw new Error(`Nonliteral copy at ${file}:${key}`);
  }
  function visit(node) {
    if (ts.isVariableDeclaration(node) && node.name.getText(tree) === variable) walk(node.initializer, '');
    else ts.forEachChild(node, visit);
  }
  visit(tree);
  return result;
}

function add(id, section, label, zh, en, files, intent, concern = '') {
  rows.push({ id, section, label, zh, en, sources: files.map(([f, text]) => ref(f, text)), intent, concern, status: '待用户审阅' });
}
function fromLiteral(id, section, key, data, file, intent, concern = '') {
  const z = data[`zh.${key}`], e = data[`en.${key}`];
  if (!z || !e) throw new Error(`Missing bilingual key: ${key}`);
  const labels = {
    storyEyebrow: '场景区眉题', storyTitle: '场景区标题', storyLead: '场景区说明',
    progressNote: '进度能力条件', progressLink: '进度接入链接',
    setupEyebrow: '安装区眉题', setupTitle: '安装区标题', setupLead: '安装区说明',
    download: '下载入口', dependencies: '依赖说明链接', guide: '配对指南链接',
    agentTitle: 'Agent 安装卡片标题', agentLead: 'Agent 安装卡片说明',
    manualSummary: '手动安装折叠入口', promptCopy: '安装提示词复制按钮', promptNote: '安装提示词执行范围',
    boundaryEyebrow: '数据边界眉题', boundaryTitle: '数据边界标题', boundaryLead: '数据边界说明',
    readonly: '手机权限说明', privacy: '隐私入口', finalTitle: '收尾标题', finalLead: '收尾说明',
    finalSecondary: '收尾第二入口', copied: '复制成功反馈', copy: '复制按钮辅助标签', copyFailed: '复制失败反馈',
    screenshotAlt: '详情截图替代文字', tagline: '页脚产品概括', product: '页脚产品分组', resources: '页脚资源分组',
    quickStart: '快速开始入口', docs: '文档入口', security: '安全入口', status: '服务状态入口', support: '支持入口',
    selfHosting: '自托管入口', github: '源码入口', copyright: '版权与品牌声明',
  };
  const nested = key.match(/^(scenarios|steps|nodes)\.(\d)\.(\d)$/);
  const label = labels[key] ?? (nested ? `${{scenarios:'场景',steps:'手动步骤',nodes:'数据流节点'}[nested[1]]} ${Number(nested[2])+1} ${nested[3] === '0' ? '标题' : '说明'}` : key);
  add(id, section, label, z.text, e.text, [[file, key.split('.')[0]]], intent, concern);
  rows.at(-1).sourceKey = key;
  rows.at(-1).sources = [{ file, line: z.line }, { file, line: e.line }];
  if (old[file]) {
    const before = literals(file, 'copy', old[file]);
    const bz = before[`zh.${key}`]?.text, be = before[`en.${key}`]?.text;
    if (bz !== z.text || be !== e.text) Object.assign(rows.at(-1), { previous: { zh: bz ?? null, en: be ?? null }, status: '已按 Agent 优先调整；措辞仍待审阅' });
  }
}

const homes = ['website/docs/zh/index.mdx', 'website/docs/en/index.mdx'];
const texts = homes.map(read);
const scalar = (text, key) => text.match(new RegExp(`^${key}: (.+)$`, 'm'))?.[1];
const home = (id, label, values, intent, concern = '') => add(id, '首页首屏', label, ...values, homes.map((f, i) => [f, id === 'H01' ? '  text: |-' : values[i].split('\n')[0]]), intent, concern);
home('H01', '主标题', texts.map(t => t.match(/^  text: \|-\n((?:    .+\n)+)/m)[1].trim().replace(/\n    /g, '\n')), '说明离开电脑后仍能获知任务状态。', '它只表达结果，没有直接说明服务哪些任务、通过什么接入；也是上一版重复最多的意思。');
home('H02', '首屏说明', texts.map(t => scalar(t, '  tagline')), '给出使用场景与 Mac/Linux → iPhone 的方向。', '场景先列训练、构建、处理数据，Agent 没有出现；这未经用户确认，不应默认为核心场景排序。');
home('H03', '页面描述 / 搜索摘要', texts.map(t => scalar(t, 'description')), '搜索与分享时说明产品用途。', '需要与最终核心定位一致；目前仍围绕进度与长任务。');
const actionTexts = texts.map(t => [...t.matchAll(/^      text: (.+)$/gm)].map(m => m[1]));
for (let i = 0; i < actionTexts[0].length; i++) home(`H0${i + 4}`, `首屏按钮 ${i + 1}`, actionTexts.map(a => a[i]), i === 0 ? '获取 iPhone App。' : '进入已改为 Agent 优先的安装区。');

function ternaries(file, section, prefix, notes) {
  const src = read(file), tree = ts.createSourceFile(file, src, ts.ScriptTarget.Latest, true, ts.ScriptKind.TSX);
  const pairs = [];
  function visit(node) {
    if (ts.isConditionalExpression(node) && node.condition.getText(tree) === 'zh' && ts.isStringLiteral(node.whenTrue) && ts.isStringLiteral(node.whenFalse) && !['zh-Hans', 'cn'].includes(node.whenTrue.text)) pairs.push(node);
    ts.forEachChild(node, visit);
  }
  visit(tree);
  pairs.forEach((n, i) => add(`${prefix}${String(i + 1).padStart(2, '0')}`, section, notes[i]?.[0] ?? '界面文字', n.whenTrue.text, n.whenFalse.text, [[file, n.whenTrue.getText(tree)]], notes[i]?.[1] ?? '辅助说明。', notes[i]?.[2] ?? ''));
}
ternaries('website/theme/components/HomeHero/index.tsx', '首页首屏辅助文字', 'HX', [
  ['系统要求', '说明价格、设备要求和电脑端安装要求。', 'CLI 是实现依赖；安装方式应由 Agent 优先的入口解释。'],
  ['任务列表替代文字', '为读屏用户描述示例图。', '示例数据不是用户真实任务；“真实界面”与“真实业务数据”要区分。'],
  ['锁屏图注', '指出锁屏中的状态展示。', '“进度在这里”仍与主标题重复。'],
  ['实时活动替代文字', '为读屏用户描述实时活动截图。', '72% 是构造的演示数据。'],
]);
ternaries('website/theme/components/HomeFeature/index.tsx', '首页功能区', 'F', [
  ['区块眉题', '引出任务从开始到结束的过程。', '抽象过渡句，没有新增产品信息。'],
  ['区块标题', '强调减少反复查看。', '与 H01 重复，没有说明哪些状态变化值得关注。'],
  ['区块说明', '列出运行状态、进度和结果。', '没有提到任务消息与显式关注提醒。'],
]);
const features = texts.map(t => [...t.matchAll(/  - title: (.+)\n    details: (.+)/g)]);
for (let i = 0; i < 3; i++) for (let k = 1; k <= 2; k++) {
  add(`F${String(4 + i * 2 + k - 1).padStart(2, '0')}`, '首页功能区', `功能 ${i + 1} ${k === 1 ? '标题' : '说明'}`, features[0][i][k], features[1][i][k], homes.map((f, j) => [f, features[j][i][k]]), ['锁屏与灵动岛展示。', '显示任务结果与历史。', '让支持 Skill 的 Agent 接入 RunBuoy。'][i], ['“不用反复看终端”较泛，应说明用户能获知的具体信息。', '只写查看结果，主动提醒与显式关注消息没有讲清。', 'Agent 被放在第三个功能项；默认安装方式已明确，但是否也是第一核心场景还需用户定义。'][i]);
}

const contentFile = 'website/theme/components/HomeContent/index.tsx', content = literals(contentFile);
const sections = { S: '使用场景', I: '安装区', P: '数据与执行边界', C: '收尾号召', U: '辅助与反馈' };
const counts = {};
const important = {
  storyEyebrow: ['引入等待场景。', '“给等待一个交代”含义抽象，不能帮助理解产品。'],
  storyTitle: ['说明电脑任务可继续执行。', '“你可以先离开”仍重复 H01；未呈现 Agent/任务与 RunBuoy 的关系。'],
  storyLead: ['将多机任务放到一个视图。', '“不只是还在跑”容易暗示所有任务都有细粒度进度；须有显式上报。'],
  progressNote: ['限定百分比与 ETA 的来源。', '是功能解释，放在主要卖点下面只能补充，不能修复主标题的绝对承诺。'],
  setupTitle: ['把 Agent 安装设为主路径。', '本轮已按用户明确要求修改。'],
  setupLead: ['说明把提示词交给什么工具。', '不承诺所有 Agent 都支持 Skill。'],
  agentLead: ['说明 Agent 会安装与验证哪些组件。', '安装与真正接入任务是两个步骤；不能写成粘贴后自动跟踪一切。'],
  manualSummary: ['将手动安装作为折叠后的备选路径。', '本轮已按用户明确要求修改。'],
  promptNote: ['说明安装提示词的实际执行范围。', '配对、任务启动仍需用户主动发起；不是全自动安装到推送闭环。'],
  boundaryEyebrow: ['引出数据范围。', '“清清楚楚”是评价词，信息量低。'],
  boundaryTitle: ['说明状态外发与本地执行分离。', '“工作留在电脑”过宽；不应让人误以为业务依赖的云端 AI 也变成本地执行。'],
  boundaryLead: ['说明默认不上传的数据及日志片段例外。', '功能边界应准确；“经过清理”不等于绝对无敏感信息。'],
  readonly: ['说明手机的查看权限边界。', '这是重要边界，但是否作为前列宣传卖点需要单独决定。'],
  finalTitle: ['收尾情绪性号召。', '“让等待轻一点”过泛，无法区分 RunBuoy。'],
  finalLead: ['引导下一次任务接入。', '仍重复“带在身边”，没有给出 Agent 的具体使用动作。'],
  screenshotAlt: ['为读屏用户描述任务详情。', '“真实示例进度”容易混淆：实际界面、构造的任务数据。'],
};
for (const key of Object.keys(content).filter(k => k.startsWith('zh.')).map(k => k.slice(3))) {
  const group = /^(story|scenarios|progress)/.test(key) ? 'S' : /^(setup|steps|download|dependencies|guide|agent|manual|prompt)/.test(key) ? 'I' : /^(boundary|nodes|readonly|privacy)/.test(key) ? 'P' : /^final/.test(key) ? 'C' : 'U';
  const id = `${group}${String(counts[group] = (counts[group] ?? 0) + 1).padStart(2, '0')}`;
  const defaults = group === 'I' ? ['引导安装、配对或查看操作说明。', 'Agent 默认展开；手动安装相关内容默认折叠。'] : group === 'S' ? ['说明一个具体任务场景或接入方式。', '训练、构建、备份的优先顺序尚未作为产品定位得到确认。'] : group === 'P' ? ['说明数据流与手机权限。', ''] : ['辅助导航、无障碍或操作反馈。', '不承担核心卖点。'];
  fromLiteral(id, sections[group], key, content, contentFile, ...(important[key] ?? defaults));
}
add('I99', '安装区', 'Agent 提示词旁的指南链接', '使用指南', 'Read the guide', [[contentFile, "'使用指南'"]], '打开完整安装指南。');

const footerFile = 'website/theme/components/HomeFooter/index.tsx', footer = literals(footerFile);
Object.keys(footer).filter(k => k.startsWith('zh.')).forEach((key, i) => fromLiteral(`N${String(i + 1).padStart(2, '0')}`, '页脚与导航', key.slice(3), footer, footerFile, i === 0 ? '概括产品用途。' : key.endsWith('copyright') ? '品牌署名与开源、隐私定位。' : '导航标签。', i === 0 ? '“始终”比当前确认/过期状态的实际语义更绝对。' : key.endsWith('copyright') ? '“隐私为先”是定位表态；需要由默认数据范围来支撑。' : ''));
for (const [locale, file] of [['zh', 'website/docs/zh/_nav.json'], ['en', 'website/docs/en/_nav.json']]) {
  const nav = JSON.parse(read(file));
  function visit(v) { if (Array.isArray(v)) return v.forEach(visit); if (v && typeof v === 'object') { if (v.text) { const row = rows.find(r => r.section === '页脚与导航' && r[locale] === v.text); if (row) row.sources.push(ref(file, v.text)); else throw new Error(`Uncatalogued nav label ${v.text}`); } Object.values(v).filter(x => typeof x === 'object').forEach(visit); } }
  visit(nav);
}

const storeFile = 'assets/marketing/sources/copy.json', store = JSON.parse(read(storeFile));
const storeIntent = ['展示锁屏状态。', '展示成功/失败与历史。', '展示多机任务。', '展示阶段、进度与消息。', '展示配对路径。', '说明本地执行与数据边界。'];
const storeConcern = [
  '首张仍强调“看进度”；Agent 接入和重要消息没有体现，“就知道跑到哪”也依赖任务上报。',
  '“成了/出错了”口语风格需确认；英文 Finished 包含失败结束，二者不是互斥结果。',
  '默认展示训练/构建/备份，未体现 Agent；多机是否值得占第三张还需确认。',
  '与第 1 张高度重复；“真实”指上报来源，截图数据本身是示例。',
  '副标题直接让用户安装 CLI，没有表达 Agent 是主要安装手段；等核心文案确认后一起重出图片。',
  '“工作留在电脑”边界过宽；具体可证明的是 RunBuoy 不上传默认排除字段、手机只读。',
];
store['zh-Hans'].slides.forEach((slide, i) => ['title', 'subtitle', 'footnote'].forEach((key, j) => add(`A${String(i + 1).padStart(2, '0')}.${['T', 'S', 'N'][j]}`, 'App Store 宣传图', `第 ${i + 1} 张${['标题', '副标题', '脚注'][j]}`, slide[key], store['en-US'].slides[i][key], [[storeFile, `"id":"${slide.id}"`]], j === 2 ? '示例说明或兼容性/功能条件。' : storeIntent[i], j === 2 ? '检查是否把理解主卖点必需的条件藏进小字。' : storeConcern[i])));
const renderFile = 'assets/marketing/scripts/render.swift';
[
  ['A01.L', 'App Store 宣传图', '第一张功能标签', '实时活动 · 灵动岛', 'Live Activities · Dynamic Island', '标识 iOS 展示形式。', '图片实际展示锁屏；灵动岛是能力标签，不是该图实截。'],
  ['A06.D1', 'App Store 宣传图', '数据流 1', '电脑执行任务', 'Your computer runs it', '说明执行位置。', ''],
  ['A06.D2', 'App Store 宣传图', '数据流 2', 'Server 转发状态', 'Server relays status', '说明服务端职责。', 'Server 是实现术语；用户是否需要在宣传图理解它值得讨论。'],
  ['A06.D3', 'App Store 宣传图', '数据流 3', 'iPhone 只读展示', 'iPhone keeps you in view', '说明手机职责。', '英文没有明确表达只读，与中文语义不完全一致。'],
  ['A06.L', 'App Store 宣传图', '权限说明', '不在手机上启动、停止或重试任务。', 'No remote start, stop, or retry.', '说明手机不执行控制操作。', ''],
  ['O01', '分享卡片', '主标题', '离开电脑，\n进度就在手边。', 'Step away.\nStay in the know.', '分享时概括使用收益。', '仍重复离开电脑/在手边；需要跟随最终定位。'],
  ['O02', '分享卡片', '平台说明', 'Mac / Linux → iPhone', 'Mac / Linux → iPhone', '说明平台与方向。', ''],
  ['H00', '通用固定文字', '品牌名', 'RunBuoy', 'RunBuoy', '现有品牌名。', ''],
  ['H06', '通用固定文字', '首屏平台眉题', 'MAC / LINUX → IPHONE', 'MAC / LINUX → IPHONE', '说明平台与方向。', ''],
].forEach(([id, section, label, zh, en, intent, concern]) => add(id, section, label, zh, en, [[id === 'H06' ? 'website/theme/components/HomeHero/index.tsx' : renderFile, zh.split('\n')[0]]], intent, concern));

const promptFile = 'website/theme/components/HomeContent/installPrompts.ts', prompts = literals(promptFile, 'AGENT_PROMPTS');
const splitPrompt = t => t.split(/\n\n(?=\d\. |只汇报|汇报|Only report|Report whether)/);
const chunks = [splitPrompt(prompts.zh.text), splitPrompt(prompts.en.text)];
// Keep earlier review IDs stable; G07 is the newly added PATH repair step.
const promptIds = ['G01', 'G02', 'G03', 'G04', 'G07', 'G05', 'G06'];
if (chunks[0].length !== promptIds.length || chunks[1].length !== promptIds.length) throw new Error('Update the bilingual prompt review mapping.');
chunks[0].forEach((z, i) => add(promptIds[i], 'Agent 安装提示词', `提示词段落 ${i + 1}`, z, chunks[1][i], [[promptFile, z.split('\n')[0]]], ['界定安装并验证的请求。', '安装或更新 Skill，完整保留脚本与参考。', '区分 CLI 未安装与 PATH 缺失，避免重复安装。', '处理缺失系统依赖与需要额外确认的命令。', '修复 PATH，分别验证当前会话与新终端。', '通过直接命令运行安装验证。', '汇报路径验证结果，并限定本次执行范围。'][i], '这是可执行安装指令，不是对外卖点；首页与快速开始复用同一份内容，并通过一致性检查。'));

function markdownBlocks(file) {
  const lines = read(file).split('\n'), result = [];
  let pending = [], start = 0, code = false, front = false;
  const flush = kind => { if (pending.length) result.push({ text: pending.join('\n'), line: start + 1, kind }); pending = []; };
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (i === 0 && line === '---') { front = true; continue; }
    if (front) { if (line === '---') front = false; else if (line.startsWith('description: ')) result.push({ text: line.slice(13), line: i + 1, kind: '页面描述' }); continue; }
    if (line.startsWith('```')) { if (!code) { flush('正文'); start = i; } pending.push(line); if (code) flush('命令或提示词'); code = !code; continue; }
    if (code) { pending.push(line); continue; }
    if (!line.trim()) { flush('正文'); continue; }
    if (/^import |^<\/?(?:Tabs|Tab|div|details)\b/.test(line)) { flush('正文'); const label = line.match(/label="([^"]+)"/); if (label) result.push({ text: label[1], line: i + 1, kind: '选项标签' }); continue; }
    if (line === ':::') { flush('正文'); continue; }
    if (/^#{1,6} |^[-\d]+[.)]? |^:::|^<summary>/.test(line)) { flush('正文'); result.push({ text: line.replace(/^<summary>|<\/summary>$/g, ''), line: i + 1, kind: line.startsWith('#') ? '标题' : line.startsWith('<summary>') ? '折叠入口' : '条目' }); continue; }
    if (!pending.length) start = i;
    pending.push(line);
  }
  flush('正文'); return result;
}
for (const [prefix, route, section] of [['D', 'download.md', '下载页全文'], ['Q', 'guide/index.mdx', '快速开始全文']]) {
  const files = ['zh', 'en'].map(l => `website/docs/${l}/${route}`), data = files.map(markdownBlocks);
  if (data[0].length !== data[1].length) throw new Error(`Bilingual block count mismatch: ${route} ${data.map(x => x.length)}`);
  data[0].forEach((z, i) => {
    const e = data[1][i];
    add(`${prefix}${String(i + 1).padStart(2, '0')}`, section, z.kind, z.text, e.text, files.map((f, n) => [f, data[n][i].text.split('\n')[0]]), z.kind === '命令或提示词' ? '提供可执行的安装/配对/示例指令。' : z.kind === '折叠入口' ? '将手动方式作为备选入口。' : z.kind === '页面描述' ? '搜索与分享摘要。' : '说明获取、安装、验证或接入步骤。', '操作性说明；不能据此将手动执行命令当成主要产品体验。');
    rows.at(-1).sources = files.map((file, n) => ({ file, line: data[n][i].line }));
  });
}

if (new Set(rows.map(r => r.id)).size !== rows.length) throw new Error('Duplicate copy ID');
writeFileSync(path.join(base, 'copy-inventory.json'), JSON.stringify({ date: '2026-10-03', status: 'Awaiting copy review; only Agent-first installation changes implemented', sourceHashes, entries: rows }, null, 2) + '\n');
const lead = readFileSync(path.join(base, 'review-introduction.md'), 'utf8');
let md = lead + `\n\n本清单共 **${rows.length} 条**，中英文使用同一个编号；技术指令按完整语义段保留，不截断、不省略。\n`;
for (const section of [...new Set(rows.map(r => r.section))]) {
  md += `\n## ${section}\n`;
  for (const row of rows.filter(r => r.section === section)) {
    md += `\n### ${row.id} · ${row.label}\n\n**中文原文**\n\n${row.zh.split('\n').map(l => '> ' + l).join('\n')}\n\n**English**\n\n${row.en.split('\n').map(l => '> ' + l).join('\n')}\n\n表达意图：${row.intent}\n\n审阅备注：${row.concern || '暂未标出具体语言问题，仍待用户审阅。'}\n\n状态：${row.status}。\n`;
    if (row.previous) md += `\n本轮调整前：${row.previous.zh ?? '无该标签'} / ${row.previous.en ?? 'No previous label'}\n`;
    md += '\n来源：' + row.sources.map(s => `[${s.file}${s.line ? ':' + s.line : ''}](../../../${s.file})`).join('，') + '\n';
  }
}
writeFileSync(path.join(base, 'copy-review.md'), md);
console.log(`Exported ${rows.length} bilingual entries to assets/marketing/copy-review/copy-review.md`);
