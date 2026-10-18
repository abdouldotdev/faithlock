import { GlossaryTerm } from '@/lib/types'
import { APP_STORE_URL } from '@/lib/constants'
import BibleVerse from '@/components/ui/BibleVerse'
import CTAButton from '@/components/ui/CTAButton'
import RichText, { stripMarkdown } from '@/components/ui/RichText'
import TemplateTracker from '@/components/templates/TemplateTracker'
import ResourceStoreClickTracker from '@/components/templates/ResourceStoreClickTracker'
import TableOfContents from '@/components/seo/TableOfContents'
import ReadingTime from '@/components/seo/ReadingTime'
import SubtleCallout from '@/components/seo/SubtleCallout'
import BreadcrumbSchema from '@/components/seo/BreadcrumbSchema'

interface GlossaryTemplateProps {
  term: GlossaryTerm
  updatedAt: string
}

// Categories that use "What is X?" format (glossary definitions)
const DEFINITION_CATEGORIES = ['General', 'Understanding Addiction', 'Digital Wellness', 'Spiritual Disciplines', 'Practical Solutions']

function isDefinitionPage(category: string): boolean {
  return DEFINITION_CATEGORIES.includes(category)
}

function estimateWordCount(term: GlossaryTerm): number {
  const text = [
    stripMarkdown(term.shortDefinition),
    stripMarkdown(term.detailedExplanation),
    term.christianPerspective ? stripMarkdown(term.christianPerspective) : '',
    ...(term.faqs && Array.isArray(term.faqs) ? term.faqs : []).map((f) => `${f.question} ${f.answer}`),
  ].join(' ')
  return text.split(/\s+/).filter(Boolean).length
}

function formatDate(dateString: string): string {
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', { month: 'short', year: 'numeric' })
}

