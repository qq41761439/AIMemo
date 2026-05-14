# AIMemo Agent Guide

This guide is for coding agents working in this repository. Follow it before finishing any task.

## Language

- Talk with the user in Chinese unless they explicitly ask for another language.
- Keep status updates short and concrete.

## Project Basics

- AIMemo currently keeps the Flutter app as the desktop maintenance line for macOS, Windows, and Web preview.
- New iOS and Android mobile work should be native-first: iOS uses SwiftUI, Android uses Kotlin + Jetpack Compose + Material 3.
- The mobile app product, page, visual, platform implementation, state feedback, accessibility, and acceptance source of truth is `docs/product-document-app.md`.
- The main Flutter desktop UI is in `lib/src/features/home_page.dart`.
- Persistent macOS data is handled by `lib/src/services/app_database.dart`.
- Web preview data is handled by `lib/src/services/in_memory_memo_store.dart`.
- Summary prompt templates are rendered by `lib/src/services/template_renderer.dart`.

## Required Workflow

- Before editing, check `git status --short` and do not revert user changes.
- Use `rg` / `rg --files` for search.
- Use `apply_patch` for manual file edits.
- Keep changes scoped to the user request.
- Update `README.md` when behavior, setup, workflow, templates, API shape, or user-facing features change.
- Commit completed work to git. Do not leave finished work uncommitted unless the user explicitly says not to commit.

## Verification

Run the checks that match the files touched:

- Flutter desktop/Web changes:
  - `flutter analyze`
  - `flutter test`

After verification passes for Flutter desktop app changes, build and open the macOS Release app:

```bash
flutter build macos
pkill -x aimemo || true
sleep 1
open build/macos/Build/Products/Release/aimemo.app
```

Always close the old app before opening the newly built app, otherwise macOS may show the previous version.

- Native Android changes:
  - Run the relevant Gradle unit/UI checks for the native Android project once it exists.
  - Launch the app on an Android emulator for user-facing UI changes.
  - The local Android SDK is at `~/Library/Android/sdk`; `~/.zshrc` should export `ANDROID_HOME`, `ANDROID_SDK_ROOT`, and add `platform-tools` plus `emulator` to `PATH`.
  - This machine has `Pixel_10_Pro` and `Pixel_8` AVDs. Check availability with `adb devices` and `emulator -list-avds`; if no device is running, prefer `emulator -avd Pixel_10_Pro`.
  - For native Android UI verification, run from `native/android`: `./gradlew installDebug`, then `adb shell am force-stop com.aimemo.app` and `adb shell am start -n com.aimemo.app/.MainActivity`.

- Native iOS changes:
  - Run the relevant Xcode build/tests for the native iOS project once it exists.
  - Launch the app in the iOS Simulator for user-facing UI changes.

Legacy Flutter iOS/Android targets are not the new mobile product direction. Only run Flutter mobile verification when intentionally touching the old Flutter mobile targets.

If intentionally touching the legacy Flutter iOS target, also open the iOS Simulator and launch the app there:

```bash
open -a Simulator
flutter run -d ios
```

If multiple simulators are available, use `flutter devices` and run the app on an available iPhone simulator.

## Git Rules

- Include documentation updates in the same commit when they describe the change.
- Review `git diff` before committing.
- Use a concise commit message in English, for example:
  - `Update agent workflow guide`
  - `Improve summary period templates`
  - `Fix summary generation client`
- Never run destructive git commands such as `git reset --hard` or `git checkout --` unless the user explicitly requests them.

## GitHub Actions

- When completed work should update the Windows installer, push `main` to `origin`.
- Trigger the Windows installer workflow by pushing a new `v*` tag, because `.github/workflows/build-windows.yml` runs on version tags.
- If the current version tag already exists, ask before bumping `pubspec.yaml` or creating a new tag.

## Model Service

- Users can configure custom OpenAI-compatible model services inside the Summary page model settings.
- Custom model mode calls `{baseUrl}/chat/completions` directly from the desktop app.
- Store real model API keys in system secure storage only; do not write real API keys to SQLite, README, `.env`, tests, or git.
- `mode`, `baseUrl`, and `model` may be saved in local `app_settings`.
- Official AIMemo hosted model availability depends on backend configuration, account state, and quota. Show clear unavailable, unauthenticated, quota, network, and generation error states.

## Current Product Expectations

- Tags with no non-deleted task associations should not be shown.
- When a task is associated with a tag, that tag should move to the front.
- Summary periods support day, week, month, year, and custom date ranges.
- Daily and weekly templates should stay simple: completed work and next plan.
- Monthly and yearly templates can include richer review structure.
- Custom summary templates should behave like weekly summaries for ranges of 7 days or less, and like monthly summaries for longer ranges.
- New iOS/Android App work follows `docs/product-document-app.md`: login/register, onboarding, Tasks, Task edit, optional Task detail, Profile, Settings, Summary entry, Summary result, and Summary history.
- Do not design native mobile App work around local-only mode, custom model API keys, or offline edit sync unless explicitly requested.
- Do not continue the old mobile top-level "任务 / 总结" switch as the product source of truth; migrate App UX toward `docs/product-document-app.md`.

## UI Style Expectations

- For new iOS/Android App work, follow `docs/product-document-app.md` first.
- Use the mobile App style from that document: white background, rounded cards, soft shadows, purple gradient buttons, internationalized readable typography, and 390 x 844 pt as the reference portrait canvas.
- Use the font sizes and touch targets specified in `docs/product-document-app.md`, including 22 pt page titles, 16 pt section text/buttons, 14 pt tags, 12 pt subtext, buttons at least 44 pt high, and tags 24-28 pt high.
- Summary UX should include the AI Summary entry, report type selection, generated result page, dialog-style modification input, confirmation, Copy / Share, and in-place expandable history list.
