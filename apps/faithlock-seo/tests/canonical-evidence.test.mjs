import test from 'node:test'
import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

const appRoot = join(dirname(fileURLToPath(import.meta.url)), '..')
const read = (relativePath) => readFile(join(appRoot, relativePath), 'utf8')

test('home declares a self-referential canonical and stable Open Graph URL', async () => {
  const source = await read('app/page.tsx')
  assert.match(source, /alternates:\s*\{[\s\S]*canonical:\s*['"]\/['"]\s*,?\s*\}/)
  assert.match(source, /openGraph:\s*\{[\s\S]*url:\s*['"]\/['"]/s)
})

test('evidence inventory routes are canonicalized and included in the sitemap', async () => {
  const [sitemap, features, privacy, terms, layout] = await Promise.all([
    read('app/sitemap.ts'),
    read('app/(seo)/features/page.tsx'),
    read('app/(seo)/privacy/page.tsx'),
    read('app/(seo)/terms/page.tsx'),
    read('app/layout.tsx'),
  ])

  assert.match(sitemap, /SITE_URL}\/features/)
  assert.match(sitemap, /SITE_URL}\/privacy/)
  assert.match(sitemap, /SITE_URL}\/terms/)
  assert.match(features, /canonical:\s*['"]\/features['"]/)
  assert.match(privacy, /canonical:\s*['"]\/privacy['"]/)
  assert.match(terms, /canonical:\s*['"]\/terms['"]/)
  assert.match(layout, /SchemaMarkup/)
  assert.match(layout, /'@type': 'WebSite'/)
})
