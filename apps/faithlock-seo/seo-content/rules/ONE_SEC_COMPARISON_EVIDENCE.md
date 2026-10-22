# One Sec comparison evidence brief

Date checked: 2026-10-22
Target: `new-pages/comparisons/faithlock-vs-one-sec.md`
Scope: `apps/faithlock-seo/seo-content/` only

## Source inventory

| Source | Official evidence used | Decision |
|---|---|---|
| https://one-sec.app/ | one sec describes interruption/blocking for social apps, apps, and websites; lists breathing, reflection, phone rotation, journaling, intention/emotion tracking, scheduled blocks, blocking mode, iOS/Android/browser coverage, and reports 57% fewer app openings on average | Keep only bounded descriptions and attribute the 57% figure to one sec's published claim and cited research context |
| https://one-sec.app/android | breathing intervention, configurable text/duration, statistics, local/offline processing claim, and Android-specific setup | Keep breathing intervention and Android availability; do not generalize Android implementation details to every platform |
| https://one-sec.app/research/ | PNAS 2023, CHI 2024, Danish 2025 and other research entries are listed as published or in progress | Keep “links to peer-reviewed research”; do not turn the 57% average into a guarantee or head-to-head result |
| https://apps.apple.com/us/app/one-sec-screen-time-focus/id1532875441 | iOS listing says one sec delays access rather than blocking completely by default; free one-app tier; optional re-intervention; pricing and compatibility are listing-specific | Keep the default-delay distinction; omit prices because regional/platform offers change |
| https://www.pnas.org/doi/10.1073/pnas.2213114120 | cited study destination on one sec's official research page | Cite only as the research context behind the published 57% claim |
| https://apps.apple.com/us/app/faith-lock-bible-prayer-focus/id6754208209 | official FaithLock listing, ID `6754208209` | CTA uses exact official App Store URL; render layer may route through the tracked destination |

## Claims removed or reformulated

- Removed unverified One Sec pricing (`$4.99/month`, `$19/year`, `$39.99/year`, and `$99.99 lifetime`).
- Removed unsupported “4.8 stars / 55,000+ users” and “popular” social proof.
- Removed unsupported claim that One Sec always uses a 10-second timer; official sources describe multiple interventions and configurable duration.
- Removed the absolute claim that One Sec is always a soft pause; official sources document blocking mode and scheduled blocks.
- Removed unsupported “works offline” generalization; the Android page's local/offline wording is not promoted to every platform.
- Removed unverified claims about no streaks, battery impact, API conflicts, independent user-report consensus, and cross-platform synchronization semantics.
- Kept the 57% figure only with source attribution and an explicit limitation: it is an average app-opening result, not a guarantee, head-to-head comparison, install, purchase, or revenue claim.

## CTA and measurement contract

The CTA source contains the exact official URL ending in `/id6754208209`. Existing render behavior rewrites raw FaithLock App Store links to the tracked store destination. The existing contract is `faithlock_store_click`; it records one outbound web click with destination, location, page path, source, and optional button text. A click is not an installation, re-engagement, subscription, purchase, or revenue event.

The relevant contract implementation and tests are outside this content-only change and were not modified: `lib/store-click.ts`, `tests/store-click.test.mjs`, and the provider/render path. The content CTA is therefore verified against the existing contract rather than creating a second event name.

## AppsFlyer bounded read attempt

Attempt: searched the authorized shared-tool catalog for `appsflyer` and for AppsFlyer attribution/report actions.

Result: no AppsFlyer tool was exposed to this runtime, so no authorized read of App ID, period/timezone, source/campaign, install, re-engagement, purchase events, or attribution windows was performed.

Classification: ACCESS_DENIED (authorized connector/tool surface absent), not DATA_ABSENT. No credentials or individual-level data were accessed. Attribution remains unavailable for this comparison.

## ROI and acceptance limits

ROI NON CALCULABLE: no attributable new-payer count over a rolling 28-day window, attributable recorded revenue, or reliable cost was available in this run. The CTA and `faithlock_store_click` are measurement proxies only. No installation, subscription, purchase, or revenue result is inferred.

No publication, external contact, spend, merge, or Production change was performed.
