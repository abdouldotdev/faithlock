import type { Competitor } from './types'

const SMALL_WORDS = new Set(['vs', 'v', 'and', 'or', 'of', 'the', 'for', 'to', 'a', 'an', 'in', 'on', 'with'])

const ACRONYMS: Record<string, string> = {
  ios: 'iOS',
  ipad: 'iPad',
  iphone: 'iPhone',
  macos: 'macOS',
}

const MAX_TITLE_LENGTH = 70

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

function normalizeName(name: string | undefined | null): string {
  const trimmed = name?.trim() ?? ''
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
  fields: Pick<Competitor, 'name' | 'seoTitle'>,
  routeSlug: string,
): string {
  const configuredTitle = fields.seoTitle?.trim()
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
