/**
 * Constants re-exported from faithlock-data.ts (single source of truth)
 * This file exists for backward compatibility with existing imports.
 */
import {
  SITE,
  PLATFORM,
  PRICING,
  COPY,
  COMPANY,
  FEATURES,
  APP_METRICS,
  INDUSTRY_STATS,
  displayMetric,
} from './faithlock-data'

export const SITE_URL = SITE.url
export const APP_STORE_URL = SITE.appStoreUrl
export const OFFICIAL_APP_STORE_URL = 'https://apps.apple.com/us/app/faith-lock-bible-prayer-focus/id6754208209'
export const SITE_NAME = SITE.name
export const SITE_TAGLINE = COPY.tagline
export const SITE_DESCRIPTION = COPY.description

// Backward-compatible stats object
// Only expose real or properly sourced data
export const FAITHLOCK_STATS = {
  // Industry stat, NOT a FaithLock claim
  phoneChecksPerDay: String(INDUSTRY_STATS.phoneChecksPerDay.value),

  // Real app data - Complete Bible
  versesInLibrary: 'Complete Bible',
  versesCount: '31K+', // For numeric displays (BSB translation)
  unlockTime: FEATURES.bibleVerseUnlock.unlockTime,
  platforms: [...PLATFORM.available],

  // Current listing prices; billing periods are intentionally not inferred.
  price: {
    displayed: [...PRICING.displayedPrices],
    periodsVerified: PRICING.periodsVerified,
  },

  // Conditional display - only show if we have real numbers
  users: displayMetric(APP_METRICS.users, 1000),
  rating: APP_METRICS.rating ? String(APP_METRICS.rating) : null,
  reviewCount: displayMetric(APP_METRICS.reviewCount, 50),
} as const

// Re-export features
export const APP_FEATURES = [
  {
    icon: 'book',
    title: FEATURES.bibleVerseUnlock.name,
    description: FEATURES.bibleVerseUnlock.description,
  },
  {
    icon: 'shield',
    title: FEATURES.appBlocking.name,
    description: FEATURES.appBlocking.description,
  },
  {
    icon: 'clock',
    title: FEATURES.scheduledLocks.name,
    description: FEATURES.scheduledLocks.description,
  },
  {
    icon: 'flame',
    title: FEATURES.streakTracking.name,
    description: FEATURES.streakTracking.description,
  },
  {
    icon: 'chart',
    title: FEATURES.screenTimeInsights.name,
    description: FEATURES.screenTimeInsights.description,
  },
  {
    icon: 'bell',
    title: FEATURES.prayerReminders.name,
    description: FEATURES.prayerReminders.description,
  },
] as const

export const HOW_IT_WORKS = COPY.howItWorks

export const TARGET_AUDIENCE = [
  'Christians struggling with phone addiction',
  "Anyone who wants more time in God's Word",
  'Parents teaching kids healthy phone habits',
  'Young adults building spiritual discipline',
  'Anyone who reaches for their phone before their Bible',
] as const

export const NAV_LINKS = [
  { label: 'Resources', href: '/resources' },
  { label: 'Compare', href: '/compare' },
] as const

export { COMPANY, PRICING, INDUSTRY_STATS, COPY, displayMetric }
