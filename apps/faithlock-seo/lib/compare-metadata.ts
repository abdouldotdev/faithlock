import type { Competitor } from './types'

const SMALL_WORDS = new Set(['vs', 'v', 'and', 'or', 'of', 'the', 'for', 'to', 'a', 'an', 'in', 'on', 'with'])

const ACRONYMS: Record<string, string> = {
  ios: 'iOS',
  ipad: 'iPad',
  iphone: 'iPhone',
  macos: 'macOS',
}

const MAX_TITLE_LENGTH = 70
const MAX_DESCRIPTION_LENGTH = 160

/**
 * Flatten a CMS text field to plain text.
 *
 * Kept local (no imports) on purpose: this module is loaded directly by
 * `node --experimental-strip-types` in tests, where extension-less relative
 * imports do not resolve. It mirrors `coerceToPlainText` in
 * `lib/meta-description.ts`; Contentful returns Rich text documents for some
 * fields, and calling `.trim()` on one threw
 * `TypeError: e.seoDescription?.trim is not a function` while prerendering five
 * `/compare/*` pages on 2026-11-11 (Vercel Preview failure, ABD-800).
 */
function textOf(input: unknown): string | undefined {
  if (typeof input === 'string') {
    const text = input.replace(/\s+/g, ' ').trim()
    return text || undefined
  }
  if (Array.isArray(input)) {
    const parts = input.map(textOf).filter((part): part is string => Boolean(part))
    return parts.length ? parts.join(' ') : undefined
  }
  if (input && typeof input === 'object') {
    const node = input as { value?: unknown; content?: unknown[] }
    if (typeof node.value === 'string') return textOf(node.value)
    if (Array.isArray(node.content)) return textOf(node.content)
    for (const value of Object.values(node)) {
      const text = textOf(value)
      if (text) return text
    }
  }
  return undefined
}

function titleCaseToken(token: string, index: number): string {
  const acronym = ACRONYMS[token]
  if (acronym) return acronym
  if (index > 0 && SMALL_WORDS.has(token)) return token
  return token.charAt(0).toUpperCase() + token.slice(1)
}

function humanizeSlug(slug: string): string {
  return slug
    .replace(/^faithlock-vs-/, '')
    .replace(/[-_]+/g, ' ')
    .trim()
    .split(' ')
    .filter(Boolean)
    .map((token, index) => titleCaseToken(token.toLowerCase(), index))
    .join(' ')
}

/**
 * A Contentful `name` can be a real product name ("Opal") or a raw slug
 * ("faithlock-vs-opal", "christian-app-blocker-comparison"). Anything that is
 * a single lowercase token, or that contains a separator, is treated as a slug
 * so the visible <title> never exposes it verbatim.
 */
function isSlugLike(name: string): boolean {
  if (/\s/.test(name)) return false
  return /^[a-z0-9]+([-_][a-z0-9]+)*$/.test(name)
}

function normalizeName(name: unknown): string {
  const trimmed = textOf(name) ?? ''
  if (!trimmed) return ''
  return isSlugLike(trimmed) ? humanizeSlug(trimmed) : trimmed
}

/**
 * Return a stable comparison title even when an older Contentful entry has no
 * seoTitle. The route label keeps the fallback unique per compare URL while
 * preserving the existing editorial title whenever it is present.
 *
 * The route label is only appended when it adds information: emitting
 * "FaithLock vs Opal — Opal comparison" duplicated the competitor name, and
 * echoing a slug name produced "FaithLock vs faithlock-vs-opal — Opal
 * comparison" on Production (observed 2026-11-11).
 */
export function getComparisonTitle(
  fields: Pick<Competitor, 'name'> & { seoTitle?: unknown },
  routeSlug: string,
): string {
  const configuredTitle = textOf(fields.seoTitle)
  if (configuredTitle) return configuredTitle

  const routeLabel = humanizeSlug(routeSlug)
  const competitorName = normalizeName(fields.name) || routeLabel
  const base = `FaithLock vs ${competitorName}`

  const routeAddsInformation =
    routeLabel.toLowerCase() !== competitorName.toLowerCase() &&
    !competitorName.toLowerCase().endsWith(routeLabel.toLowerCase())

  const title = routeAddsInformation ? `${base} — ${routeLabel} comparison` : base

  return title.length <= MAX_TITLE_LENGTH ? title : base
}

/**
 * Visible competitor name for body copy, tables, breadcrumbs and JSON-LD.
 *
 * PR #81 fixed the <title>, but the rendered page still used the raw Contentful
 * `name`, so Production served "FaithLock vs faithlock-vs-opal" as the H1,
 * "vs faithlock-vs-opal" in the breadcrumb and `faithlock-vs-opal` as the table
 * column header on the eight entries whose `name` is a slug (observed
 * 2026-11-11 on /compare/faithlock-vs-opal). Normalising once here keeps every
 * consumer consistent.
 */
export function getCompetitorDisplayName(
  fields: Pick<Competitor, 'name'>,
  routeSlug: string,
): string {
  return normalizeName(fields.name) || humanizeSlug(routeSlug)
}

/**
 * Meta description for a compare page. Falls back to a deterministic sentence
 * built from the display name when Contentful has no `seoDescription`, because
 * eight of the thirteen compare URLs shipped with no description at all
 * (measured on Production, 2026-11-11). The sentence mirrors the sections the
 * template actually renders: features, pricing, effectiveness, biblical view.
 */
export function getComparisonDescription(
  fields: Pick<Competitor, 'name'> & { seoDescription?: unknown },
  routeSlug: string,
): string {
  // Keep this module free of runtime imports: tests load it directly with
  // `node --experimental-strip-types`, and extension-less lib imports do not
  // resolve under plain ESM. Same 160-char snippet bound as lib/meta-description.
  const configuredDescription = textOf(fields.seoDescription)
  if (configuredDescription) {
    return configuredDescription.length <= MAX_DESCRIPTION_LENGTH
      ? configuredDescription
      : `${configuredDescription.slice(0, MAX_DESCRIPTION_LENGTH - 1).trimEnd()}…`
  }

  const name = getCompetitorDisplayName(fields, routeSlug)
  const base = `FaithLock vs ${name}: features, pricing, effectiveness and a biblical perspective on screen time and app blocking.`
  if (base.length <= MAX_DESCRIPTION_LENGTH) return base

  const short = `FaithLock vs ${name}: features, pricing and a biblical perspective on screen time.`
  if (short.length <= MAX_DESCRIPTION_LENGTH) return short

  const cut = short.slice(0, MAX_DESCRIPTION_LENGTH - 1)
  const lastSpace = cut.lastIndexOf(' ')
  return `${(lastSpace > 0 ? cut.slice(0, lastSpace) : cut).replace(/[\s,;:.!?—–-]+$/, '')}…`
}
