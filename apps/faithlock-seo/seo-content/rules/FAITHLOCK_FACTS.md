# FaithLock — factual source of truth

Versioned factual registry for the SEO site. Public copy may use only claims marked VERIFIED, and must preserve the wording and scope below. Unknown or paywall-dependent details stay unclaimed.

Last verified: 2026-10-21

## Primary sources

| Source | URL | Scope |
|---|---|---|
| Apple App Store listing | https://apps.apple.com/us/app/faith-lock-bible-prayer-focus/id6754208209 | Product name, seller, availability, supported devices, minimum OS, description, feature copy, current rating/review count, and displayed in-app purchase prices |
| Apple iTunes Lookup API | https://itunes.apple.com/lookup?id=6754208209&country=us | Machine-readable verification of the same listing; excludes the homonymous app id6786329834 |
| Official product site | https://faithlock.net/ | Product positioning and public feature descriptions |
| SEO site privacy page | https://www.getfaithlock.com/privacy | Site-published privacy notice; do not infer stronger privacy claims than the page states |
| SEO site terms page | https://www.getfaithlock.com/terms | Site-published subscription, cancellation, and limitation terms |

## Verified claims

| Claim | Allowed wording / scope | Evidence |
|---|---|---|
| Product identity | “Faith Lock: Bible Prayer Focus” is the App Store listing name; “FaithLock” is the product brand used by the official site. | App Store listing; official product site |
| Seller | Appbiz Studio, LLC | App Store listing / iTunes Lookup |
| Distribution | The verified listing is free to download and offers in-app purchases. | App Store listing / iTunes Lookup |
| Platforms | The verified listing supports iPhone and iPad. Do not claim Android, macOS, Windows, or cross-platform support. | App Store listing / iTunes Lookup (`features: iosUniversal`, supported devices) |
| Minimum OS | iOS 13.0 or later for the verified listing. | iTunes Lookup (`minimumOsVersion`) |
| Core mechanism | FaithLock is a prayer lock app that blocks selected distracting apps and asks users to read Bible verses and pray before access. | App Store description; official product site |
| Scheduling | The App Store description lists scheduled lock times for prayer, devotion, work, or family time. | App Store description |
| Progress | The App Store description lists prayer streak tracking and faith insights/stats, including screen time saved and verses read. | App Store description |
| Reminders and presentation | The App Store description lists prayer reminders and dark mode. | App Store description |
| Sync | Cloud sync is described as a Premium feature in the App Store listing. Do not call the product fully on-device or claim that all data stays on-device. | App Store description |
| Pricing | At verification, the listing displayed in-app purchase prices of $6.99 and $39.99. The listing/API evidence used here does not state the billing periods; never attach weekly, monthly, annual, or trial periods without a current paywall source. | App Store listing / iTunes Lookup |
| Privacy and terms | The site exposes `/privacy` and `/terms`. Link to those pages for policy detail; do not convert policy text into broader “private”, “secure”, or “never tracks” marketing claims. | SEO site privacy and terms pages |

## Not verified / prohibited

- $4.99/week, $24.99/year, or any other billing period not currently shown by the cited App Store/paywall evidence.
- A 3-day free trial as a current offer.
- Android, Windows, macOS, or generic cross-platform availability.
- iOS 16+ as the minimum OS; the verified listing says iOS 13.0+.
- “All data stays on your device”, “private and on-device”, or equivalent; the listing explicitly describes Premium cloud sync.
- User, download, or community totals such as “100k+” unless independently supplied and dated by the owner.
- “Only app blocker”, “unbreakable”, clinical outcomes, or guaranteed battery percentages.
- The homonymous App Store app id6786329834.

## Change protocol

When the App Store listing or official product site changes, update this file first with the retrieval date and source URL. Then update `lib/faithlock-data.ts` and affected public pages in the same change. Keep pricing periods and paywall entitlements unknown when the sources do not state them.
