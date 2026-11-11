import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import { fileURLToPath } from 'node:url'
import test from 'node:test'

const pagePath = fileURLToPath(new URL('../seo-content/new-pages/comparisons/freedom-vs-cold-turkey.md', import.meta.url))

const officialSources = [
  'https://freedom.to/premium',
  'https://freedom.to/be-free',
  'https://getcoldturkey.com/pricing/',
  'https://getcoldturkey.com/features/',
  'https://getcoldturkey.com/support/system-requirements/',
  'https://getcoldturkey.com/support/user-guide/',
  'https://apps.apple.com/us/app/faith-lock-bible-prayer-focus/id6754208209',
]

test('Freedom vs Cold Turkey page keeps official source URLs and product identity', async () => {
  const source = await readFile(pagePath, 'utf8')

  for (const url of officialSources) assert.match(source, new RegExp(url.replaceAll('/', '\\/')))
  assert.match(source, /Faith Lock: Bible Prayer Focus/)
  assert.match(source, /6754208209/)
  assert.doesNotMatch(source, /6786329834/)
  assert.match(source, /iOS-only/)
  assert.match(source, /iOS 13\.0 or later/)
})

test('page retains only bounded, source-supported pricing and compatibility claims', async () => {
  const source = await readFile(pagePath, 'utf8')

  assert.match(source, /Freedom.*\$8\.99\/month/s)
  assert.match(source, /\$99\.50 lifetime/)
  assert.match(source, /Cold Turkey.*lifetime access/s)
  assert.match(source, /Cold Turkey.*macOS.*Windows/s)
  assert.match(source, /Android, iOS.*not supported/s)
  assert.match(source, /does not state a dollar amount/)

  assert.doesNotMatch(source, /Cold Turkey[^\n]{0,100}\$39/)
  assert.doesNotMatch(source, /Freedom[^\n]{0,100}\$39\.99\/year/)
  assert.doesNotMatch(source, /\$4\.99|\$24\.99/)
  assert.doesNotMatch(source, /id6786329834/)
  assert.doesNotMatch(source, /unbypassable|virtually impossible|unmatched|strongest desktop blocker/i)
  assert.doesNotMatch(source, /2\.5 million|2\.5M\+|3 million users/i)
})

test('page does not present llms.txt or AI-exposure measurement as evidence', async () => {
  const source = await readFile(pagePath, 'utf8')
  assert.doesNotMatch(source, /llms\.txt|AI exposure|AI citations|GEO exposure/i)
})
