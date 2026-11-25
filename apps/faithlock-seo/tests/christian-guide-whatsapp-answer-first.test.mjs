import test from 'node:test'
import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import matter from 'gray-matter'
import { marked } from 'marked'

const pagePath = new URL('../seo-content/new-pages/platform-guides/christian-guide-to-whatsapp.md', import.meta.url)
const faithLockCta = 'https://apps.apple.com/us/app/faith-lock-bible-prayer-focus/id6754208209'

test('WhatsApp guide keeps the exact answer-first prompt and official single CTA', async () => {
  const source = await readFile(pagePath, 'utf8')
  const { data, content } = matter(source)
  const html = await marked.parse(content)

  assert.equal(data.slug, 'christian-guide-to-whatsapp')
  assert.match(html, /^\s*<h2>How can a Christian use WhatsApp without losing focus, boundaries, or faith on iPhone\?<\/h2>/)
  assert.match(html, /<h3>What each layer can and cannot do<\/h3>/)
  assert.match(html, /Apple Screen Time[\s\S]*FaithLock/)
  assert.equal(source.split(faithLockCta).length - 1, 1)
  assert.match(html, new RegExp(`href="${faithLockCta}"`))
  assert.match(html, /data-store-location="whatsapp_answer_cta"/)
  assert.match(source, /\[1\] Official FaithLock App Store listing for App ID `6754208209`/)
})
