# ABD-12 — Diagnostic bundle Production

Date: 2026-10-19 UTC
Run: 2932de36-d8f6-4c7d-abaf-8b9718c886ab
Agent: Dev

## Verified state

- Canonical issue: ABD-12; Preview is excluded by TOPIC-REGISTRY.md.
- Workspace: `/srv/paperclip-hermes/dev/workspaces/faithlock`.
- Branch: `fix/faithlock-store-click-measurement`, based on approved commit `38d472cc9f77bfc66b257dfa381702951a1b06c3`.
- Local implementation includes `ResourceStoreClickTracker` in `GlossaryTemplate`, `resource-store-click.ts`, and the tracking tests.
- `corepack pnpm test:tracking`: 7/7 passed.
- `./node_modules/.bin/tsc --noEmit`: passed.
- Fresh Paperclip issue evidence says the approved Production click occurred, but PostHog landing project `324483` returned zero `faithlock_store_click` events.
- Existing Production inspection evidence records that the public JavaScript bundles did not contain `ResourceStoreClickTracker`, `faithlock_store_click`, or `resource_page`, despite those markers being present in the approved source commit.

## Classification

`INSTRUMENTATION_MISSING` caused by a public-bundle versus approved-commit divergence. This is not a local test failure. No production mutation was performed.

## Required unblock

Jupiter/Release must confirm the commit actually served by the public Production domain and restore/republish the approved tracking code (or provide equivalent bundle evidence). Orion must then immediately re-read PostHog project `324483` around one controlled Production click and verify exactly one event with its properties.

## Paperclip disposition limitation

A standard API comment mutation was attempted with the current run ID and rejected HTTP 403 (`cross_issue_influence_run_context_required`). The local task-bridge key exists, but the documented bridge helper `paperclip_issue.py` is absent from this runtime. No duplicate issue was created and no further identical mutation was retried. Paperclip mutation requires the runtime/task bridge to expose an accepted checkout context; until then this file is the durable handoff.

## Current run update — 2026-10-19 UTC

- Run: `fd7bd083-8bc9-4bca-a2b8-85ecd7e97488`.
- Fresh browser evidence on the approved Production domain reproduced a legacy article CTA destination (`https://apps.apple.com/app/faithlock`) while the global CTA used the verified FaithLock listing.
- Code fix committed locally as `b271119`: normalize the exact legacy CMS URL to `https://apps.apple.com/us/app/faith-lock-bible-prayer-focus/id6754208209` for string/HTML/Contentful hyperlink rendering.
- Verification: `corepack pnpm test:tracking` passed 8/8; `./node_modules/.bin/tsc --noEmit` passed; `git diff --check` passed.
- No production mutation, deploy, or external publication performed. Release/Jupiter must publish or provide equivalent served-bundle evidence, then Orion should reread PostHog `324483` after one controlled Production click.
