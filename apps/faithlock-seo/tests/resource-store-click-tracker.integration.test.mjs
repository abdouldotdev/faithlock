import test from 'node:test'
import assert from 'node:assert/strict'
import { trackResourceStoreClick } from '../lib/resource-store-click.ts'

class FakeElement {
  constructor(href, section = 'content') {
    this.href = href
    this.section = section
  }

  closest(selector) {
    if (selector === 'a[href]') return this
    if (selector === 'section[id]') return { id: this.section }
    return null
  }
}

globalThis.Element = FakeElement

const page = '/resources/best-bible-verse-lock-screen-apps'
const official = new FakeElement('https://pim.ms/kTxgKF4')
const thirdParty = new FakeElement('https://apps.apple.com/us/app/faithlock-pray-first/id6786329834')
const article = {
  contains: (anchor) => anchor === official || anchor === thirdParty,
  querySelectorAll: () => [official, thirdParty],
}

function event(target) {
  let prevented = false
  return {
    target,
    preventDefault() {
      prevented = true
    },
    get prevented() {
      return prevented
    },
  }
}

test('captures exactly one event per eligible click and preserves navigation', () => {
  const captured = []
  const mouseClick = event(official)
  trackResourceStoreClick(mouseClick.target, page, article, (name, properties) => captured.push({ name, properties, options: { transport: 'sendBeacon' } }))

  assert.equal(captured.length, 1)
  assert.equal(captured[0].name, 'faithlock_store_click')
  assert.equal(captured[0].properties.destination_type, 'short_link')
  assert.equal(captured[0].options.transport, 'sendBeacon')
  assert.equal(mouseClick.prevented, false)

  const keyboardClick = event(official)
  trackResourceStoreClick(keyboardClick.target, page, article, (name, properties) => captured.push({ name, properties }))
  assert.equal(captured.length, 2)
  assert.equal(keyboardClick.prevented, false)
})

test('does not capture third-party store links', () => {
  const captured = []
  trackResourceStoreClick(thirdParty, page, article, (...args) => captured.push(args))
  assert.equal(captured.length, 0)
})
