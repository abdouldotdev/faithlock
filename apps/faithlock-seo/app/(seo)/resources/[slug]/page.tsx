import { Metadata } from 'next'
import { notFound } from 'next/navigation'
import { getAllGlossaryTerms, getGlossaryTermBySlug } from '@/lib/contentful'
import { GlossaryTerm } from '@/lib/types'
import { SITE_URL } from '@/lib/constants'
import { toMetaDescription } from '@/lib/meta-description'
import GlossaryTemplate from '@/components/templates/GlossaryTemplate'
import SchemaMarkup from '@/components/seo/SchemaMarkup'

export async function generateStaticParams() {
  const terms = await getAllGlossaryTerms()
  return terms.map((t) => ({ slug: t.fields.slug as string }))
}

export async function generateMetadata({
  params,
}: {
  params: { slug: string }
}): Promise<Metadata> {
  const entry = await getGlossaryTermBySlug(params.slug)

  if (!entry) {
    return { title: 'Term Not Found' }
  }

  const fields = entry.fields as unknown as GlossaryTerm
  const year = new Date().getFullYear()
  const title = fields.seoTitle || `What is ${fields.term}? Christian Guide (${year})`
  // Five glossary entries ship without seoDescription, so Production served no
  // meta description on those URLs (measured 2026-11-11). shortDefinition is the
  // entry's own summary, already rendered on the page — reuse it, bounded to
  // the snippet length, rather than inventing copy.
  const description =
    toMetaDescription(fields.seoDescription) ?? toMetaDescription(fields.shortDefinition)

  return {
    title,
    description,
    openGraph: {
      title,
      description,
      type: 'article',
      url: `${SITE_URL}/resources/${fields.slug}`,
    },
    twitter: {
      card: 'summary_large_image',
      title,
      description,
    },
    alternates: {
      canonical: `/resources/${fields.slug}`,
    },
  }
}

export default async function LearnSlugPage({
  params,
}: {
  params: { slug: string }
}) {
  const entry = await getGlossaryTermBySlug(params.slug)

  if (!entry) {
    notFound()
  }

  const fields = entry.fields as unknown as GlossaryTerm

  const articleSchema = {
    '@context': 'https://schema.org',
    '@type': 'Article',
    headline: fields.seoTitle?.trim() || `What is ${fields.term}?`,
    description:
      toMetaDescription(fields.seoDescription) ?? toMetaDescription(fields.shortDefinition),
    author: { '@type': 'Organization', name: 'FaithLock' },
    publisher: {
      '@type': 'Organization',
      name: 'FaithLock',
      logo: { '@type': 'ImageObject', url: `${SITE_URL}/logo.png` },
    },
    datePublished: entry.sys.createdAt,
    dateModified: entry.sys.updatedAt,
    mainEntityOfPage: {
      '@type': 'WebPage',
      '@id': `${SITE_URL}/resources/${fields.slug}`,
    },
  }

  const faqSchema =
    fields.faqs && fields.faqs.length > 0
      ? {
          '@context': 'https://schema.org',
          '@type': 'FAQPage',
          mainEntity: fields.faqs.map((faq) => ({
            '@type': 'Question',
            name: faq.question,
            acceptedAnswer: { '@type': 'Answer', text: faq.answer },
          })),
        }
      : null

  const schemas = faqSchema ? [articleSchema, faqSchema] : [articleSchema]

  return (
    <>
      <SchemaMarkup data={schemas} />
      <GlossaryTemplate term={fields} updatedAt={entry.sys.updatedAt} />
    </>
  )
}
