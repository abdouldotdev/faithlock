# Attribution baseline — rolling 28 days (PostHog product project)

Status: verified snapshot + reproducible queries. Owner: Dev (ABD-172).
Measurement source: PostHog product project for the FaithLock mobile app
(`com.appbiz.faithlock`, the project that also holds `prayer_session_completed`,
matching the ABD-63 verification). No AppsFlyer connector read was used: the
attribution fields below arrive in PostHog from the AppsFlyer SDK integration.

Precondition: run `docs/analytics/queries/source-identity.sql` (Q0) first. It
fails closed when the connector is bound to a different project, which is the
state observed on 2026-11-10 (see the re-verification section below).

Snapshot executed: 2026-11-09T14:25Z. Window: `now() - INTERVAL 28 DAY`
(rolling, UTC).

## What is measured, and what it is not

| Stage | Event / field | Status |
|---|---|---|
| Install attribution | `install_attributed` → `af_status`, `af_media_source` | present |
| Purchase / trial start | `paywall_purchase_completed` → `revenue`, `currency`, `plan_id`, `plan_type`, `is_trial_start` | present |
| First product value | `first_focus_started`, `first_focus_completed`, `focus_completed` | absent from the project taxonomy (0 events, all time) — `INSTRUMENTATION_MISSING` until a build containing PR #74 ships |

Definitions used:

- **Payer**: a distinct person with at least one `paywall_purchase_completed`
  event where `is_trial_start` is not `true`.
- **Trial start**: `is_trial_start = true`. It is *not* a payer. The `revenue`
  value on a trial start is the plan price at trial start, not collected money.
- **Recorded value**: `sum(revenue)` **per currency**. Values are never summed
  across currencies; no FX normalisation is applied here.
- **Attribution bucket**: `af_media_source` (falling back to `af_status`) from
  the person's first `install_attributed` event. Persons with a purchase but no
  `install_attributed` event are reported as `no_install_attributed`, never
  silently dropped or counted as organic.

## Verified snapshot (28 days to 2026-11-09T14:25Z)

Funnel top: `install_attributed` = 82 events / 82 persons.

Purchases: 13 events / 13 persons.

| Currency | Attribution bucket | Persons | Charged events | Charged value | Trial starts | Trial value |
|---|---|---|---|---|---|---|
| USD | organic | 7 | 2 | 13.98 | 5 | 199.95 |
| USD | no_install_attributed | 2 | 2 | 13.98 | 0 | — |
| CAD | organic | 1 | 0 | — | 1 | 49.99 |
| GBP | organic | 2 | 0 | — | 2 | 79.98 |
| MYR | no_install_attributed | 1 | 0 | — | 1 | 199.90 |

North Star inputs from this window:

- **Attributable new payers (strict, organic)**: **2** persons, recorded charged
  value **USD 13.98**.
- All charged payers (organic + unattributed): **4** persons, **USD 27.96**.
- Trial starts awaiting conversion: **9** (8 organic, 1 unattributed), with a
  plan-price value of USD 199.95 / CAD 49.99 / GBP 79.98 / MYR 199.90.
- **ROI: NON CALCULABLE** — acquisition cost is not recorded in this source.
  Attributable payers and recorded revenue exist; cost does not.

## Limits that must travel with these numbers

1. Trial-start `revenue` is plan value, not money collected. A payer is counted
   only from non-trial purchase events; conversion and any refund/chargeback
   confirmation require the billing source (RevenueCat / App Store), which is
   not an active Paperclip connection.
2. `install_attributed` proves install attribution for the person, not that the
   purchase was caused by that source. The join is per person, lifetime-first
   attribution bucket, and is stated as such.
3. Internal or team test purchases are not excluded — no allowlist is applied.
   `$is_testflight` and `$is_sideloaded` are `false` on the snapshot rows, which
   is weak evidence of App Store builds only.
4. A store click is still not an install, and an install is still not a payer.
   Each stage stays separate.

## Q0 — source identity preflight (mandatory, run first)

`docs/analytics/queries/source-identity.sql` must return a non-zero count for
each of `prayer_session_completed`, `install_attributed` and
`paywall_purchase_completed` **before** Q1..Q4 may be run or published. Any zero
means the connector is bound to a different PostHog project; the correct
classification is `CONNECTOR_UNHEALTHY` (mis-scoped source), never
`DATA_ABSENT`, because an empty result from the wrong project is
indistinguishable from a real zero.

## Re-verification attempt, 2026-11-10 — gate fired, source was not FaithLock

Status: **not re-verifiable from the shared connector on 2026-11-10.**

- Q0 executed 2026-11-10T10:0xZ (UTC) through the shared PostHog connector:
  `prayer_session_completed` = 0, `install_attributed` = 0,
  `paywall_purchase_completed` = 0, with PostHog taxonomy warnings that none of
  the three names exists in the connected project.
- Negative control (30-day event inventory of the connected project) returned a
  mobile-money app taxonomy — `fastcash_*`, `transfer_*`, `airtime_*`,
  `auth_pin_*`, `revenue`, `appsflyer_first_launch_attributed` (950 events) —
  and no FaithLock event at all.
- Conclusion: the connector resolves to a project that is **not** the FaithLock
  product project (239251). The 2026-11-09 snapshot above therefore remains a
  dated observation and must not be refreshed, extended or cited as current
  until the connector is re-scoped. Nothing in this document is retracted: the
  numbers were produced by the queries below against the FaithLock project at
  the timestamp shown.
- Blast radius: the North Star inputs (attributable payers, recorded revenue)
  and ABD-773 step 3 (`first_focus_*` reception) cannot be read until the
  connector is re-scoped to 239251 (product) / 324483 (landing).
- **Confirmed persistent, not transient.** Q0 was re-executed on 2026-11-11T11:2xZ
  (run `1785255f-b63e-435c-ae04-6969a7afa50f`): `prayer_session_completed`,
  `install_attributed` and `paywall_purchase_completed` = 0 events each, with
  PostHog taxonomy warnings that none of the three names exists in the connected
  project. The negative control returned the same mobile-money taxonomy over a
  7-day window (`fastcash_deposit_step_advanced` 2 660, `fastcash_entry_opened`
  2 518, `airtime_flags_resolved` 1 839, `transfer_started` 670) and a 90-day
  scan for `%faithlock%`, `%prayer_session%`, `%paywall%` returned zero rows.
  The connected project holds 204 752 events / 1 764 persons over 28 days and
  none of them is a FaithLock event. The binding has therefore been wrong for at
  least two consecutive days; the 2026-11-09 snapshot is the last good read.

## Comparison mode

Re-run the four queries in `docs/analytics/queries/attribution-28d.sql` against
the same rolling 28-day window and compare, per currency and per attribution
bucket:

- attributable new payers (strict, organic) — primary;
- charged value by currency — reported separately, never summed across currencies;
- trial starts and trial value — secondary, never reported as revenue;
- `install_attributed` persons — funnel top, proxy only.

Record each run with its execution timestamp and window. A run is only
comparable when source, window length, currency handling and attribution-bucket
rule are identical.
