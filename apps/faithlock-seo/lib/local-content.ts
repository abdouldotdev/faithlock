import { readFileSync, readdirSync, statSync, existsSync } from 'fs'
import { join, basename, extname } from 'path'
import matter from 'gray-matter'
import { ContentfulEntry, FAQ, GlossaryTerm } from './types'

// Local markdown source for /resources content.
// Files live in seo-content/new-pages/**/*.md (any subfolder — all flattened to /resources/<slug>).
const CONTENT_DIR = join(process.cwd(), 'seo-content', 'new-pages')

// ─── Parsing helpers (mirrors scripts/import-new-content.mjs so local rendering
// matches what already-imported Contentful entries look like) ───

function extractShortDef(body: string): string {
  const afterTakeaways = body.match(/## Key Takeaways[\s\S]*?\n---\n\n([\s\S]*?)(?=\n##|\n---)/m)
  if (afterTakeaways) return afterTakeaways[1].trim().slice(0, 500)

  const firstSection = body.match(/## [\s\S]*?\n\n([\s\S]*?)(?=\n##|$)/m)
  if (firstSection) return firstSection[1].trim().slice(0, 500)

  return body.slice(0, 500)
}

function extractFaqs(body: string): FAQ[] {
  const faqs: FAQ[] = []
  const faqMatches = Array.from(
    body.matchAll(/\*\*([^*]+\?)\*\*\n([^*\n][\s\S]*?)(?=\n\*\*[^*]+\?|---|\n## |$)/gm)
  )
  for (const match of faqMatches) {
    const question = match[1].trim()
    const answer = match[2].trim().replace(/\[([^\]]*)\]\([^)]*\)/g, '$1').slice(0, 1000)
    if (question && answer) faqs.push({ question, answer })
  }
  return faqs
}

function findMarkdownFiles(dir: string): string[] {
  if (!existsSync(dir)) return []
  let files: string[] = []
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const fullPath = join(dir, entry.name)
    if (entry.isDirectory()) {
      files = files.concat(findMarkdownFiles(fullPath))
    } else if (entry.isFile() && extname(entry.name) === '.md') {
      files.push(fullPath)
    }
  }
  return files
}

function parseFile(filePath: string): ContentfulEntry<GlossaryTerm> {
  const raw = readFileSync(filePath, 'utf-8')
  const { data: meta, content } = matter(raw)
  const body = content.trim()
  const slug = (meta.slug as string) || basename(filePath, '.md')
  const title = (meta.title as string) || slug.replace(/-/g, ' ')
  const mtime = statSync(filePath).mtime.toISOString()

  const fields: GlossaryTerm = {
    term: title,
    slug,
    category: (meta.category as string) || 'Guides',
    shortDefinition: extractShortDef(body),
    detailedExplanation: body,
    christianPerspective: '',
    bibleVerses: [],
    statistics: [],
    relatedTerms: [],
    faqs: extractFaqs(body),
    seoTitle: (meta.meta_title as string) || title,
    seoDescription: (meta.meta_description as string) || '',
  }

  return {
    sys: { id: `local-${slug}`, createdAt: mtime, updatedAt: mtime },
    fields,
  }
}

// Parsed once per server/build lifetime — avoids re-reading 300+ files per request.
let cache: Map<string, ContentfulEntry<GlossaryTerm>> | null = null

function loadAll(): Map<string, ContentfulEntry<GlossaryTerm>> {
  if (cache) return cache
  const map = new Map<string, ContentfulEntry<GlossaryTerm>>()
  for (const filePath of findMarkdownFiles(CONTENT_DIR)) {
    try {
      const entry = parseFile(filePath)
      map.set(entry.fields.slug, entry)
    } catch {
      // Skip malformed files rather than failing the whole build
    }
  }
  cache = map
  return map
}

export function getAllLocalGlossaryEntries(): ContentfulEntry<GlossaryTerm>[] {
  return Array.from(loadAll().values())
}

export function getLocalGlossaryEntryBySlug(slug: string): ContentfulEntry<GlossaryTerm> | null {
  return loadAll().get(slug) || null
}