export default function GlossaryTemplate({ term, updatedAt }: GlossaryTemplateProps) {
  const wordCount = estimateWordCount(term)
  const isDefinition = isDefinitionPage(term.category)
  const hasChristianPerspective = term.christianPerspective && stripMarkdown(term.christianPerspective).trim().length > 10
  const hasFaqs = term.faqs && Array.isArray(term.faqs) && term.faqs.length > 0
  const hasStats = term.statistics && Array.isArray(term.statistics) && term.statistics.length > 0
  const hasRelated = term.relatedTerms && Array.isArray(term.relatedTerms) && term.relatedTerms.length > 0
  const hasBibleVerses = term.bibleVerses && Array.isArray(term.bibleVerses) && term.bibleVerses.length > 0

  // Build TOC dynamically based on what content exists
  const tocItems = [
    ...(isDefinition
      ? [{ id: 'understanding', text: `Understanding ${term.term}` }]
      : [{ id: 'content', text: term.term }]
    ),
    ...(hasChristianPerspective
      ? [{ id: 'biblical-view', text: 'Biblical Perspective' }]
      : []),
    ...(hasStats
      ? [{ id: 'statistics', text: 'Statistics & Research' }]
      : []),
    ...(hasFaqs
      ? [{ id: 'faqs', text: 'Frequently Asked Questions' }]
      : []),
    ...(hasRelated
      ? [{ id: 'related', text: 'Related Topics' }]
      : []),
  ]

  return (
    <article className="cozy-page">
      <TemplateTracker type="glossary" slug={term.slug} />
      <ResourceStoreClickTracker />
      <BreadcrumbSchema
        items={[
          { name: 'Home', url: '/' },
          { name: 'Resources', url: '/resources' },
          { name: term.term, url: `/resources/${term.slug}` },
        ]}
      />

      {/* Hero */}
      <div className="cozy-hero">
        <div className="container-default py-14 md:py-20">
          <nav className="cozy-breadcrumb mb-8">
            <a href="/">Home</a>
            <span className="cozy-breadcrumb-separator">/</span>
            <a href="/resources">Resources</a>
            <span className="cozy-breadcrumb-separator">/</span>
            <span>{term.term}</span>
          </nav>

          <div className="flex items-center gap-3 mb-4">
            <span className="cozy-badge-peach">{term.category}</span>
            <ReadingTime wordCount={wordCount} />
            <span className="text-sm text-cozy-ink-muted">Updated {formatDate(updatedAt)}</span>
          </div>

          {/* H1: adaptive based on category */}
          <h1 className="text-3xl sm:text-4xl md:text-5xl font-bold mb-6 tracking-tight leading-tight text-cozy-ink">
            {isDefinition ? `What is ${term.term}?` : term.term}
          </h1>

          {/* Quick summary — only for definitions, or when shortDefinition is meaningfully different from body */}
          {term.shortDefinition && stripMarkdown(term.shortDefinition).length > 20 && (
            <div className="cozy-card p-6 max-w-2xl">
              <p className="text-sm font-semibold text-cozy-primary-dark mb-2 uppercase tracking-wide">
                {isDefinition ? 'Quick Definition' : 'Summary'}
              </p>
              <p className="text-cozy-ink/85 leading-relaxed">
                {stripMarkdown(term.shortDefinition)}
              </p>
            </div>
          )}
        </div>
      </div>

      <div className="container-narrow py-12 md:py-16">
        {/* Table of Contents */}
        <TableOfContents items={tocItems} />

        {/* Main Content */}
        <section id={isDefinition ? 'understanding' : 'content'} className="mb-16 md:mb-20">
          {isDefinition && (
            <h2 className="text-2xl md:text-3xl font-bold mb-6 text-cozy-ink">
              Understanding {term.term}
            </h2>
          )}
          <RichText
            content={term.detailedExplanation}
            className="prose-cozy"
          />
        </section>

        {/* Christian Perspective — only if content exists */}
        {hasChristianPerspective && (
          <section id="biblical-view" className="mb-16 md:mb-20 bg-cozy-surface-muted text-cozy-ink border-[2.5px] border-cozy-ink rounded-cozy-lg shadow-cozy-hard p-8 md:p-12">
            <span className="cozy-badge mb-4">Christian Perspective</span>
            <h2 className="text-2xl md:text-3xl font-bold mb-6 text-cozy-ink">
              A Biblical View of {term.term}
            </h2>
            <RichText
              content={term.christianPerspective}
              className="prose-cozy"
            />
            {hasBibleVerses && (
              <div className="space-y-4 mt-8">
                <h3 className="text-lg font-bold text-cozy-ink">Biblical Foundation</h3>
                {term.bibleVerses.map((verse, i) => (
                  <BibleVerse key={i} reference={verse.reference} text={verse.text} />
                ))}
              </div>
            )}
          </section>
        )}

        {/* Statistics */}
        {hasStats && (
          <section id="statistics" className="mb-16 md:mb-20">
            <h2 className="text-2xl md:text-3xl font-bold mb-8 text-cozy-ink">
              Statistics &amp; Research
            </h2>
            <div className="grid sm:grid-cols-2 gap-4">
              {term.statistics!.map((stat, i) => (
                <div key={i} className="cozy-card p-6">
                  <p className="text-lg font-bold text-cozy-ink mb-2 leading-snug">
                    {stat.stat}
                  </p>
                  <p className="text-xs text-cozy-ink-muted">Source: {stat.source}</p>
                </div>
              ))}
            </div>
          </section>
        )}

        {/* FAQs */}
        {hasFaqs && (
          <section id="faqs" className="mb-16 md:mb-20">
            <h2 className="text-2xl md:text-3xl font-bold mb-8 text-cozy-ink">
              Frequently Asked Questions
            </h2>
            <div className="space-y-3">
              {term.faqs.map((faq, i) => (
                <details key={i} className="cozy-card p-5 md:p-6 cozy-faq">
                  <summary className="font-semibold text-cozy-ink cursor-pointer">
                    {faq.question}
                  </summary>
                  <p className="mt-4 text-cozy-ink/85 leading-relaxed text-sm">
                    {faq.answer}
                  </p>
                </details>
              ))}
            </div>
          </section>
        )}

        {/* Subtle product mention */}
        <SubtleCallout />

        {/* CTA */}
        <section className="bg-cozy-primary text-white border-[2.5px] border-cozy-ink rounded-cozy-lg shadow-cozy-hard-lg p-10 md:p-16 text-center mb-16">
          <h2 className="text-2xl md:text-4xl font-bold mb-4 text-balance">
            Start building a daily Scripture habit
          </h2>
          <p className="text-lg mb-8 text-white/80">
            Join Christians replacing scrolling with Scripture.
          </p>
          <CTAButton
            text="Try FaithLock Free"
            href={APP_STORE_URL}
            variant="white"
            size="large"
            showAppleIcon
            trackingLocation="glossary_cta"
          />
        </section>

        {/* Related */}
        {hasRelated && (
          <section id="related">
            <h2 className="text-xl font-bold mb-6 text-cozy-ink">Related Topics</h2>
            <div className="grid sm:grid-cols-3 gap-4">
              {term.relatedTerms!.map((slug, i) => {
                const displayName = slug
                  .split('-')
                  .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
                  .join(' ')
                return (
                  <a key={i} href={`/resources/${slug}`} className="cozy-card-interactive p-5">
                    <h3 className="font-semibold text-cozy-ink text-sm">{displayName}</h3>
                    <p className="text-xs text-cozy-ink-muted mt-1">
                      Learn about {displayName.toLowerCase()}
                    </p>
                  </a>
                )
              })}
            </div>
          </section>
        )}
      </div>
    </article>
  )
}
