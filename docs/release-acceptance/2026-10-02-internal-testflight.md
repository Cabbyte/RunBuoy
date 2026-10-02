# Internal TestFlight acceptance, 2026-10-02

The user accepted the previously reported unresolved accessibility risks, required
manual large-text, VoiceOver and critical-operation checks before the remaining
build checks, and then reported: “已经人工测试，没问题”. This is a user-reported
manual pass; it is not an independently observed VoiceOver recording.

The prepared app was built successfully on MacBook16 with Xcode 27 beta for an
isolated iPhone 17 / iOS 27 simulator using preview fixtures and normal animations.
The user did not separately identify the device used for acceptance. In particular,
this record does not claim human verification on the CI runtime, iOS 26.5.

The accepted iOS tree is `e28c2148089aff4804ac7ed083ea7378584e1f21`, from candidate
`663a71082f3a774a97800fa556d848e26ced5f5d`, identical to the retained first layout
experiment. The second experiment was reverted. No further iOS source or test
assertion change is included in this acceptance.

The [machine-readable policy](2026-10-02-internal-testflight.json) expires on
2026-10-03 at 00:00 UTC. It allows only the documented native audit signatures for
Active, Settings and the Form probes, the existing core audit's Dynamic Type
failure, and the isolated `3 mo. ago` OCR substitution. Native Dynamic Type,
clipping and contrast reports remain unresolved; nil elements cannot be mapped
to distinct controls. They are accepted risks, not established false positives.
The core audit can stop at Active, so subsequent core-audit pages are not claimed
as automatically audited. Normal navigation tests and user acceptance provide
separate evidence.

All UI tests still run, with unchanged assertions and diagnostic callbacks returning
false. CI exports the original xcresult and attachments. The external gate checks
all assertion failures, the full expected test list, native evidence, source tree,
runtime and successful system-size restoration. It reports actual passes separately
from user-accepted failures. Unknown failures, skipped/missing tests, build errors,
and controller errors block CI. Unit tests, iOS 18 smoke, privacy, archive and every
other CI job remain required. The existing TestFlight gate still requires successful
push CI for the exact release SHA on an approved branch. This exception authorizes
an internal TestFlight build only, not public App Store release or an accessibility
conformance claim.
