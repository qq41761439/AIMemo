# AIMemo Agent Guide

This guide is for coding agents working in this repository. Follow it before finishing any task.

## Language

- Talk with the user in Chinese unless they explicitly ask for another language.
- Keep status updates short and concrete.

## Project Basics

- AIMemo is a Flutter desktop app with a Node/Fastify LLM proxy.
- The main Flutter UI is in `lib/src/features/home_page.dart`.
- Persistent macOS data is handled by `lib/src/services/app_database.dart`.
- Web preview data is handled by `lib/src/services/in_memory_memo_store.dart`.
- Summary prompt templates are rendered by `lib/src/services/template_renderer.dart`.
- The LLM proxy is in `server/server.js`.

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
- Server changes:
  - `cd server && node --check server.js`
- Dependency or security-sensitive server changes:
  - `cd server && npm audit --audit-level=moderate`

After verification passes for app changes, build and open the macOS Release app:

```bash
flutter build macos
pkill -x aimemo || true
sleep 1
open build/macos/Build/Products/Release/aimemo.app
```

Always close the old app before opening the newly built app, otherwise macOS may show the previous version.

## Git Rules

- Include documentation updates in the same commit when they describe the change.
- Review `git diff` before committing.
- Use a concise commit message in English, for example:
  - `Update agent workflow guide`
  - `Improve summary period templates`
  - `Fix summary generation proxy`
- Never run destructive git commands such as `git reset --hard` or `git checkout --` unless the user explicitly requests them.

## Local LLM Proxy

- The app talks to `http://localhost:8787` by default.
- The Node proxy prefers `server/.env`.
- If `LLM_API_KEY` is not configured, the proxy tries local CLIProxyAPI config at `/opt/homebrew/etc/cliproxyapi.conf`.
- Do not commit `server/.env`.

## Current Product Expectations

- Tags with no non-deleted task associations should not be shown.
- When a task is associated with a tag, that tag should move to the front.
- Summary periods support day, week, month, year, and custom date ranges.
- Daily and weekly templates should stay simple: completed work and next plan.
- Monthly and yearly templates can include richer review structure.
- Custom summary templates should behave like weekly summaries for ranges of 7 days or less, and like monthly summaries for longer ranges.
