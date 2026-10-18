# FaithLock resource → App Store click measurement (draft for Data review)

**Scope:** only `/resources/best-bible-verse-lock-screen-apps` and `/resources/best-christian-app-blocker`. This branch does not deploy or publish the instrumentation.

## Event contract proposed

- `faithlock_store_click`: one event per click on a verified FaithLock outbound store link on these two resource pages. Works for Contentful-rendered inline links and the existing React CTA button.
- Dimensions: `page_path`, per-page `cta_id` (ordinal among eligible links **inside the article**, stable while the article content is unchanged; rebaseline after CMS link reordering), `link_position` (nearest section ID or `unknown`), `market=US`, `source=resource_page` (surface, **not** traffic attribution), `destination_url`, and `destination_type` (`short_link` or `app_store`).
- Eligible destinations: `https://pim.ms/kTxgKF4` and direct `apps.apple.com` paths ending in `id6754208209` (Appbiz Studio, LLC). Do **not** track the similarly named but unrelated `id6786329834` (Fraser Smith) or other apps linked in comparison content.
- Existing `cta_click` remains unchanged. A React CTA may generate one `cta_click` and one `faithlock_store_click` for different analyses; the new event should not duplicate itself. No URL or redirect change; no UTM is added.
- This measures **outbound web clicks only**, not installs, subscriptions, revenue, or attribution. The event can only be claimed as received after a controlled non-production or approved production test in the correct PostHog web project (the site and app use separate projects).

## Acceptance before release

1. Run `corepack pnpm test:tracking` and `./node_modules/.bin/tsc --noEmit` inside `apps/faithlock-seo` after dependency installation.
2. On a non-production preview with PostHog configured, click one qualifying link with mouse and keyboard on each scoped page. Confirm exactly one `faithlock_store_click` per interaction, and that the App Store destination opens even if PostHog is blocked. Check a third-party App Store link emits no `faithlock_store_click`.
3. Data confirms the project ID, event name, dimensions and privacy policy before approving the measurement contract. Product/developer approves implementation; Board approval is separate before any production deployment.
4. After an approved release, compare counts only for a dated period/timezone and eligible-page denominators. Do not convert clicks into installations or subscriptions without a separate authorized attribution source.

**Source identity:** project metadata and the live `getfaithlock.com` CTA point to App Store `id6754208209`; Nova's earlier briefs citing `id6786329834` were quarantined for product-identity mismatch.
