// `faithlock_store_click`: one event per click on a link to the FaithLock App
// Store listing, anywhere on the site. Outbound web click only, never an
// install or a subscription.

const SHORT_LINK = { host: 'pim.ms', path: '/kTxgKF4' }
const FAITHLOCK_APP_ID = 'id6754208209'

export interface StoreClickProperties {
  destination_url: string
  destination_type: 'short_link' | 'app_store'
  location: string
  button_text?: string
  page_path: string
  source: 'resource_page' | 'site'
}

export function storeDestinationType(href: string): StoreClickProperties['destination_type'] | null {
  let url: URL
  try {
    url = new URL(href)
  } catch {
    return null
  }
  if (url.protocol !== 'https:') return null
  if (url.hostname === SHORT_LINK.host && url.pathname === SHORT_LINK.path) return 'short_link'
  if (url.hostname === 'apps.apple.com' && url.pathname.endsWith(`/${FAITHLOCK_APP_ID}`)) return 'app_store'
  return null
}

export function buildStoreClick(
  href: string,
  pagePath: string,
  location: string,
  text?: string,
): StoreClickProperties | null {
  const destination_type = storeDestinationType(href)
  if (!destination_type) return null
  return {
    destination_url: href,
    destination_type,
    location: location || 'content',
    button_text: text || undefined,
    page_path: pagePath,
    source: pagePath.startsWith('/resources/') ? 'resource_page' : 'site',
  }
}

/** Where on the page the link sits: explicit tag, landing CTA id, nearest section, else content. */
export function storeLinkLocation(link: Element): string {
  const el = link as HTMLElement
  return (
    el.dataset?.storeLocation ||
    el.dataset?.trackCta ||
    (link.closest('[data-track-section]') as HTMLElement | null)?.dataset.trackSection ||
    link.closest('section[id]')?.id ||
    'content'
  )
}
