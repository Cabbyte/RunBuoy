# Phone frame asset

Generated with built-in ImageGen; transparent background enabled. The screen and exterior are transparent. Original output copied byte-for-byte into the project; no raster edits.

## Prompt

Use case: product-mockup, transparent reusable web asset.
Generate exactly one front-facing modern iPhone hardware frame only, portrait device. Reference 1 gives desired refined website material style only; reference 2 is the screen screenshot that will later be inserted by HTML, DO NOT include its contents.
Object: very thin dark titanium outer chassis and polished black inner bezel, softly rounded modern iPhone corners, tiny realistic edge highlights and side button silhouettes. Perfectly orthographic front view, vertical, zero tilt, zero perspective, symmetrical. Overall hardware device width / height approximately 0.48. Display opening width about 92% of device width, height about 96% of device height, rounded corners.
CRITICAL: BOTH the entire interior display opening AND everything outside the device are genuinely fully transparent alpha. This is a hollow frame shaped cutout PNG, not a complete phone. No glass across screen opening, no wallpaper, no opaque fill, no painted checkerboard. No dynamic island, no camera, no notch, no status bar, no screen UI, no text, no logo. The HTML screenshot supplies all screen content separately.
Canvas portrait approximately 768x1600, tightly frame the hardware with only 2% external transparent margins. Clean sharp antialiased edges; professional softly lit black / dark titanium material, subtle real metal detailing, no cast shadow outside the frame.

## Placement measurements

- PNG: 870 × 1808 RGBA.
- Alpha nonzero bounding box: x=19, y=37, width=830, height=1716 (includes antialiasing and side buttons).
- Central display opening: x≈69, y≈75 through x≈800, y≈1713; width≈732, height≈1639.
- Place screenshot underneath frame at left 7.93%, top 4.15%, width 84.14%, height 90.65% of full image canvas. Let frame overlap screenshot edges by 1–2px to prevent a hairline gap.
- Rounded screen corners: approximately 95px radius in source coordinates; use rounded clipping proportionally.
- Screenshot aspect ratio 660/1434 differs slightly from generated opening; object-fit: cover crops about 3% horizontally. Prefer this over stretching the screenshot.
- Center alpha measured 0, exterior alpha 0, frame reaches alpha 255. No UI, camera notch, dynamic island or text is included.

Raw generation: `/Users/timli/.codex/generated_images/01a11155-6ecd-78c0-814e-4a5baa1073f6/exec-e18b746f-f476-48b7-af33-a525fa3306dd.png`.

Runtime asset: `website/docs/public/marketing/zh-Hans/homepage/phone-frame.png`.
