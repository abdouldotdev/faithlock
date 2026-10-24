import type { Competitor } from './types'

function humanizeSlug(slug: string): string {
  return slug
    .replace(/^faithlock-vs-/, '')
    .replace(/[-_]+/g, ' ')
    .replace(/\b\w/g, (character) => character.toUpperCase())
    .trim()
}

/**
 * Return a stable comparison title even when an older Contentful entry has no
 * seoTitle. The route label makes the fallback unique per compare URL while
 * preserving the existing editorial title whenever it is present.
 */
export function getComparisonTitle(
  fields: Pick<Competitor, 'name' | 'seoTitle'>,
  routeSlug: string,
): string {
  const configuredTitle = fields.seoTitle?.trim()
  if (configuredTitle) return configuredTitle

  const routeLabel = humanizeSlug(routeSlug)
  const competitorName = fields.name?.trim() || routeLabel
  return `FaithLock vs ${competitorName} — ${routeLabel} comparison`
}
