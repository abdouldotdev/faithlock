import { Metadata } from 'next'
import { notFound } from 'next/navigation'
import { getAllCompetitors, getCompetitorBySlug } from '@/lib/contentful'
import { Competitor } from '@/lib/types'
import { SITE_URL } from '@/lib/constants'
import ComparisonTemplate from '@/components/templates/ComparisonTemplate'
import SchemaMarkup from '@/components/seo/SchemaMarkup'
import {
  getComparisonDescription,
  getComparisonTitle,
  getCompetitorDisplayName,
} from '@/lib/compare-metadata'

export async function generateStaticParams() {
  const competitors = await getAllCompetitors()
  return competitors.map((c) => {
    const slug = c.fields.slug as string
    return {
      slug: slug.startsWith('faithlock-vs-') ? slug : `faithlock-vs-${slug}`,
    }
  })
}

export async function generateMetadata({
  params,
}: {
  params: { slug: string }
}): Promise<Metadata> {
  // Certaines entrées Contentful portent déjà le préfixe dans leur slug, d'autres non.
  // Retirer le préfixe systématiquement faisait 404 les premières (opal, freedom,
  // cold-turkey, appblock), pourtant listées au sitemap. On essaie les deux formes.
  const competitorSlug = params.slug.replace('faithlock-vs-', '')
  const entry =
    (await getCompetitorBySlug(competitorSlug)) ??
    (await getCompetitorBySlug(params.slug))

  if (!entry) {
    return { title: 'Comparison Not Found' }
  }

  const fields = entry.fields as unknown as Competitor
  const title = getComparisonTitle(fields, params.slug)
  const description = getComparisonDescription(fields, params.slug)

  return {
    title,
    description,
    openGraph: {
      title,
      description,
      type: 'article',
      url: `${SITE_URL}/compare/${params.slug}`,
    },
    twitter: {
      card: 'summary_large_image',
      title,
      description,
    },
    alternates: {
      canonical: `/compare/${params.slug}`,
    },
  }
}

export default async function ComparisonPage({
  params,
}: {
  params: { slug: string }
}) {
  // Certaines entrées Contentful portent déjà le préfixe dans leur slug, d'autres non.
  // Retirer le préfixe systématiquement faisait 404 les premières (opal, freedom,
  // cold-turkey, appblock), pourtant listées au sitemap. On essaie les deux formes.
  const competitorSlug = params.slug.replace('faithlock-vs-', '')
  const entry =
    (await getCompetitorBySlug(competitorSlug)) ??
    (await getCompetitorBySlug(params.slug))

  if (!entry) {
    notFound()
  }

  const fields = entry.fields as unknown as Competitor
  // Visible copy must never expose the raw Contentful slug (H1, breadcrumb,
  // table headers, JSON-LD, related links). Same root cause as the <title>
  // defect fixed in PR #81 — normalise once, here.
  const displayName = getCompetitorDisplayName(fields, params.slug)
  const competitor: Competitor = { ...fields, name: displayName }
  const description = getComparisonDescription(fields, params.slug)
  const title = getComparisonTitle(fields, params.slug)

  // Fetch all competitors for dynamic related links
  const allCompetitors = await getAllCompetitors()
  const otherCompetitors = allCompetitors
    .filter((c) => (c.fields.slug as string) !== competitorSlug)
    .map((c) => ({
      slug: (c.fields.slug as string).startsWith('faithlock-vs-')
        ? (c.fields.slug as string)
        : `faithlock-vs-${c.fields.slug as string}`,
      name: getCompetitorDisplayName(c.fields as unknown as Competitor, c.fields.slug as string),
    }))

  const articleSchema = {
    '@context': 'https://schema.org',
    '@type': 'Article',
    headline: title,
    description,
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
      '@id': `${SITE_URL}/compare/${params.slug}`,
    },
  }

  const comparisonSchema = {
    '@context': 'https://schema.org',
    '@type': 'ItemList',
    itemListElement: [
      {
        '@type': 'SoftwareApplication',
        name: 'FaithLock',
        applicationCategory: 'LifestyleApplication',
        operatingSystem: 'iOS',
        offers: { '@type': 'Offer', price: '0', priceCurrency: 'USD' },
      },
      {
        '@type': 'SoftwareApplication',
        name: displayName,
        applicationCategory: 'LifestyleApplication',
        operatingSystem: fields.platforms?.join(', ') || 'iOS',
        offers: {
          '@type': 'Offer',
          price: fields.price || '0',
          priceCurrency: 'USD',
        },
        // Only include real rating data — never fabricate reviewCount
        ...(fields.rating
          ? {
              aggregateRating: {
                '@type': 'AggregateRating',
                ratingValue: fields.rating.toString(),
                bestRating: '5',
              },
            }
          : {}),
      },
    ],
  }

  return (
    <>
      <SchemaMarkup data={[articleSchema, comparisonSchema]} />
      <ComparisonTemplate
        competitor={competitor}
        updatedAt={entry.sys.updatedAt}
        otherCompetitors={otherCompetitors}
      />
    </>
  )
}
