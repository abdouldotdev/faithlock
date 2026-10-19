import posthog from 'posthog-js'
import { buildStoreClick } from '@/lib/store-click'

// ─── Store click (every link to the FaithLock App Store listing) ──
export function trackStoreClick(href: string, location: string, text?: string) {
  const props = buildStoreClick(href, window.location.pathname, location, text)
  if (!props) return
  // Same-tab links navigate away immediately: beacon survives the unload.
  posthog.capture('faithlock_store_click', props, { transport: 'sendBeacon' })
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
