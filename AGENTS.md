# AIMemo Agent Guide

This guide is for coding agents working in this repository. Follow it before finishing any task.

## Language

- Talk with the user in Chinese unless they explicitly ask for another language.
- Keep status updates short and concrete.

## Project Basics

- AIMemo currently keeps the Flutter app as the desktop maintenance line for macOS, Windows, and Web preview.
- New iOS and Android mobile work should be native-first: iOS uses SwiftUI, Android uses Kotlin + Jetpack Compose + Material 3.
- The mobile design source of truth is `docs/mobile-design-guidelines.md`.
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
- New iOS/Android V1 focuses on the cloud account mode: tasks, tags, summary generation, summary history, and My account page.
- Do not design native mobile V1 around local-only mode, custom model API keys, or offline edit sync unless explicitly requested.
- Mobile top-level navigation should use the "任务 / 总结" switch with a top-right "我的" entry. Do not reintroduce the old bottom four-tab Flutter mobile layout.

## UI Style Expectations

- For new iOS/Android work, follow `docs/mobile-design-guidelines.md` first.
- Keep the summary generation controls compact; avoid wrapping small control groups in large card-like frames unless there is a clear need.
- Controls in the same row should share the same visual language. For example, the summary period selector and date range picker should both use a 40px height, 6px radius, `_border` outline, `_ink` text, and similar icon sizing.
- Date range selection must look clickable. Use a compact outlined button with a calendar icon instead of plain text.
- Do not add explanatory helper text below obvious controls when the same meaning is already communicated by labels, icons, or tooltips.
- Keep the template module lightweight: use a compact title row for expand/collapse, and avoid an outer card frame around the collapsed template header.
