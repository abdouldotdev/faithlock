import { createClient } from 'contentful'
import { getAllLocalGlossaryEntries, getLocalGlossaryEntryBySlug } from './local-content'

// Local markdown in seo-content/new-pages is now the source of truth for /resources
// content. Contentful is kept only as a fallback for entries that haven't been
// migrated to local files yet, so it must stay fully optional: the site (and the
// build) has to work with zero Contentful env vars configured.
const hasContentfulConfig = Boolean(
  process.env.CONTENTFUL_SPACE_ID && process.env.CONTENTFUL_ACCESS_TOKEN
)

// Delivery client (published content) — null when Contentful isn't configured
export const client = hasContentfulConfig
  ? createClient({
      space: process.env.CONTENTFUL_SPACE_ID as string,
      accessToken: process.env.CONTENTFUL_ACCESS_TOKEN as string,
    })
  : null

// Preview client (draft content) - optional
export const previewClient =
  hasContentfulConfig && process.env.CONTENTFUL_PREVIEW_ACCESS_TOKEN
    ? createClient({
        space: process.env.CONTENTFUL_SPACE_ID as string,
        accessToken: process.env.CONTENTFUL_PREVIEW_ACCESS_TOKEN,
        host: 'preview.contentful.com',
      })
    : null

// Safe query wrapper - returns empty array if content type doesn't exist yet
// or Contentful isn't configured for this environment
async function safeGetEntries(query: Record<string, unknown>) {
  if (!client) return []
  try {
    const response = await client.getEntries(query)
    return response.items
  } catch {
    return []
  }
}

type GlossaryEntry = {
  sys: { id: string; createdAt: string; updatedAt: string }
  fields: Record<string, unknown>
}

// ─── Competitors (Comparison Pages) ───

export async function getAllCompetitors() {
  return safeGetEntries({
    content_type: 'competitor',
    order: ['-fields.downloads'],
  })
}

export async function getCompetitorBySlug(slug: string) {
  const items = await safeGetEntries({
    content_type: 'competitor',
    'fields.slug': slug,
    limit: 1,
  })
  return items[0] || null
}

// ─── Glossary Terms (Resources Pages) ───
// Local markdown files (seo-content/new-pages) take priority. Contentful only
// fills in slugs that don't have a local file yet, so nothing already live
// under Contentful-only content breaks while the migration is in progress.

export async function getAllGlossaryTerms(): Promise<GlossaryEntry[]> {
  const localEntries = getAllLocalGlossaryEntries()
  const localSlugs = new Set(localEntries.map((e) => e.fields.slug))

  const contentfulItems: GlossaryEntry[] = []
  if (client) {
    // Contentful defaults to 100 items per page — fetch all.
    let skip = 0
    const limit = 100
    while (true) {
      const items = (await safeGetEntries({
        content_type: 'glossaryTerm',
        order: ['fields.term'],
        limit,
        skip,
      })) as GlossaryEntry[]
      contentfulItems.push(...items)
      if (items.length < limit) break
      skip += limit
    }
  }

  const contentfulOnly = contentfulItems.filter(
    (item) => !localSlugs.has((item.fields as { slug?: string })?.slug || '')
  )

  const merged: GlossaryEntry[] = [
    ...(localEntries as unknown as GlossaryEntry[]),
    ...contentfulOnly,
  ]
  merged.sort((a, b) =>
    ((a.fields as { term?: string })?.term || '').localeCompare(
      (b.fields as { term?: string })?.term || ''
    )
  )
  return merged
}

export async function getGlossaryTermBySlug(slug: string): Promise<GlossaryEntry | null> {
  const local = getLocalGlossaryEntryBySlug(slug)
  if (local) return local as unknown as GlossaryEntry

  const items = (await safeGetEntries({
    content_type: 'glossaryTerm',
    'fields.slug': slug,
    limit: 1,
  })) as GlossaryEntry[]
  return items[0] || null
}

export async function getGlossaryTermsByCategory(category: string): Promise<GlossaryEntry[]> {
  const localEntries = getAllLocalGlossaryEntries().filter(
    (e) => e.fields.category === category
  )
  const localSlugs = new Set(localEntries.map((e) => e.fields.slug))

  const items = (await safeGetEntries({
    content_type: 'glossaryTerm',
    'fields.category': category,
    order: ['fields.term'],
  })) as GlossaryEntry[]

  const contentfulOnly = items.filter(
    (item) => !localSlugs.has((item.fields as { slug?: string })?.slug || '')
  )
  return [...(localEntries as unknown as GlossaryEntry[]), ...contentfulOnly]
}

// ─── Features (Feature Pages) ───

export async function getAllFeatures() {
  return safeGetEntries({
    content_type: 'feature',
    order: ['fields.name'],
  })
}

export async function getFeatureBySlug(slug: string) {
  const items = await safeGetEntries({
    content_type: 'feature',
    'fields.slug': slug,
    limit: 1,
  })
  return items[0] || null
}

// ─── Utility: Get all content for sitemap ───

export async function getAllSlugs() {
  const [competitors, glossaryTerms, features] = await Promise.all([
    getAllCompetitors(),
    getAllGlossaryTerms(),
    getAllFeatures(),
  ])

  return {
    competitors: competitors.map((c) => ({
      slug: (c.fields as Record<string, unknown>).slug as string,
      updatedAt: c.sys.updatedAt,
    })),
    glossaryTerms: glossaryTerms.map((t) => ({
      slug: (t.fields as Record<string, unknown>).slug as string,
      updatedAt: t.sys.updatedAt,
    })),
    features: features.map((f) => ({
      slug: (f.fields as Record<string, unknown>).slug as string,
      updatedAt: f.sys.updatedAt,
    })),
  }
}

// ─── Utility: Get all content for footer ───

export async function getAllContentForFooter() {
  const [competitors, glossaryTerms, features] = await Promise.all([
    getAllCompetitors(),
    getAllGlossaryTerms(),
    getAllFeatures(),
  ])

  return {
    competitors: competitors.map((c) => {
      const f = c.fields as Record<string, unknown>
      const slug = f.slug as string
      return {
        slug: slug.startsWith('faithlock-vs-') ? slug : `faithlock-vs-${slug}`,
        name: f.name as string,
      }
    }),
    glossaryTerms: glossaryTerms.map((t) => {
      const f = t.fields as Record<string, unknown>
      return {
        slug: f.slug as string,
        term: f.term as string,
        category: (f.category as string) || 'General',
      }
    }),
    features: features.map((f) => {
      const ff = f.fields as Record<string, unknown>
      return {
        slug: ff.slug as string,
        name: ff.name as string,
      }
    }),
  }
}
