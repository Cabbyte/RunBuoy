# Machines — selected first concept

final result: passed

## Source and viewport

- Selected visual: `output/machines-option-1/selected-reference.png`, copied from the first displayed Image Gen result, `exec-ea383642-9d00-4a53-b3a0-6b5833c7dfe8.png`.
- Source: 853 × 1844 pixels, displayed at 390 pt wide.
- Implementation: native SwiftUI on iPhone 17e, 390 × 844 pt, 3× density (1170 × 2532 pixels), iOS 27.0.
- State: English, light appearance, default Large content size, `loaded` fixture with the same two machines, long CI name, and 3-month confirmation dates.
- The reference omits OS chrome. Native status and navigation bars remain. Content comparisons align the start of the summary rather than treating the native bars as design drift.

## Comparison history

### Iteration 1

Evidence: `output/machines-option-1/iteration-1-light.png`, compared together with the reference in `output/machines-option-1/comparison-iteration-1.html` at 390 pt wide in Codex's in-app browser. Focused content and full-screen pairs are included.

- [P2] The 15 pt metadata and 20 pt vertical row padding make the group about 30 pt taller than the selected design. Change to 13 pt semantic footnote text and 16 pt row padding.
- [P2] Content uses 20 pt side insets while the native title uses 16 pt. Use the same 16 pt inset for the summary, action, list and footer.
- No content, state, symbol, navigation or primary-action mismatch observed.

### Iteration 2

Evidence: `output/machines-option-1/implemented-light.png`, viewed beside the source in `output/machines-option-1/comparison.html`. The complete combined comparison is saved as `output/machines-option-1/comparison-final.png`; it includes both the aligned content regions and the full screens.

- [Resolved P2] Metadata now uses semantic 13 pt footnote text and rows use 16 pt vertical padding. The summary, button, group and footer match the source's content density and vertical rhythm.
- [Resolved P2] The title, summary, primary action, group and footer share the native 16 pt page inset.
- No remaining P0, P1 or P2 visual mismatch observed in the normalized comparison.

## Fidelity review

| Area | Observed result |
| --- | --- |
| Typography | Native system fonts; 20 pt semibold summary, 17 pt headline names and action, 13 pt metadata and footer. Long names wrap without truncation or fragmented metadata columns. |
| Layout | One text-only summary, one primary action, one grouped list. No duplicate list heading. Both rows share the same text column; the divider begins at that column. |
| Spacing | 16 pt page and row insets, 48 pt icon tiles, 16 pt icon-to-text gap, 24 pt summary-to-action gap and 28 pt action-to-list gap. |
| Colors | Existing RunBuoy canvas, accent and secondary text tokens are retained. The native grouped surface adapts to light and dark appearance. |
| Symbols | Native SF Symbols remain crisp. Neutral computer tiles have no status badge; confirmation remains readable in text. |
| Copy and state | The reference's two machine names, platform, update status, relative dates and confirmation state are present. The boundary explanation appears once below the list. English and Simplified Chinese are localized. |

Native status/navigation chrome is retained rather than baked into an image. Minor differences in the source's rendered SF Symbol shape, raster color and title shape are accepted; this is a native implementation, not a pixel-identical bitmap recreation.

## Runtime and behavior verification

- Debug iOS Simulator build passed after the final spacing and typography changes.
- Three existing UI tests passed, zero failed: `testMachineNameIsReadOnlyAndMatchesServer`, `testManualPairingCodeCanBeConfirmed`, and `testMachineStopReceivingAndRevokeHaveDistinctDestructiveConfirmations`. Result bundle: `/tmp/runbuoy-machines-option-1-tests.xcresult`.
- English light appearance at default Large content size was visually compared with the selected reference.
- Accessibility Medium content size was inspected at the top and bottom of the screen. Icons move above the text, long names remain complete, and the footer is reachable by scrolling. Evidence: `output/machines-option-1/implemented-accessibility.png` and `output/machines-option-1/implemented-accessibility-bottom.png`.
- Simplified Chinese in dark appearance was visually inspected with the same long machine name. No overlap or clipping observed. Evidence: `output/machines-option-1/implemented-zh-dark.png`.
- `git diff --check` and both localization files' `plutil -lint` checks passed.
- Simulator appearance and text size were restored to light and Large after the checks.

Scope: local V3 worktree and simulator fixtures. Physical-device and TestFlight verification were not performed for this change.
