import { Metadata } from 'next'
import { notFound } from 'next/navigation'
import { getAllGlossaryTerms, getGlossaryTermBySlug } from '@/lib/contentful'
import { GlossaryTerm } from '@/lib/types'
import { SITE_URL } from '@/lib/constants'
import GlossaryTemplate from '@/components/templates/GlossaryTemplate'
import SchemaMarkup from '@/components/seo/SchemaMarkup'
import { headers } from 'next/headers'

const SUPPRESS_CTA_HEADER = 'x-faithlock-suppress-global-store-ctas'

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
  const description = fields.seoDescription

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
  const suppressStoreCta = headers().get(SUPPRESS_CTA_HEADER) === '1'

  const articleSchema = {
    '@context': 'https://schema.org',
    '@type': 'Article',
    headline: fields.seoTitle,
    description: fields.seoDescription,
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
      <GlossaryTemplate term={fields} updatedAt={entry.sys.updatedAt} suppressStoreCta={suppressStoreCta} />
    </>
  )
}
