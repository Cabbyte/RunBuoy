#!/bin/bash
# Repeatable local fixture capture. Run from any directory on a Mac with Xcode.
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
locale="${1:?Usage: SIMULATOR_UDID=... capture.sh zh-Hans|en-US active-runs|history|run-detail|pairing|data|lock-screen}"
screen="${2:?Choose a screen}"
sim="${SIMULATOR_UDID:?Set the dedicated simulator UDID; never use an unspecified booted device}"
case "$locale" in
  zh-Hans) scenario=showcase; apple_languages='(zh-Hans)'; apple_locale=zh_CN ;;
  en-US) scenario=showcaseEnglish; apple_languages='(en)'; apple_locale=en_US ;;
  *) printf 'Unsupported locale\n' >&2; exit 1 ;;
esac
args=(-runbuoy-ui-testing -runbuoy-ui-scenario "$scenario" -AppleLanguages "$apple_languages" -AppleLocale "$apple_locale")
case "$screen" in
  active-runs) ;;
  history) args+=(-runbuoy-ui-preview-tab history) ;;
  run-detail) args+=(-runbuoy-ui-preview-run 018f0d8a-8c0a-7000-8000-000000000101) ;;
  pairing|data) args+=(-runbuoy-marketing-screen "$screen") ;;
  lock-screen) args+=(-runbuoy-ui-url runbuoy://demo/notification -runbuoy-marketing-activity 2) ;;
  *) printf 'Unsupported screen\n' >&2; exit 1 ;;
esac
xcrun simctl status_bar "$sim" override --time 09:41 --dataNetwork wifi --wifiMode active --wifiBars 3 --batteryState charged --batteryLevel 100
xcrun simctl launch --terminate-running-process "$sim" dev.runbuoy.app "${args[@]}"
if [ "$screen" = lock-screen ]; then
  printf '\nIn Device Hub, select this simulator, then Controls > Lock.\n'
  printf 'Confirm the Live Activity is RUNNING (72%%), with the correct widget language.\n'
else
  printf '\nVerify the requested screen is visible and fully loaded.\n'
fi
read -r -p 'Press Return to capture the verified screen: ' _capture_confirm
output="$repo_root/assets/marketing/sources/screenshots/$locale/$screen.png"
mkdir -p "$(dirname "$output")"
xcrun simctl io "$sim" screenshot "$output"
printf 'Saved %s\n' "$output"
