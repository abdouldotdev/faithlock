import test from 'node:test'
import assert from 'node:assert/strict'
import {
  FAITHLOCK_APP_STORE_DEVELOPER,
  FAITHLOCK_APP_STORE_ID,
  FAITHLOCK_APP_STORE_URL,
} from '../lib/resource-store-click.ts'

const EXPECTED_ID = '6754208209'
const EXPECTED_DEVELOPER = 'Appbiz Studio, LLC'
const EXPECTED_CANONICAL_URL =
  'https://apps.apple.com/us/app/faith-lock-bible-prayer-focus/id6754208209'
const HOMONYMOUS_APP_ID = '6786329834'

test('keeps the FaithLock App Store identity contract pinned', () => {
  assert.equal(FAITHLOCK_APP_STORE_ID, EXPECTED_ID)
  assert.equal(FAITHLOCK_APP_STORE_DEVELOPER, EXPECTED_DEVELOPER)
  assert.equal(FAITHLOCK_APP_STORE_URL, EXPECTED_CANONICAL_URL)
  assert.match(FAITHLOCK_APP_STORE_URL, new RegExp(`/id${EXPECTED_ID}$`))
  assert.doesNotMatch(FAITHLOCK_APP_STORE_URL, new RegExp(`/id${HOMONYMOUS_APP_ID}$`))
})

test('does not allow the homonymous App Store id in the production tracker', async () => {
  const source = await import('node:fs/promises')
  const trackerSource = await source.readFile(new URL('../lib/resource-store-click.ts', import.meta.url), 'utf8')
  assert.doesNotMatch(trackerSource, new RegExp(`id${HOMONYMOUS_APP_ID}`))
})