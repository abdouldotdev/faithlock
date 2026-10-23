import test from 'node:test'
import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import matter from 'gray-matter'
import { marked } from 'marked'

const pagePath = new URL('../seo-content/new-pages/best-app-blockers-iphone.md', import.meta.url)
const faithLockCta = 'https://apps.apple.com/us/app/faith-lock-bible-prayer-focus/id6754208209'

test('best iPhone blockers keeps the exact answer-first HTML contract and official CTA', async () => {
  const source = await readFile(pagePath, 'utf8')
  const { data, content } = matter(source)
  const html = await marked.parse(content)

  assert.equal(data.slug, 'best-app-blockers-iphone')
  assert.match(html, /^\s*<h2>Short answer<\/h2>/)
  assert.match(html, /<h2>What the official sources support<\/h2>/)
  assert.match(html, /<table>[\s\S]*What the official source supports[\s\S]*What it does not prove[\s\S]*<\/table>/)
  assert.match(html, /There is no single best iPhone blocker for every person\./)
  assert.equal(source.split(faithLockCta).length - 1, 1)
  assert.match(html, new RegExp(`href="${faithLockCta}"`))
})

test('answer-first page preserves the resource canonical route and indexable metadata path', async () => {
  const routeSource = await readFile(new URL('../app/(seo)/resources/[slug]/page.tsx', import.meta.url), 'utf8')
  assert.match(routeSource, /canonical:\s*`\/resources\/\$\{fields\.slug\}`/)
  assert.doesNotMatch(routeSource, /robots:\s*\{\s*index:\s*false/)
})