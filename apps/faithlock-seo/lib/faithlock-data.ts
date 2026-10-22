/**
 * FAITHLOCK - Single Source of Truth
 * ===================================
 * ALL app data used across the SEO site lives here.
 * Update this file when real metrics change.
 *
 * Last updated: 2026-01-31
 *
 * RULES:
 * - Never fabricate user counts, reviews, or ratings
 * - Industry stats must include source
 * - App claims must be verifiable
 * - Use framing language (see COPY section) instead of fake numbers
 */

// ─── PRICING ────────────────────────────────────────────────
export const PRICING = {
  model: 'free download with in-app purchases' as const,
  displayedPrices: [] as const,
  periodsVerified: false as const,
} as const

// ─── PLATFORM ───────────────────────────────────────────────
export const PLATFORM = {
  available: ['iPhone', 'iPad'] as const,
  minVersion: 'iOS 13.0+',
  appStoreUrl: 'https://pim.ms/kTxgKF4',
  requiresScreenTimeAPI: true,
} as const

// ─── APP FEATURES (verifiable from the actual app) ──────────
export const FEATURES = {
  bibleVerseUnlock: {
    name: 'Prayer and Bible Verse Unlock',
    description: 'Read Bible verses and pray before accessing selected apps',
    unlockTime: '~30 seconds',
  },
  appBlocking: {
    name: 'Custom App Blocking',
    description: 'Choose which apps to lock: social media, games, browsers',
  },
  streakTracking: {
    name: 'Streak Tracking',
    description: 'Track your daily consistency with verse reading',
  },
  screenTimeInsights: {
    name: 'Faith Insights and Stats',
    description: 'Track screen time saved and verses read',
  },
  spiritualCovenant: {
    name: '30-Day Spiritual Covenant',
    description: 'Commit to 30 days of replacing scrolling with Scripture',
  },
  scheduledLocks: {
    name: 'Scheduled Lock Times',
    description: 'Auto-lock during morning devotion, work hours, or family time',
  },
  prayerReminders: {
    name: 'Prayer Reminders',
    description: 'Gentle nudges to pause and pray throughout your day',
  },
} as const

// ─── INDUSTRY STATISTICS (with sources - these are NOT FaithLock stats) ──
// Use these for educational content, NOT as FaithLock claims
export const INDUSTRY_STATS = {
  phoneChecksPerDay: {
    value: 96,
    label: '96 times/day',
    description: 'Average phone checks per day',
    source: 'Asurion, 2023',
  },
  averageScreenTime: {
    value: '7+ hours',
    description: 'Average daily screen time for US adults',
    source: 'DataReportal, 2024',
  },
  socialMediaTime: {
    value: '2h 23min',
    description: 'Average daily social media time',
    source: 'DataReportal, 2024',
  },
  phoneAddictionRate: {
    value: '57%',
    description: 'Of Americans consider themselves addicted to their phones',
    source: 'Reviews.org, 2023',
  },
  screenTimeReductionWithTools: {
    value: '20-30%',
    description: 'Typical screen time reduction with blocking tools',
    source: 'Journal of Behavioral Addictions, 2022',
  },
} as const

// ─── REAL APP METRICS ───────────────────────────────────────
// Only include what's actually true. Update as the app grows.
export const APP_METRICS = {
  // Set to null when we don't have meaningful numbers to show
  // This prevents us from displaying embarrassingly small or fake numbers
  users: null as number | null, // Don't display until meaningful (1,000+)
  rating: null as number | null, // Don't display until 50+ reviews
  reviewCount: null as number | null, // Don't display until 50+ reviews
  downloads: null as number | null, // Don't display until meaningful

  // Things we CAN verify from the app itself
  versesInLibrary: 31102, // Complete Bible - all verses available
  bibleTranslation: 'BSB',
  versesLabel: 'Complete Bible library (BSB)', // For display purposes
} as const

