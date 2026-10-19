import test from 'node:test'
import assert from 'node:assert/strict'
import { readdirSync, readFileSync } from 'node:fs'
import { join } from 'node:path'
import { isCompetitorUrl, unlinkCompetitors } from '../lib/competitors.ts'

test('flags competitor sites, subdomains and other apps store listings', () => {
  assert.equal(isCompetitorUrl('https://opalapp.com/help/x'), true)
  assert.equal(isCompetitorUrl('https://support.bark.us/article'), true)
  assert.equal(isCompetitorUrl('https://www.blok.so/resources/x'), true)
  assert.equal(isCompetitorUrl('https://apps.apple.com/us/app/opal/id1497465230'), true)
  assert.equal(isCompetitorUrl('https://play.google.com/store/apps/details?id=com.screenzen'), true)
})

test('keeps FaithLock and neutral sources', () => {
  assert.equal(isCompetitorUrl('https://apps.apple.com/us/app/faith-lock-bible-prayer-focus/id6754208209'), false)
  assert.equal(isCompetitorUrl('https://pim.ms/kTxgKF4'), false)
  assert.equal(isCompetitorUrl('https://www.biblegateway.com/passage/?search=John+3'), false)
  assert.equal(isCompetitorUrl('https://pmc.ncbi.nlm.nih.gov/articles/PMC9974409/'), false)
  assert.equal(isCompetitorUrl('https://notbark.us.example.com'), false)
  assert.equal(isCompetitorUrl('/resources/opal-review'), false)
})

test('unlinks competitor anchors and keeps their text', () => {
  const html = '<p><a href="https://opalapp.com">Opal</a> vs <a href="https://pim.ms/kTxgKF4">FaithLock</a></p>'
  assert.equal(unlinkCompetitors(html), '<p>Opal vs <a href="https://pim.ms/kTxgKF4">FaithLock</a></p>')
})

test('no markdown page links to a competitor', () => {
  const dir = new URL('../seo-content/new-pages/', import.meta.url).pathname
  const offenders = []
  const walk = (d) => {
    for (const e of readdirSync(d, { withFileTypes: true })) {
      const p = join(d, e.name)
      if (e.isDirectory()) walk(p)
      else if (e.name.endsWith('.md')) {
        for (const [, mdUrl, htmlUrl] of readFileSync(p, 'utf8').matchAll(/\]\((https?:\/\/[^)\s]+)\)|href="(https?:\/\/[^"]+)"/g)) {
          const url = mdUrl || htmlUrl
          if (isCompetitorUrl(url)) offenders.push(`${p}: ${url}`)
        }
      }
    }
  }
  walk(dir)
  assert.deepEqual(offenders, [])
})
