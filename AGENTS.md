# Agent Guide

This guide is for coding agents working in this repository. Follow it before finishing any task.

## Language

- Talk with the user in Chinese unless they explicitly ask for another language.
- Keep status updates short and concrete.

## Required Workflow

- Before editing, check `git status --short` and do not revert user changes.
- Use `rg` / `rg --files` for search.
- Use `apply_patch` for manual file edits.
- Keep changes scoped to the user request.
- Update `README.md` when behavior, setup, workflow, templates, API shape, or user-facing features change.
- Commit completed work to git. Do not leave finished work uncommitted unless the user explicitly says not to commit.

## Current App Direction

- Current mobile app work is focused on the Flutter app.
- For iOS/Android mobile features, prefer `lib/src/mobile/`, `lib/src/mobile/mobile_components.dart`, and `lib/src/mobile/mobile_theme.dart`.
- Use `docs/product-document-app.md`, `docs/mobile-component-system.md`, and `assets/prototypes/` as the mobile product and visual references.
- Do not modify `native/android/` for current mobile feature work unless the user explicitly asks for the paused native Android Compose app.

## Verification

Run the checks that match the files touched:

- Flutter changes:
  - `flutter analyze`
  - `flutter test`
  - For iOS/Android app changes, update the running simulator/emulator after the change and verify the affected screen when practical.
  - When iOS/Android Debug/Test app flows need the local backend, do not start it proactively; tell the user to run `cd backend && npm run dev`. iOS Simulator uses `http://127.0.0.1:8787` and Android Emulator uses `http://10.0.2.2:8787`.

- Native Android changes:
  - Run the relevant Gradle unit or UI checks.
  - Launch the app on an Android emulator for user-facing UI changes.
  - The local Android SDK is at `~/Library/Android/sdk`; `~/.zshrc` should export `ANDROID_HOME`, `ANDROID_SDK_ROOT`, and add `platform-tools` plus `emulator` to `PATH`.
  - If an emulator is needed, check availability with `adb devices` and `emulator -list-avds`.

- Native iOS changes:
  - Run the relevant Xcode build or tests.
  - Launch the app in the iOS Simulator for user-facing UI changes.

- Backend changes:
  - Run the relevant build, lint, or test commands for the backend package.

- Documentation-only changes:
  - Review the rendered Markdown when practical.

## Git Rules

- Include documentation updates in the same commit when they describe the change.
- Review `git diff` before committing.
- Use a concise commit message in English, for example:
  - `Update agent workflow guide`
  - `Fix Android section toggle`
  - `Improve test coverage`
- Never run destructive git commands such as `git reset --hard` or `git checkout --` unless the user explicitly requests them.

## Secrets

- Store real credentials, API keys, tokens, and private certificates only in approved secure storage.
- Do not write real secrets to source files, SQLite, README, `.env`, tests, fixtures, logs, or git.
- Use placeholders or documented environment variables in examples.

## UI Work

- Follow the existing design system and platform conventions in the touched area.
- Keep text readable, controls accessible, and tap targets large enough for touch interfaces.
- Verify user-facing layout changes on the relevant screen sizes or devices when practical.
