import posthog from 'posthog-js'
import { APP_STORE_URL } from '@/lib/constants'

// ─── Store click (every link to the FaithLock App Store listing) ──
// Matches the tracked short link and the raw App Store listing (any locale).
const FAITHLOCK_STORE_PATTERNS = [
  /^https?:\/\/pim\.ms\/kTxgKF4/i,
  /^https?:\/\/apps\.apple\.com\/.*\/id6754208209/i,
]

export function isFaithLockStoreUrl(href: string): boolean {
  return href === APP_STORE_URL || FAITHLOCK_STORE_PATTERNS.some((re) => re.test(href))
}

export function trackStoreClick(href: string, location: string, text?: string) {
  posthog.capture(
    'faithlock_store_click',
    {
      href,
      location,
      button_text: text,
      url: window.location.pathname,
    },
    // Same-tab links navigate away immediately: beacon survives the unload.
    { transport: 'sendBeacon' }
  )
}

// ─── CTA / Download ─────────────────────────────────────────
export function trackCTAClick(location: string, text?: string) {
  posthog.capture('cta_click', {
    location,
    button_text: text,
    url: window.location.pathname,
  })
}

// ─── Navigation ──────────────────────────────────────────────
export function trackNavClick(label: string, href: string, location: 'header' | 'footer' | 'mobile_menu') {
  posthog.capture('nav_click', {
    label,
    href,
    location,
    url: window.location.pathname,
  })
}

// ─── Internal Link ───────────────────────────────────────────
export function trackInternalLink(href: string, section: string) {
  posthog.capture('internal_link_click', {
    href,
    section,
    url: window.location.pathname,
  })
}

// ─── Outbound Link ───────────────────────────────────────────
export function trackOutboundClick(href: string, label: string) {
  posthog.capture('outbound_click', {
    href,
    label,
    url: window.location.pathname,
  })
}

// ─── FAQ ─────────────────────────────────────────────────────
export function trackFAQOpen(question: string, index: number) {
  posthog.capture('faq_open', {
    question,
    index,
    url: window.location.pathname,
  })
}

// ─── Phone Demo ──────────────────────────────────────────────
export function trackPhoneDemo(action: 'unlock' | 'lock') {
  posthog.capture('phone_demo_interaction', {
    action,
    url: window.location.pathname,
  })
}

// ─── Section View (scroll) ───────────────────────────────────
export function trackSectionView(section: string) {
  posthog.capture('section_view', {
    section,
    url: window.location.pathname,
  })
}

// ─── pSEO Template View ─────────────────────────────────────
export function trackTemplateView(type: 'comparison' | 'feature' | 'glossary', slug: string) {
  posthog.capture('template_view', {
    type,
    slug,
    url: window.location.pathname,
  })
}
