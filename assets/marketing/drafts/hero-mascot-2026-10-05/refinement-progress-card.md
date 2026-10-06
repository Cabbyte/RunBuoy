# Progress card refinement

Status: visual draft, not implemented or deployed. Generated with built-in `image_gen.imagegen`.

User feedback: replace the prominent floating card with the top detailed progress card, and reduce small text across all pages. Continue the existing Chinese-only website scope.

Design rule for the future implementation: remove redundant footnotes and repeated metadata; enlarge essential supporting text; use the enlarged progress card to expose task details instead of expecting users to read small text in the phone screenshot. Preserve required preview/example labels. Do not modify native app UI as part of website typography work.

[Revised concept](refinement-progress-card.png)

## Exact prompt

Use case: ui-mockup / precise layout refinement. Create ONE revised Chinese RunBuoy desktop homepage hero effect mockup at 1600 x 960, maintaining the exact reference layout and brand identity. Image 1 is the previous full hero, the edit target. Image 2 is user's crop identifying the black floating card to replace. Image 3 is original real website reference showing the complete TOP featured task progress card. Preserve the friendly red-white 3D buoy mascot, face, proportions, soft blue water base, left copy/right phone composition, navigation and white/ice-blue palette of image 1. Keep ample whitespace and premium typographic polish.

User change A: REMOVE the black floating Live Activity card entirely. Instead promote the top detailed task-progress card from the phone UI to a larger floating WHITE card with a restrained light-blue outline/glow and soft shadow, about 460px wide x 205px tall in this canvas. Position in the lower-right foreground so it overlaps the lower phone area but does not cover mascot's face, headline, CTA or its main body. It represents the top featured task from the app, not a new invented feature. Strong readable hierarchy, real detailed blue-cyan progress bar. Card text must be LARGE and reduced to essential data: first row '大模型微调 · 第 8 轮'; second row '训练第 8 / 10 个 Epoch' with bold '78%' right-aligned; thick blue-to-cyan progress bar at 78%; third row '7,800 / 10,000 steps'. Omit redundant machine name and timestamps on the floating card, no tiny metadata. 24px task title, 21px stage, 34px percentage, 18px steps on 1600px canvas. White clean native appearance like the TOP card in reference3. Keep original phone UI grounded in reference; phone UI can remain secondary but the enlarged progress card must be clearly readable.

User change B: Reduce small text across the page: remove English eyebrow completely, remove the long technical requirements footnote under buttons, remove repetitive captions. Keep just a single unobtrusive but legible 18px '新版预览 · 示例数据' near bottom-right, no microprint. Keep left main headline exactly two lines '扫一眼，' then blue '掌握任务的进展。'. Body only two generous lines at 25-27px: '安装交给 Agent，状态带到 iPhone。' and '阶段、结果随手看，重要消息随身收。'. Buttons 'App Store 下载' and '连接我的电脑' with 24px labels and 64px height. Navigation 20px. No added explanatory blocks, no fake badges or additional copy. Slightly recenter headline vertically after removing eyebrow. Clear hierarchy, no overlapping text, no small-print clutter. This is a visual draft only; preserve accurate Chinese words, not random glyphs. Date anchor 2026-10-05 but no dates shown.
