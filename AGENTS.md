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

## Verification

Run the checks that match the files touched:

- Flutter changes:
  - `flutter analyze`
  - `flutter test`

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
