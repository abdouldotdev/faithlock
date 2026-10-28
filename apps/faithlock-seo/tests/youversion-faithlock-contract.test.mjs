import test from 'node:test'
import assert from 'node:assert/strict'
import fs from 'node:fs'
import path from 'node:path'

const docs = path.resolve(import.meta.dirname, '../../../docs/internal')
const prototype = fs.readFileSync(path.join(docs, 'youversion-faithlock-7-day-prototype.md'), 'utf8')
const contract = fs.readFileSync(path.join(docs, 'youversion-faithlock-measurement-contract.md'), 'utf8')

test('internal prototype contains exactly seven complete days', () => {
  const days = [...prototype.matchAll(/^### Day (\d+) — (.+)$/gm)]
  assert.equal(days.length, 7)
  assert.deepEqual(days.map(([, number]) => Number(number)), [1, 2, 3, 4, 5, 6, 7])

  for (const label of ['Scripture:', 'Reflection:', 'Prayer:', 'Practice:', 'Completion definition:']) {
    assert.equal((prototype.match(new RegExp(`^${label}`, 'gm')) ?? []).length, 7, label)
  }
})

test('prototype is explicitly internal and has no external delivery instruction', () => {
  assert.match(prototype, /INTERNAL ONLY/)
  assert.match(prototype, /no YouVersion contact, submission, publication/i)
  assert.match(prototype, /an installation, activation, purchase, payer, or revenue event/i)
  assert.doesNotMatch(prototype, /https?:\/\//)
})

test('measurement contract separates funnel stages and attribution dimensions', () => {
  for (const token of [
    'faithlock_series_day_completed',
    'faithlock_series_completed',
    'first_focus_completed',
    'faithlock_store_click',
    'media_source',
    'campaign',
    'referral_type',
    '6754208209',
    'ROI NON CALCULABLE',
    'INSTRUMENTATION_MISSING',
  ]) assert.match(contract, new RegExp(token.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')))

  assert.match(contract, /A store click is a web proxy\..*not an install\./)
  assert.match(contract, /STOP external test \/ GO internal content review/)
  assert.match(contract, /no raw device ID or personal data/)
})

test('contract does not authorize external delivery', () => {
  assert.match(contract, /not implemented and not approved for external testing/)
  assert.match(contract, /No YouVersion contact, submission, publication, paid API call, Production\/store change/)
})
