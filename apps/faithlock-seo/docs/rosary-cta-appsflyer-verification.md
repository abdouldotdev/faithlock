# Rosary CTA and AppsFlyer verification

Date: 2026-10-22T02:22:39Z (UTC)
Scope: `/resources/how-to-pray-the-rosary`; no Production or external publication performed.

## Control 1 — CTA receipt

Status: PASS (static contract and local test).

The page CTA is the official FaithLock App Store URL ending in `id6754208209` and carries `data-store-location="rosary_faithlock_cta"`. The delegated listener in `app/providers.tsx` is the single event source and passes the resolved location to `trackStoreClick`. `buildStoreClick` now emits the receipt contract:

- `cta_id=rosary_faithlock_cta`
- `market=en-US`
- `source=resource_page`
- `destination=official_app_store`

Supporting fields retain the destination URL/type, location, button text, and page path. The destination matcher rejects non-HTTPS links, other App Store IDs (including `id6786329834`), and unrelated domains. The outbound event remains `faithlock_store_click` with `sendBeacon` transport.

Reproducible command:

```text
corepack pnpm test:tracking
```

Result: PASS, 8 tests, 0 failures. `git diff --check`: PASS. Node emitted only the existing module-type performance warnings.

This proves an outbound web-click receipt contract only. It does not prove an installation, subscription, payers, or revenue.

## Control 2 — AppsFlyer live read

Status: NOT AVAILABLE in this runtime; no live result was claimed.

Two bounded shared-tool searches were performed for an AppsFlyer live app-install/attribution report and for an AppsFlyer installs API. The shared tool catalog returned no matching AppsFlyer tool. No key, token, individual record, or guessed endpoint was used. Therefore the product correction reported by the Board is not disputed, but this run cannot verify a live AppsFlyer response for App ID `6754208209`, period/timezone, source/campaign, install/re-engagement/purchase events, or attribution windows.

Classification: ACCESS_DENIED at the runtime connector surface (AppsFlyer is not exposed to this agent runtime), not `DATA_ABSENT` and not evidence of zero installs or revenue. The next unblock is to expose an authorized read-only AppsFlyer report/export tool or attach an approved aggregate export; then repeat the read with an explicit UTC period and attribution windows.

## ROI

ROI NON CALCULABLE: attributable payers/revenue and reliable cost are not available from this verification. Store clicks remain a funnel proxy.

## Files changed

- `lib/store-click.ts`: receipt contract fields.
- `seo-content/new-pages/catholic/how-to-pray-the-rosary.md`: stable CTA location marker.
- `tests/store-click.test.mjs`: contract and Rosary CTA coverage.
- `docs/store-click-measurement.md`: contract documentation.
- This report: reproducible evidence and AppsFlyer runtime limitation.