// ─── COPY & FRAMING ────────────────────────────────────────
// Strategic copy that's honest but compelling - no fake numbers
export const COPY = {
  tagline: 'Stop scrolling. Start Scripture.',
  subtitle: 'Turn phone addiction into daily devotion.',
  description:
    'FaithLock blocks distracting apps and unlocks them with Bible verses—building a consistent Scripture habit without relying on willpower alone.',

  // CTA copy - no fake user counts
  ctaPrimary: 'Try FaithLock Free',
  ctaSecondary: 'Get the App',

  // Social proof without fake numbers
  // Use these INSTEAD of "Join 25,000+ Christians"
  socialProof: {
    // When we have no meaningful user count:
    noNumbers: 'Join Christians replacing scrolling with Scripture',
    // When we reach 1,000+:
    withNumbers: (count: string) =>
      `Join ${count} Christians replacing scrolling with Scripture`,
  },

  // Value props - factual, no inflated claims
  valueProps: [
    'Replace mindless scrolling with daily Scripture',
    'Build a consistent Bible habit in 30 seconds a day',
    'Block any app and unlock it with a verse',
  ],

  // How it works - factual
  howItWorks: [
    {
      step: '1',
      title: 'Choose Your Distractions',
      description:
        'Lock social media, games, shopping—anything stealing your attention.',
    },
    {
      step: '2',
      title: 'Unlock with Scripture',
      description:
        'Read a Bible verse to access your apps. Takes about 30 seconds.',
    },
    {
      step: '3',
      title: 'Build the Habit',
      description:
        'Track your streak and watch your Scripture habit grow day by day.',
    },
  ],
} as const

// ─── COMPANY ────────────────────────────────────────────────
export const COMPANY = {
  name: 'Appbiz Studio, LLC',
  email: 'hey@appbiz.studio',
  privacyUrl: '/privacy',
  termsUrl: '/terms',
  dataDeletionUrl: '/request-data-delete',
} as const

// ─── SEO SITE CONFIG ────────────────────────────────────────
export const SITE = {
  name: 'FaithLock',
  url: process.env.NEXT_PUBLIC_SITE_URL || 'https://www.getfaithlock.com',
  appStoreUrl:
    process.env.NEXT_PUBLIC_APP_STORE_URL || PLATFORM.appStoreUrl,
} as const

// ─── HELPER: should we show a metric? ──────────────────────
// Returns the value only if it's meaningful enough to display
export function displayMetric(
  value: number | null,
  threshold: number
): string | null {
  if (value === null || value < threshold) return null
  if (value >= 1_000_000) return `${(value / 1_000_000).toFixed(1)}M+`
  if (value >= 1_000) return `${(value / 1_000).toFixed(0)}K+`
  return `${value}+`
}

// ─── COMPARISON DATA (FaithLock's real features for /compare) ──
export const FAITHLOCK_COMPARISON = {
  name: 'FaithLock',
  price: 'In-app purchases shown in the App Store listing',
  pricingModel: 'Free download with in-app purchases; billing periods are not stated in the registry',
  platforms: PLATFORM.available,
  features: {
    bibleQuiz: false, // We do verse reading, not quiz
    bibleVerseUnlock: true, // Our core feature
    screenTimeTracking: true,
    appBlocking: true,
    customScheduling: true,
    streakTracking: true,
    spiritualCovenant: true,
    prayerReminders: true,
    androidSupport: false,
    accountabilityPartner: false, // Not yet
  },
} as const

// ─── COMPARISON PROS/CONS (used in ComparisonTemplate) ──────
export const FAITHLOCK_PROS = [
  'Bible verse unlocking ensures genuine Scripture engagement',
  '30-day spiritual covenant for building consistent habits',
  'Streak tracking and insights dashboard',
  'Scheduled lock times for daily routines',
  'Prayer reminders throughout the day',
  'Active development and community support',
] as const

export const FAITHLOCK_CONS = [
  'Available on iPhone and iPad',
  'Newer app (less brand awareness)',
  'Requires iOS 13.0+ according to the verified listing',
] as const

// ─── BIBLE VERSES (used across the site for decoration) ─────
export const FEATURED_VERSES = [
  {
    reference: 'Philippians 4:8',
    text: 'Finally, brothers and sisters, whatever is true, whatever is noble, whatever is right, whatever is pure, whatever is lovely, whatever is admirable—if anything is excellent or praiseworthy—think about such things.',
  },
  {
    reference: 'Psalm 119:37',
    text: 'Turn my eyes away from worthless things; preserve my life according to your word.',
  },
  {
    reference: 'Proverbs 25:28',
    text: 'Like a city whose walls are broken through is a person who lacks self-control.',
  },
  {
    reference: 'Colossians 3:2',
    text: 'Set your minds on things above, not on earthly things.',
  },
  {
    reference: '1 Corinthians 6:12',
    text: '"I have the right to do anything," you say—but not everything is beneficial. "I have the right to do anything"—but I will not be mastered by anything.',
  },
  {
    reference: 'Ephesians 5:15-16',
    text: 'Be very careful, then, how you live—not as unwise but as wise, making the most of every opportunity.',
  },
] as const
