const RESOURCE_SLUGS = new Set([
  'best-bible-verse-lock-screen-apps',
  'best-christian-app-blocker',
])

const OFFICIAL_APP_ID = '6754208209'
const SHORT_LINK_PATH = '/kTxgKF4'

export interface ResourceStoreClickInput {
  href: string
  pagePath: string
  position: number
  section: string
}

export interface ResourceStoreClickProperties {
  cta_id: string
  page_path: string
  link_position: string
  market: 'US'
  source: 'resource_page'
  destination_url: string
  destination_type: 'short_link' | 'app_store'
}

/** A store click is a web outbound-click proxy, never an install or subscription. */
export function buildResourceStoreClick({ href, pagePath, position, section }: ResourceStoreClickInput): ResourceStoreClickProperties | null {
  const match = /^\/resources\/([^/]+)\/?$/.exec(pagePath)
  const slug = match?.[1]
  if (!slug || !RESOURCE_SLUGS.has(slug) || !Number.isInteger(position) || position < 1) return null

  let url: URL
  try {
    url = new URL(href)
  } catch {
    return null
  }
  if (url.protocol !== 'https:' || url.username || url.password) return null

  let destination_type: ResourceStoreClickProperties['destination_type']
  if (url.hostname === 'pim.ms' && url.pathname === SHORT_LINK_PATH) {
    destination_type = 'short_link'
  } else if (url.hostname === 'apps.apple.com' && new RegExp(`/id${OFFICIAL_APP_ID}$`).test(url.pathname)) {
    destination_type = 'app_store'
  } else {
    return null
  }

  return {
    cta_id: `${slug}_store_${position}`,
    page_path: pagePath,
    link_position: section || 'unknown',
    market: 'US',
    source: 'resource_page',
    destination_url: url.href,
    destination_type,
  }
}

/** Count only eligible anchors inside the article, never a dynamic header/menu. */
export function getArticleStoreClick(
  article: Pick<Element, 'contains' | 'querySelectorAll'>,
  anchor: HTMLAnchorElement,
  pagePath: string,
): ResourceStoreClickProperties | null {
  if (!article.contains(anchor)) return null
  const links = Array.from(article.querySelectorAll<HTMLAnchorElement>('a[href]'))
  const eligible = links.filter((link) => buildResourceStoreClick({
    href: link.href, pagePath, position: 1, section: 'unknown',
  }) !== null)
  const position = eligible.indexOf(anchor) + 1
  if (position < 1) return null
  return buildResourceStoreClick({
    href: anchor.href,
    pagePath,
    position,
    section: anchor.closest('section[id]')?.id || 'unknown',
  })
}
