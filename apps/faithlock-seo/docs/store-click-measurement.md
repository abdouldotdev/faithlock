# FaithLock → App Store click measurement

## Event contract

- `faithlock_store_click`: one event per click (left or middle) on a link to the FaithLock App Store listing, on **every page** of the site: landing, header, footer, CTA buttons, callouts, and links inside markdown / Contentful content.
- Single source: the delegated listener in `app/providers.tsx`. Components only tag where they sit with `data-store-location`; they never capture the event themselves, so a click cannot be counted twice.
- Properties: `destination_url`, `destination_type` (`short_link` | `app_store`), `location` (`data-store-location`, landing `data-track-cta`, nearest `data-track-section` / `section[id]`, else `content`), `button_text`, `page_path`, `source` (`resource_page` for `/resources/*`, else `site`).
- Eligible destinations: `https://pim.ms/kTxgKF4` (the link every CTA uses, = `APP_STORE_URL`) and `apps.apple.com` paths ending in `/id6754208209`. Raw App Store links in content are rewritten to the short link at render time (`components/ui/RichText.tsx`). Other apps (including the unrelated `id6786329834`) never match.
- Sent with `transport: 'sendBeacon'` so same-tab navigations still deliver the event.
- `cta_click` is unchanged and still fires alongside for the components that already sent it.
- Measures outbound web clicks only, not installs, subscriptions or revenue.

## Tests

`corepack pnpm test:tracking` (store-click matching + competitor-link guard over all markdown pages).
