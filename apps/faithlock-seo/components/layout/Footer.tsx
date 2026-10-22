import { getAllContentForFooter } from '@/lib/contentful'
import { OFFICIAL_APP_STORE_URL, COMPANY } from '@/lib/constants'

// Top Bible Verse topics by search volume
const TOP_BIBLE_VERSES = [
  'bible-verses-about-love',
  'bible-verses-about-strength',
  'bible-verses-about-encouragement',
  'bible-verses-about-anxiety',
  'bible-verses-about-healing',
  'bible-verses-about-peace',
  'bible-verses-about-forgiveness',
  'bible-verses-about-faith',
  'bible-verses-about-hope',
  'bible-verses-about-depression',
  'bible-verses-about-patience',
  'bible-verses-about-anger',
]

// Top Prayers by search volume
const TOP_PRAYERS = [
  'prayer-for-anxiety',
  'prayer-for-strength',
  'prayer-for-healing',
  'prayer-for-peace',
  'prayer-for-guidance',
  'prayer-for-protection',
  'prayer-for-forgiveness',
  'prayer-for-courage',
  'prayer-for-patience',
  'prayer-for-wisdom',
  'prayer-for-phone-addiction',
  'prayer-for-stress',
]

export default async function Footer() {
  const content = await getAllContentForFooter()

  // Filter glossary terms by priority slugs
  const bibleVerses = TOP_BIBLE_VERSES
    .map(slug => content.glossaryTerms.find(t => t.slug === slug))
    .filter(Boolean) as { slug: string; term: string; category: string }[]

  const prayers = TOP_PRAYERS
    .map(slug => content.glossaryTerms.find(t => t.slug === slug))
    .filter(Boolean) as { slug: string; term: string; category: string }[]

  // Top comparisons (first 12) — clean up display names
  const topComparisons = content.competitors.slice(0, 12).map(comp => ({
    ...comp,
    displayName: comp.name
      .replace(/^faithlock-vs-/i, '')
      .replace(/-/g, ' ')
      .replace(/\b\w/g, c => c.toUpperCase()),
  }))

  return (
    <footer className="bg-cozy-cream text-cozy-ink border-t-[2.5px] border-cozy-ink">
      {/* ─── Top section: Brand + Meta Links ─── */}
      <div className="container-wide pt-16 pb-12">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-10 md:gap-8">
          {/* Brand */}
          <div>
            <div className="flex items-center gap-2.5 mb-4">
              <div className="w-8 h-8 bg-cozy-peach border-[1.5px] border-cozy-ink rounded-lg flex items-center justify-center">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#3D2B1F" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
                </svg>
              </div>
              <span className="text-lg font-bold text-cozy-ink">FaithLock</span>
            </div>
            <p className="text-sm text-cozy-ink-muted leading-relaxed mb-5">
              Stop scrolling. Start Scripture. Turn phone addiction into daily devotion.
            </p>
            <a
              href={OFFICIAL_APP_STORE_URL}
              data-store-location="footer"
              className="inline-flex items-center gap-2 bg-cozy-primary text-white border-[2.5px] border-cozy-ink shadow-cozy-hard px-4 py-2.5 rounded-full font-bold text-sm transition-all duration-150 hover:-translate-x-0.5 hover:-translate-y-0.5 hover:shadow-cozy-hard-lg"
              target="_blank"
              rel="noopener noreferrer"
            >
              <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
              </svg>
              Download on App Store
            </a>
            <p className="mt-2 text-xs text-cozy-ink-muted">Free &middot; iOS 13.0 or later</p>
            <p className="mt-5 text-xs text-cozy-ink-muted">
              &copy; {new Date().getFullYear()} {COMPANY.name}
            </p>
          </div>

          {/* Product */}
          <div>
            <h4 className="font-bold text-cozy-ink text-sm mb-4">Product</h4>
            <ul className="space-y-2.5 text-sm">
              <li><a href="/resources" className="text-cozy-ink-muted hover:text-cozy-primary transition-colors">Resources</a></li>
              <li><a href="/compare" className="text-cozy-ink-muted hover:text-cozy-primary transition-colors">Comparisons</a></li>
              <li><a href="/features" className="text-cozy-ink-muted hover:text-cozy-primary transition-colors">Features</a></li>
              <li><a href={`mailto:${COMPANY.email}`} className="text-cozy-ink-muted hover:text-cozy-primary transition-colors">Contact</a></li>
            </ul>
          </div>

          {/* Company */}
          <div>
            <h4 className="font-bold text-cozy-ink text-sm mb-4">Company</h4>
            <ul className="space-y-2.5 text-sm">
              <li><a href={COMPANY.privacyUrl} className="text-cozy-ink-muted hover:text-cozy-primary transition-colors">Privacy Policy</a></li>
              <li><a href={COMPANY.termsUrl} className="text-cozy-ink-muted hover:text-cozy-primary transition-colors">Terms of Use</a></li>
              <li><a href={COMPANY.dataDeletionUrl} className="text-cozy-ink-muted hover:text-cozy-primary transition-colors">Request Data Deletion</a></li>
              <li><a href={`mailto:${COMPANY.email}`} className="text-cozy-ink-muted hover:text-cozy-primary transition-colors">Support</a></li>
            </ul>
          </div>

          {/* Connect */}
          <div>
            <h4 className="font-bold text-cozy-ink text-sm mb-4">Connect</h4>
            <ul className="space-y-2.5 text-sm">
              <li>
                <a href={`mailto:${COMPANY.email}`} className="text-cozy-ink-muted hover:text-cozy-primary transition-colors">
                  {COMPANY.email}
                </a>
              </li>
            </ul>
          </div>
        </div>
      </div>

      {/* ─── Bottom section: Top content by category ─── */}
      <div className="border-t border-cozy-border">
        <div className="container-wide py-12">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-10 md:gap-8">
            {/* Bible Verses */}
            <div>
              <h4 className="font-bold text-cozy-ink text-sm mb-4">Bible Verses</h4>
              <ul className="space-y-2 text-sm">
                {bibleVerses.map((item) => (
                  <li key={item.slug}>
                    <a
                      href={`/resources/${item.slug}`}
                      className="text-cozy-ink-muted hover:text-cozy-primary transition-colors leading-snug block"
                    >
                      {item.term}
                    </a>
                  </li>
                ))}
                <li>
                  <a href="/resources" className="text-cozy-primary-dark hover:text-cozy-primary transition-colors font-bold">
                    All Bible Verses &rarr;
                  </a>
                </li>
              </ul>
            </div>

            {/* Prayers */}
            <div>
              <h4 className="font-bold text-cozy-ink text-sm mb-4">Prayers</h4>
              <ul className="space-y-2 text-sm">
                {prayers.map((item) => (
                  <li key={item.slug}>
                    <a
                      href={`/resources/${item.slug}`}
                      className="text-cozy-ink-muted hover:text-cozy-primary transition-colors leading-snug block"
                    >
                      {item.term}
                    </a>
                  </li>
                ))}
                <li>
                  <a href="/resources" className="text-cozy-primary-dark hover:text-cozy-primary transition-colors font-bold">
                    All Prayers &rarr;
                  </a>
                </li>
              </ul>
            </div>

            {/* Comparisons */}
            <div>
              <h4 className="font-bold text-cozy-ink text-sm mb-4">Comparisons</h4>
              <ul className="space-y-2 text-sm">
                {topComparisons.map((comp) => (
                  <li key={comp.slug}>
                    <a
                      href={`/compare/${comp.slug}`}
                      className="text-cozy-ink-muted hover:text-cozy-primary transition-colors leading-snug block"
                    >
                      FaithLock vs {comp.displayName}
                    </a>
                  </li>
                ))}
                <li>
                  <a href="/compare" className="text-cozy-primary-dark hover:text-cozy-primary transition-colors font-bold">
                    All Comparisons &rarr;
                  </a>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </footer>
  )
}
