# FaithLock 7-Day Series Measurement Contract

Status: INTERNAL PRE-TEST CONTRACT — not implemented and not approved for external testing
Version: 1
Product: FaithLock
App Store app ID: `6754208209`
Currency: USD when a revenue record is available

## Decision gate

Current decision: STOP external test / GO internal content review.

Reason: the authorized shared-tool catalog exposed no AppsFlyer read tool in this run, so the live AppsFlyer state could not be read. This is classified as `INSTRUMENTATION_MISSING` for this contract, not as zero installs or zero revenue. `ROI NON CALCULABLE` remains mandatory because attributable payers, recorded revenue, and reliable cost are not available.

No YouVersion contact, submission, publication, paid API call, Production/store change, or external spend is authorized by this artifact.

## Funnel and non-equivalence rules

The only valid sequence is:

`referral/session → FaithLock content view → store click → AppsFlyer install or re-engagement → first in-app activation → purchase → recorded revenue`

A store click is a web proxy. The existing `faithlock_store_click` receipt is the only accepted web-store-click event name; it is not an install. An install is not an activation. An activation is not a purchase. A purchase is not recorded revenue until the revenue source confirms the amount and currency. Counts must remain separate in every report.

## Event contract (proposed, not emitted)

| Event | Emission moment | Required properties | Idempotency / interpretation |
|---|---|---|---|
| `faithlock_series_viewed` | Series screen is rendered | `series_id`, `series_version`, `source`, `campaign`, `referral_type`, `market` | May recur; one view is not a start or activation. |
| `faithlock_series_day_started` | Reader opens a specific day | `series_id`, `series_version`, `day_number`, `source`, `campaign`, `referral_type`, `market` | May recur; use the first timestamp per user/day for funnel analysis. |
| `faithlock_series_day_completed` | Reader reaches the explicit day completion action | Same as day started plus `completion_method` | At most once per user/day/version; completion is engagement only. Do not send content, prayer, mood, or journal text. |
| `faithlock_series_completed` | Reader completes Day 7 review action | `series_id`, `series_version`, `source`, `campaign`, `referral_type`, `market` | At most once per user/series/version; secondary activation proxy, not a payer. |
| `first_focus_started` | Product's independently defined first focus session begins | `source`, `campaign`, `referral_type`, `market` | Must be first-occurrence only; do not map a series day to this event without product evidence. |
| `first_focus_completed` | Product's independently defined first focus session completes | Same as first focus started | Must be first-occurrence only; secondary growth metric, not revenue. |

The existing `prayer_session_completed` event is not accepted as a substitute for `first_focus_completed` until its semantics and first-occurrence behavior are independently verified.

## Attribution fields

Every web event in this contract must carry controlled, non-sensitive values:

- `source`: normalized acquisition source, at minimum `ai_referral`, `partner_referral`, `organic_search`, or `direct`.
- `campaign`: stable campaign identifier, never free-form user text; required for AI/partner comparisons.
- `referral_type`: `ai`, `partner`, `organic`, `direct`, or `unknown`.
- `medium`: controlled channel value such as `referral`, `organic`, or `direct`.
- `content_variant`: internal variant ID when an experiment exists; omit when none exists.
- `series_id`: `faithlock_7_day_bible_prayer`.
- `series_version`: immutable content version, starting at `v1`.
- `day_number`: integer 1–7 only for day events.
- `market`: approved market code, initially `en-US`.
- `destination`: `official_app_store` only for an eligible store click.

AppsFlyer source-of-truth fields to read, without exposing keys or individual-level records:

- App ID must equal `6754208209`.
- Explicit UTC period start/end and timezone.
- `media_source` / source and `campaign` with a documented normalization map to the web `source` and `campaign`.
- Install count and install timestamp aggregate.
- Re-engagement count and timestamp aggregate, if present.
- Purchase count, revenue amount, currency, and event timestamp aggregate, if present.
- Attribution window and lookback settings.
- A stable aggregate join strategy between referral/campaign and AppsFlyer records; no raw device ID or personal data in this document.

## Required join and reporting rules

1. Preserve `source` and `campaign` unchanged through the approved redirect/deep-link path; do not infer them from page referrer after the fact.
2. Report AI referral, partner referral, organic, and direct as separate cohorts. Never combine AI and partner into an unqualified “referral” result.
3. Report each funnel stage in its own column: views, day starts, day completions, series completions, store clicks, installs, re-engagements, first focus completions, purchases, revenue.
4. Use AppsFlyer only for the stages it actually returns. Missing install/purchase/revenue fields are `INSTRUMENTATION_MISSING`, not zero.
5. Revenue is attributable only when AppsFlyer (or an explicitly approved revenue source) returns a purchase/revenue record under the declared attribution window and campaign mapping.
6. Cost is zero for this internal prototype. A future external test must record all non-zero cost before ROI is calculated.
7. North Star: attributable new payers over a rolling 28-day window plus attributable recorded revenue. `first_focus_completed` is secondary. Until both attribution and cost/revenue data are present, report `ROI NON CALCULABLE`.

## Live-read checklist and current missing fields

The fresh AppsFlyer connector lookup for this run returned no matching authorized tool. Therefore these fields are unresolved:

- Live AppsFlyer access/read endpoint or approved aggregate export.
- Confirmation that App ID `6754208209` is the connected application.
- Query period, timezone, and attribution windows.
- Returned install aggregate and event definition.
- Returned re-engagement aggregate and event definition.
- Returned purchase aggregate, revenue, currency, and event definition.
- Source/campaign values and their mapping to web `source`, `campaign`, and `referral_type`.
- Approved join key/aggregation method across web, AppsFlyer, and in-app activation.
- Baseline counts for each funnel stage.
- Any non-zero test cost and cost attribution method.

Classification: `INSTRUMENTATION_MISSING`. This does not mean the product has no installs, purchases, or revenue.

## Acceptance and stop/go

GO for internal review: the seven-day content prototype and this contract are versioned, content-only artifacts.

STOP for external test: do not contact YouVersion, submit, publish, spend, call a paid API, change Production/store, or claim ROI until every missing field above is resolved by an authorized live read and the event/join implementation is independently tested.
