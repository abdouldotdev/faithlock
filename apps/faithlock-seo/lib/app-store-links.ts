export const OFFICIAL_FAITHLOCK_APP_STORE_URL =
  'https://apps.apple.com/us/app/faithlock/id6754208209'

/**
 * Return a safe App Store destination. FaithLock always resolves to the
 * verified official listing; every other Apple App Store URL is suppressed.
 * Non-App-Store destinations are returned unchanged.
 */
export function normalizeAppStoreUrl(href: string): string | null {
  let url: URL
  try {
    url = new URL(href)
  } catch {
    return href
  }

  if (url.hostname !== 'apps.apple.com') return href

  const isOfficialId = /\/id6754208209(?:[/?#]|$)/.test(url.pathname)
  const namesFaithLock = /(?:^|\/)faithlock(?:\/|$)/i.test(url.pathname)

  return isOfficialId || namesFaithLock ? OFFICIAL_FAITHLOCK_APP_STORE_URL : null
}

/**
 * Remove competitor App Store anchors from rendered CMS/Markdown HTML while
 * keeping their visible label. This protects already-published Contentful
 * entries as well as repository content.
 */
export function sanitizeAppStoreLinksInHtml(html: string): string {
  return html.replace(
    /<a\b([^>]*?)href=(['"])(https:\/\/apps\.apple\.com[^'"]*)\2([^>]*)>([\s\S]*?)<\/a>/gi,
    (_match, before: string, quote: string, href: string, after: string, label: string) => {
      const destination = normalizeAppStoreUrl(href)
      return destination
        ? `<a${before}href=${quote}${destination}${quote}${after}>${label}</a>`
        : label
    },
  )
}
