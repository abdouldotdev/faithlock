/**
 * Plain-text and meta-description helpers shared by the compare, glossary and
 * feature routes.
 *
 * Contentful does not guarantee that a text field arrives as a string: when the
 * field type in the content model is Rich text, the Delivery API returns a
 * `document` node instead. Production proved it — five `/compare/*` URLs served
 * `<meta name="description" content="[object Object]">` on 2026-11-11, and a
 * build with those entries failed prerendering:
 *
 *   TypeError: e.seoDescription?.trim is not a function
 *
 * Calling a string method on the raw field is therefore a build-time crash once
 * the CMS actually returns entries. Coerce first, then treat everything as text.
 */

export const MAX_META_DESCRIPTION_LENGTH = 160

type RichTextNode = {
  nodeType?: string
  value?: unknown
  content?: unknown[]
  [key: string]: unknown
}

/**
 * Flatten a CMS text field to plain text.
 *
 * Accepts a string, a Contentful Rich text `document`, a nested array of nodes,
 * or a locale-keyed object; returns `undefined` when there is nothing readable,
 * so callers can fall through to the next source instead of emitting an empty
 * `<meta>` or the string "[object Object]".
 */
export function coerceToPlainText(input: unknown): string | undefined {
  if (typeof input === 'string') {
    const text = input.replace(/\s+/g, ' ').trim()
    return text || undefined
  }

  if (Array.isArray(input)) {
    const parts = input.map(coerceToPlainText).filter((part): part is string => Boolean(part))
    return parts.length ? parts.join(' ') : undefined
  }

  if (input && typeof input === 'object') {
    const node = input as RichTextNode
    // Leaf node: { nodeType: 'text', value: '…' }
    if (typeof node.value === 'string') return coerceToPlainText(node.value)
    // Container node: { nodeType: 'document' | 'paragraph', content: [...] }
    if (Array.isArray(node.content)) return coerceToPlainText(node.content)
    // Single-locale wrapper: { 'en-US': '…' }
    for (const value of Object.values(node)) {
      const text = coerceToPlainText(value)
      if (text) return text
    }
  }

  return undefined
}

/**
 * Normalise whitespace and bound a description to `max` characters on a word
 * boundary. Google truncates the snippet it shows around 160 characters, so
 * anything longer is wasted bytes; a missing description is worse, because the
 * crawler then invents the snippet from page chrome.
 */
export function toMetaDescription(
  input: unknown,
  max: number = MAX_META_DESCRIPTION_LENGTH,
): string | undefined {
  const text = coerceToPlainText(input)
  if (!text) return undefined
  if (text.length <= max) return text

  const cut = text.slice(0, max - 1)
  const lastSpace = cut.lastIndexOf(' ')
  const body = lastSpace > max * 0.6 ? cut.slice(0, lastSpace) : cut
  return `${body.replace(/[\s,;:.!?—–-]+$/, '')}…`
}
