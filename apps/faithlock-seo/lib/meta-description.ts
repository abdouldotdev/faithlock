/**
 * Meta description helpers shared by the compare and glossary routes.
 *
 * Contentful entries can ship without `seoDescription`, and a glossary
 * `shortDefinition` can be a full paragraph. Google truncates the snippet it
 * shows around 160 characters, so anything longer is wasted bytes; a missing
 * description is worse, because the crawler then invents the snippet from page
 * chrome (measured on Production 2026-11-11: 13 URLs served no description at
 * all).
 */

export const MAX_META_DESCRIPTION_LENGTH = 160

/**
 * Normalise whitespace and bound a description to `max` characters on a word
 * boundary. Returns `undefined` for empty input so callers can fall through to
 * the next source instead of emitting an empty <meta>.
 */
export function toMetaDescription(
  input: string | undefined | null,
  max: number = MAX_META_DESCRIPTION_LENGTH,
): string | undefined {
  const text = input?.replace(/\s+/g, ' ').trim()
  if (!text) return undefined
  if (text.length <= max) return text

  const cut = text.slice(0, max - 1)
  const lastSpace = cut.lastIndexOf(' ')
  const body = lastSpace > max * 0.6 ? cut.slice(0, lastSpace) : cut
  return `${body.replace(/[\s,;:.!?—–-]+$/, '')}…`
}
