import assert from 'node:assert/strict'
import test from 'node:test'
import { readFile } from 'node:fs/promises'
import matter from 'gray-matter'
import { marked } from 'marked'

const pagePath = new URL('../seo-content/new-pages/best-app-blockers-iphone.md', import.meta.url)
const richTextPath = new URL('../components/ui/RichText.tsx', import.meta.url)
const middlewarePath = new URL('../middleware.ts', import.meta.url)
const layoutPath = new URL('../app/(seo)/layout.tsx', import.meta.url)
const templatePath = new URL('../components/templates/GlossaryTemplate.tsx', import.meta.url)
const officialUrl = 'https://apps.apple.com/us/app/faith-lock-bible-prayer-focus/id6754208209'
const shortUrl = 'https://pim.ms/kTxgKF4'

test('rendered best-app-blockers-iphone output has one official CTA and no short-link CTA', async () => {
  const source = await readFile(pagePath, 'utf8')
  const { content } = matter(source)
  const html = await marked.parse(content)

  assert.equal((html.match(new RegExp(officialUrl, 'g')) || []).length, 1)
  assert.equal((html.match(new RegExp(shortUrl.replace(/[.*+?^${}()|[\\]\\\\]/g, '\\\\$&'), 'g')) || []).length, 0)
})

test('RichText serving path preserves authored official App Store URLs', async () => {
  const source = await readFile(richTextPath, 'utf8')
  assert.match(source, /Keep official App Store URLs authored in SEO content intact/)
  assert.doesNotMatch(source, /html\.replace\(RAW_FAITHLOCK_STORE_URL/)
})

test('full route render suppresses chrome and template CTAs for the exact page contract', async () => {
  const middleware = await readFile(middlewarePath, 'utf8')
  const layout = await readFile(layoutPath, 'utf8')
  const template = await readFile(templatePath, 'utf8')

  assert.match(middleware, /TARGET_PATH = ['"]\/resources\/best-app-blockers-iphone['"]/)
  assert.match(middleware, /x-faithlock-suppress-global-store-ctas/)
  assert.match(layout, /suppressStoreCta/)
  assert.match(template, /!suppressStoreCta && <section/)
  assert.match(template, /<SubtleCallout suppressStoreCta=\{suppressStoreCta\} \/>/)
})
