---
name: run-ios-app
description: Build storyveApp and launch it in the iOS Simulator for manual testing. Use whenever asked to run, build, launch, or test the iOS app in ui/storyveApp.xcodeproj.
---

# Run storyveApp in the iOS Simulator

Builds the `storyveApp` scheme and installs/launches it on a Simulator
device so the user can test it manually. No test target exists in this
repo — this is the only way to exercise the app.

## 1. Pick a Simulator device

Prefer an already-booted device; otherwise boot one.

```bash
SIM_ID=$(xcrun simctl list devices | grep -m1 "(Booted)" | grep -oE '[0-9A-F-]{36}')

if [ -z "$SIM_ID" ]; then
  SIM_ID=$(xcrun simctl list devices available | grep -m1 "iPhone 17 (" | grep -oE '[0-9A-F-]{36}')
  xcrun simctl boot "$SIM_ID"
fi

open -a Simulator
```

## 2. Build

Run from the `ui/` directory (contains `storyveApp.xcodeproj`).

```bash
cd ui
xcodebuild -project storyveApp.xcodeproj -scheme storyveApp \
  -destination "id=$SIM_ID" -configuration Debug build \
  2>&1 | tee /tmp/storyve_build.log | grep -E "BUILD SUCCEEDED|BUILD FAILED|error:"
```

If it fails, check `/tmp/storyve_build.log` for the full error — common
causes are stale SPM package resolution (`File > Packages > Reset
Package Caches` in Xcode, or delete
`~/Library/Developer/Xcode/DerivedData/storyveApp-*`) or a simulator
runtime mismatch with the project's deployment target.

## 3. Locate the built .app

DerivedData paths include a machine-specific hash, and old/stale hash
directories can accumulate — so find it rather than hardcoding it, and
pick the most recently built match. The path must match exactly
`Build/Products/Debug-iphonesimulator/storyveApp.app` (not
`Index.noindex/...`, which is a non-runnable indexing copy).

```bash
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -maxdepth 6 \
  -path "*/Build/Products/Debug-iphonesimulator/storyveApp.app" \
  -print0 | xargs -0 ls -dt | head -1)
```

## 4. Install and launch

```bash
xcrun simctl install "$SIM_ID" "$APP_PATH"

BUNDLE_ID=$(defaults read "$APP_PATH/Info.plist" CFBundleIdentifier)

xcrun simctl launch "$SIM_ID" "$BUNDLE_ID"
```

The Simulator window is now showing the running app, ready for manual
interaction.

## Optional: capture console output

Useful when debugging a crash or silent failure instead of manual
testing. Runs in the foreground — use `run_in_background` if using the
Bash tool.

```bash
xcrun simctl terminate "$SIM_ID" "$BUNDLE_ID" 2>/dev/null
xcrun simctl launch --console-pty "$SIM_ID" "$BUNDLE_ID"
```

## Optional: screenshot

```bash
xcrun simctl io "$SIM_ID" screenshot /tmp/storyve_screenshot.png
```

## Notes

- Reinstalling wipes nothing by default (`simctl install` preserves
  the app's container/SwiftData store); use `xcrun simctl uninstall
  "$SIM_ID" "$BUNDLE_ID"` first if a clean-slate test is needed (e.g.
  after changing how `Book.epubPath`/`coverPath` are stored/resolved).
- Two-finger trackpad scroll does **not** reliably drive paginated
  nested scroll views (e.g. the EPUB reader) in Simulator — use a
  click-drag-release swipe instead when testing gestures manually.
