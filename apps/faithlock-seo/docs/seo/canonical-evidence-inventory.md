# FaithLock canonical and evidence inventory

This inventory maps the public evidence surfaces for the canonical home and the linked legal/features pages. It is a source-of-truth check for implementation and review; it is not a GEO guarantee and does not require `llms.txt`.

| Surface | Public URL | Source of truth | Expected evidence |
| --- | --- | --- | --- |
| Home | `https://www.getfaithlock.com/` | `apps/faithlock-seo/app/page.tsx` | HTTP 200, SSR HTML, self-referential canonical `/`, stable Open Graph URL `/` |
| Features index | `https://www.getfaithlock.com/features` | `apps/faithlock-seo/app/(seo)/features/page.tsx` | HTTP 200, canonical `/features`, linked from home navigation |
| Privacy | `https://www.getfaithlock.com/privacy` | `apps/faithlock-seo/app/(seo)/privacy/page.tsx` | HTTP 200, canonical `/privacy`, linked from legal/footer surfaces |
| Terms | `https://www.getfaithlock.com/terms` | `apps/faithlock-seo/app/(seo)/terms/page.tsx` | HTTP 200, canonical `/terms`, linked from legal/footer surfaces |
| Sitemap | `https://www.getfaithlock.com/sitemap.xml` | `apps/faithlock-seo/app/sitemap.ts` | Contains home, features, privacy and terms without duplicate URLs |
| JSON-LD | Inline in rendered HTML | `apps/faithlock-seo/app/layout.tsx` | SSR `WebSite` and `SoftwareApplication` JSON-LD; URLs use `SITE_URL` |

## Interpretation limits

HTTP, canonical, sitemap and JSON-LD checks establish technical consistency only. They do not establish search ranking, AI citation, GEO exposure, installs, subscriptions or attributable revenue. The fixed 20-prompt/100-cell GEO baseline remains `NON CALCULABLE` when no authorized platform observations exist.
