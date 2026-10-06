# RunBuoy Chinese homepage Figma prototype

Status: completed and reviewed on 2026-10-06 in the selected account jax45@akademe.edu.pl.

## Deliverables

- [Editable Figma file](https://www.figma.com/design/XeFw4ascc1qPtA3fIbcXvS?node-id=6-70)
- [Desktop prototype](https://www.figma.com/proto/XeFw4ascc1qPtA3fIbcXvS?node-id=9-84&starting-point-node-id=9%3A84)
- [Mobile prototype](https://www.figma.com/proto/XeFw4ascc1qPtA3fIbcXvS?node-id=9-231&starting-point-node-id=9%3A231)
- Desktop composition: 6:70, 1440 × 4697. Mobile: 6:198, 390 × 4605.
- Playable viewports: 9:84 (1440 × 960), 9:231 (390 × 844).
- Full canvas reviews: desktop-review.png, mobile-review.png.
- Live interaction evidence: desktop-manual-open.jpg, mobile-copy-feedback.jpg, mobile-prompt-open.jpg.

The desktop and mobile prototypes were exercised in the Figma player: installation scroll targets, prompt expansion/collapse, copied feedback and manual installation expansion. The copied state simulates feedback; it does not write to the clipboard. No website deployment was performed in this iteration.

## Scope

- Desktop homepage: 1440px wide, vertically scrollable prototype.
- Mobile homepage: 390px wide, vertically scrollable prototype.
- Sections: centered hero, tasks and messages, Agent/ChatGPT integration, Agent-first installation, concise privacy closing.
- Native editable text, buttons, navigation, task cards and layout containers. Reusable button and accordion states. Artwork is a discrete image asset. Real app/plugin screenshots are separate product illustrations, not whole-page backgrounds.
- Reference area includes the approved centered hero and three generated section references, clearly separated from editable deliverables.
- Product language: Chinese. No 示例数据 / 新版预览 marketing footnotes. Retain useful product facts in readable text, including read-only/private-preview boundaries for ChatGPT.

## Interactions

1. 连接我的电脑: scroll to installation section.
2. 复制安装提示词: demonstrate copied state, then return to default. This is a prototype interaction; actual clipboard access belongs to website implementation.
3. 查看完整提示词: expand/collapse prompt content sourced from website/theme/components/ChineseHome/installPrompts.ts.
4. 手动安装与配对: collapsed by default, expandable, with install/pair/demo steps.
5. App Store download: link to https://apps.apple.com/cn/app/runbuoy/id6795591930.

## Review references

- [Centered hero](../../drafts/hero-mascot-2026-10-05/refinement-centered-large-card-v3.png)
- [Homepage section references](../../drafts/homepage-sections-2026-10-06/README.md)
- [Independent transparent mascot](assets/mascot-transparent.png)

## Asset generation

Tool: built-in image_gen.imagegen, transparent_background: true.
Source: assets/marketing/sources/generated/buoy-calm-water-v1.png.
Prompt: Extract the exact RunBuoy mascot from this reference as a standalone reusable transparent PNG asset. Preserve exact glossy red-white buoy shape, red ball antenna on silver stem, black oval eyes, pink cheeks, smiling mouth, scalloped cyan blue water base. Front view as source, complete antenna and water base, centered with tight but comfortable 8% transparent padding. Remove ALL surrounding background, horizon, pool reflections and distant ripples. Keep just mascot and its immediate sculpted blue water base, no white backdrop, no text, no phone, no additional props. Genuine alpha transparency. High-quality crisp edges, original gentle 3D lighting, 1024x1024 canvas.

## Acceptance

- Both viewport compositions have editable native text and semantic layer structure; generated full-page references remain outside deliverable frames.
- All prototype targets resolve; default manual installation is collapsed; copied feedback and prompt/manual expansion states exist.
- Fonts verified against product typography and available Figma fonts.
- Full-frame screenshots inspected for clipping, overlap, gaps and reference fidelity.
- File URL, node IDs, component/state IDs, and validation exports saved alongside this README after execution.


## Validation results

- 30 native prototype transitions; 0 unresolved destinations.
- Desktop: 127 descendants, including 70 native text nodes. Mobile: 128 descendants, including 71 text nodes.
- Chinese font: Noto Sans SC, an available Figma fallback for unavailable PingFang. Brand: SF Pro.
- Full-frame screenshots checked after layout repairs. Initial screenshots retained as draft evidence.
- References remain separate from editable compositions. Product screenshots are discrete image layers; mobile ChatGPT is an editable focused summary based on the product screenshot.
- Node/component inventories: foundations-state.json, composition-state.json, prototype-state.json. Final interaction graph: validation.json.
- Authoring scripts: foundations.js → compose.js → repair-layout.js → prototype.js. Scripts use recorded IDs and must be adapted before reuse in a different file; do not blindly rerun creation scripts in this file.

## Water asset generation

Tool: built-in image_gen.imagegen. Asset: assets/water-background.png.
Direction: derive an empty pale-blue water scene from the mascot reference, remove mascot, phones, objects and text; retain soft ripples in the lower center and a white upper area. This is a reusable standalone background layer.
