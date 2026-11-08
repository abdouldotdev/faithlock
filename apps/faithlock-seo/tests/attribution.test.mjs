import test from "node:test"
import assert from "node:assert/strict"
import { buildOneLink, channelFromHost, classifyVisit } from "../lib/attribution.ts"

test("AI assistants, search engines and socials map to stable channels", () => {
  assert.equal(channelFromHost("chatgpt.com"), "chatgpt")
  assert.equal(channelFromHost("chat.openai.com"), "chatgpt")
  assert.equal(channelFromHost("www.perplexity.ai"), "perplexity")
  assert.equal(channelFromHost("claude.ai"), "claude")
  assert.equal(channelFromHost("gemini.google.com"), "gemini")
  assert.equal(channelFromHost("copilot.microsoft.com"), "copilot")
  assert.equal(channelFromHost("www.google.com"), "google")
  assert.equal(channelFromHost("www.google.co.uk"), "google")
  assert.equal(channelFromHost("l.facebook.com"), "facebook")
  assert.equal(channelFromHost("t.co"), "x")
  assert.equal(channelFromHost("old.reddit.com"), "reddit")
  assert.equal(channelFromHost("someblog.org"), "someblog.org")
})

test("utm_source wins over the referrer", () => {
  const v = classifyVisit("?utm_source=chatgpt.com&utm_campaign=Spring Push", "https://www.google.com/", "/resources/x")
  assert.deepEqual(v, { channel: "chatgpt", landing: "/resources/x", campaign: "spring_push" })
})

test("external referrer is used, own site and empty referrer are direct", () => {
  assert.equal(classifyVisit("", "https://www.perplexity.ai/search?q=a", "/").channel, "perplexity")
  assert.equal(classifyVisit("", "https://www.getfaithlock.com/blog", "/").channel, "direct")
  assert.equal(classifyVisit("", "", "/").channel, "direct")
  assert.equal(classifyVisit("", "not a url", "/").channel, "direct")
})

test("OneLink carries channel, page, landing, CTA and campaign", () => {
  const url = new URL(buildOneLink({ channel: "chatgpt", landing: "/a", campaign: "c1" }, "/b", "hero"))
  assert.equal(url.origin + url.pathname, "https://faithlock.onelink.me/l3EF/web")
  assert.equal(url.searchParams.get("af_channel"), "chatgpt")
  assert.equal(url.searchParams.get("af_sub1"), "/b")
  assert.equal(url.searchParams.get("af_sub2"), "/a")
  assert.equal(url.searchParams.get("af_sub3"), "hero")
  assert.equal(url.searchParams.get("af_sub4"), "c1")
  assert.equal(new URL(buildOneLink({ channel: "direct", landing: "/" }, "/", "")).searchParams.get("af_sub3"), "content")
  assert.equal(new URL(buildOneLink({ channel: "direct", landing: "/" }, "/", "")).searchParams.has("af_sub4"), false)
})
