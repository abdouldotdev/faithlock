import { documentToReactComponents } from '@contentful/rich-text-react-renderer'
import { Document } from '@contentful/rich-text-types'
import { marked } from 'marked'
import { unlinkCompetitors } from '@/lib/competitors'

interface RichTextProps {
  content: Document | string | unknown
  className?: string
}

/**
 * Strip markdown syntax from a string for plain-text display.
 * Removes headers, bold, italic, links, images, lists, etc.
 */
export function stripMarkdown(text: string | unknown): string {
  if (!text || typeof text !== 'string') return ''
  return text
    .replace(/^#{1,6}\s+/gm, '')       // headers
    .replace(/\*\*(.*?)\*\*/g, '$1')    // bold
    .replace(/\*(.*?)\*/g, '$1')        // italic
    .replace(/__(.*?)__/g, '$1')        // bold alt
    .replace(/_(.*?)_/g, '$1')          // italic alt
    .replace(/\[([^\]]*)\]\([^)]*\)/g, '$1') // links
    .replace(/!\[([^\]]*)\]\([^)]*\)/g, '$1') // images
    .replace(/^[-*+]\s+/gm, '')         // unordered lists
    .replace(/^\d+\.\s+/gm, '')         // ordered lists
    .replace(/^>\s+/gm, '')             // blockquotes
    .replace(/`{1,3}[^`]*`{1,3}/g, '')  // code
    .replace(/^\|.*\|$/gm, '')          // tables
    .replace(/^[-|:\s]+$/gm, '')        // table separators
    .replace(/^---+$/gm, '')            // horizontal rules
    .replace(/\n{3,}/g, '\n\n')         // excess newlines
    .trim()
}

/**
 * Block-level node types in Contentful Rich Text that need line breaks between them.
 */
const BLOCK_NODES = new Set([
  'document', 'paragraph', 'heading-1', 'heading-2', 'heading-3',
  'heading-4', 'heading-5', 'heading-6', 'unordered-list', 'ordered-list',
  'list-item', 'blockquote', 'hr', 'table', 'table-row', 'table-cell',
])

/**
 * Extract all raw text from a Contentful Rich Text Document.
 * Preserves line breaks between block-level nodes so markdown can be parsed.
 */
function extractRawText(node: unknown): string {
  if (!node || typeof node !== 'object') return ''
  const n = node as Record<string, unknown>
  let text = ''
  if (typeof n.value === 'string') text += n.value
  if (Array.isArray(n.content)) {
    for (const child of n.content) {
      const childNode = child as Record<string, unknown>
      const childText = extractRawText(child)
      if (BLOCK_NODES.has(childNode.nodeType as string)) {
        text += '\n\n' + childText
      } else {
        text += childText
      }
    }
  }
  return text
}

/**
 * Detect if a string contains markdown syntax.
 */
function isMarkdown(text: string): boolean {
  return /^#{1,6}\s|^\*\*|^\- |\*\*.*\*\*|^\|.*\|/m.test(text)
}

/**
 * Keep official App Store URLs authored in SEO content intact so the rendered
 * article preserves its canonical CTA. The delegated click listener accepts
 * both the official URL and the tracked short link; rewriting here would make
 * a page-level rendered-output contract impossible to verify.
 */
function withTrackedStoreLinks(html: string): string {
  return unlinkCompetitors(html)
}

/**
 * Convert markdown string to sanitized HTML.
 */
function markdownToHtml(md: string): string {
  return marked.parse(md, { async: false }) as string
}

export default function RichText({ content, className }: RichTextProps) {
  if (!content) return null

  // String content: could be HTML or Markdown
  if (typeof content === 'string') {
    const html = isMarkdown(content) ? markdownToHtml(content) : content
    return <div className={className} dangerouslySetInnerHTML={{ __html: withTrackedStoreLinks(html) }} />
  }

  // If it's a Contentful Rich Text Document object
  if (
    typeof content === 'object' &&
    content !== null &&
    'nodeType' in (content as Record<string, unknown>)
  ) {
    // Check if the Document's text nodes contain embedded HTML tags.
    // This happens when HTML strings are stored inside Rich Text fields.
    const rawText = extractRawText(content)
    if (/<[a-z][\s\S]*>/i.test(rawText)) {
      return <div className={className} dangerouslySetInnerHTML={{ __html: withTrackedStoreLinks(rawText) }} />
    }

    // Check for markdown inside Rich Text text nodes
    if (isMarkdown(rawText)) {
      return <div className={className} dangerouslySetInnerHTML={{ __html: withTrackedStoreLinks(markdownToHtml(rawText)) }} />
    }

    // Proper Rich Text Document — render with Contentful's renderer
    return (
      <div className={className}>
        {documentToReactComponents(content as Document)}
      </div>
    )
  }

  // Fallback
  return <div className={className}>{String(content)}</div>
}
