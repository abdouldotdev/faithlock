# faithlock — SEO / programmatic pages app

Next.js 14 app serving `getfaithlock.com` (`/compare/[slug]`, `/resources/[slug]`,
`/features/[slug]`, sitemap). Markdown content for `/resources` lives in
`seo-content/new-pages/`; the file path is never the public URL — the public URL
comes from the `slug:` frontmatter field (`lib/local-content.ts`).

## Building and previewing

Facts verified on Node 22.23.2 / pnpm 10 on 2026-11-11, against the Vercel
project for this app (`rootDirectory: apps/faithlock-seo`):

- `pnpm-lock.yaml` is committed, so Vercel installs with pnpm.
  `pnpm install --frozen-lockfile` is clean and must stay clean: changing
  `package.json` without regenerating the lockfile breaks the deployment.
- `next build` succeeds with **zero** Contentful environment variables — 458
  static pages. `lib/contentful.ts` treats Contentful as fully optional.
- **But** `/compare/[slug]` is Contentful-only: with no
  `CONTENTFUL_SPACE_ID` / `CONTENTFUL_ACCESS_TOKEN`, `getAllCompetitors()`
  returns `[]` and the build emits **no compare page at all** (verified: 0
  `/compare/*.html` locally without credentials, 13 with stubbed entries).
  A Preview deployment can therefore only be used to review a compare-page
  change if those two variables are configured for the **Preview** environment
  in the Vercel project; otherwise compare routes are Production-only
  verification.
- `/resources` pages do not need Contentful: they are generated from the
  committed markdown and are fully reviewable in Preview.

## Contentful text fields are not always strings

`seoDescription` is a **Rich text** field on some `competitor` entries: the
Delivery API returns a `document` node, not a string. Production proved it on
2026-11-11 — five `/compare/*` URLs served
`<meta name="description" content="[object Object]">`, and the first branch that
called `.trim()` on the field failed the whole Vercel build:

```
TypeError: e.seoDescription?.trim is not a function
Export encountered errors on following paths:
  /(seo)/compare/[slug]/page: /compare/faithlock-vs-one-sec  (+4 more)
```

A local build without Contentful credentials never hits this path (it generates
zero compare pages), so the failure is only reproducible with entries present.
Always run a CMS text field through `coerceToPlainText()` from
`lib/meta-description.ts` before using string methods on it.
