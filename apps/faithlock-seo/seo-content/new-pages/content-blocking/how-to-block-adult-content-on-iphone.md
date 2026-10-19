---
slug: how-to-block-adult-content-on-iphone
title: How to Block Adult Content on iPhone
category: Guides
meta_title: "How to Block Adult Content on iPhone (Verified 2026 Steps)"
meta_description: "Apple's current menu path, checked against Apple's own documentation, plus the free DNS layer that covers apps and the one step that decides whether any of it lasts."
---

## Quick Answer

To block adult content on iPhone, open Settings, scroll down and tap Screen Time, tap Content & Privacy Restrictions, enter your Screen Time passcode if asked, tap **App Store, Media, Web, & Games**, then tap **Web Content**, and choose **Limit Adult Websites**. This filters web content system wide and is free. Have someone else set the passcode, or you can undo it in seconds.

---

## Before You Start: The Menu Has Been Renamed

If you are following instructions written a couple of years ago, they will send you to a screen that no longer exists.

The Web Content setting now sits behind an intermediate screen called **App Store, Media, Web, & Games**. Older guides tell you to look for "Content Restrictions". The options have been relabelled too: the choices are now **Unrestricted**, **Limit Adult Websites**, and **Only Approved Websites**, where older instructions refer to "Unrestricted Access" and "Allowed Websites Only".

The steps below match Apple's current documentation ([Apple Support](https://support.apple.com/en-us/105121), checked 2026-08-16).

---

## Method 1: The Built-In Filter (Free, 2 Minutes)

Apple documents this path for a parent managing a child through Family Sharing, which adds one tap that does not apply on your own device. Both versions are given.

1. Open the **Settings** app, scroll down, then tap **Screen Time**.
2. *If you are setting this up for a child through Family Sharing:* under **Family**, tap your child's name. On your own device, skip this step.
3. Tap **Content & Privacy Restrictions**. Turn it on if it is not already.
4. If asked, enter your **Screen Time passcode**.
5. Tap **App Store, Media, Web, & Games**.
6. Tap **Web Content**.
7. Choose **Limit Adult Websites**.

That is the whole procedure. Apple's wording for the final choice is "Choose Unrestricted, Limit Adult Websites, or Only Approved Websites."

**A note on the third option.** Only Approved Websites is an allowlist: nothing loads except sites you add by hand. It is the right setting for a young child's device and impractical for an adult's. Choosing it by mistake is a common way to end up assuming iPhone filtering is broken.

**What this covers.** Web content across the device, not Safari alone. **What it does not cover:** content inside apps, and anything sent to you in a message.

---

## Method 2: The Step That Decides Whether It Lasts

This is not a technical step and it is the one that matters most.

The filter you just set is exactly as strong as the secrecy of the Screen Time passcode. If you know the code, you have set a preference. Turning it off takes about fifteen seconds, and the moment you want to turn it off is precisely the moment your judgment is least reliable.

So: have someone else set that passcode and not tell you.

1. Go to **Settings**, **Screen Time**, and tap **Change Screen Time Passcode** (or set one if you have none).
2. Hand the phone to the other person and look away while they enter it.
3. Agree what happens when you legitimately need it changed, so there is a route that does not involve a fight.

This converts a free setting into something more durable than most paid products, because reversing it now requires a conversation. If nobody in your life can do this today, that is a genuine constraint rather than a failure, and it is the main argument for accountability software, which produces a similar effect by telling someone rather than by withholding a code. See [accountability software](/resources/accountability-software).

---

## Method 3: Add Filtering DNS (Free, 5 Minutes)

Apple's web content filter acts on web content. Filtering DNS acts on the connection, so it reaches apps and every browser.

**On the phone, for Wi-Fi networks:**

1. Open **Settings**, tap **Wi-Fi**.
2. Tap the **i** button beside your network.
3. Tap **Configure DNS**, then **Manual**.
4. Remove the existing servers and add a filtering pair.

**Which resolver:**

| Service | Addresses | Notes |
|---|---|---|
| CleanBrowsing Family Filter | 185.228.168.168, 185.228.169.168 | Also blocks proxy and VPN domains, which closes the usual workaround |
| Cloudflare 1.1.1.1 for Families | 1.1.1.3, 1.0.0.3 | Malware and adult content |
| AdGuard family protection | 94.140.14.15, 94.140.15.16 | Adult content plus ads and trackers |

CleanBrowsing documents its free tier as requiring no account but throttled and unsupported ([CleanBrowsing](https://cleanbrowsing.org/filters/)). Cloudflare describes the family option as free protection for home Internet ([Cloudflare](https://one.one.one.one/family/)). AdGuard describes its family servers as blocking "ads, trackers, adult content, and enable Safe Search and Safe Mode, where possible" ([AdGuard DNS](https://adguard-dns.io/en/public-dns.html)). All checked 2026-08-16.

**Setting it on your router instead** covers every device in the house including televisions and consoles, which is the better version if you control the router. **It does nothing on cellular data**, so a phone that leaves the house leaves the filter behind. Per network DNS on the phone has the same gap. This is the reason people who need coverage everywhere end up on a paid tool that installs a device wide profile.

---

## Method 4: When to Pay for Something

Only when you need one of three things the free setup cannot do.

**Coverage across apps with real anti-bypass.** Canopy runs a network extension on iOS, installed as a VPN profile visible afterward under Settings, VPN & Device Management, and blocks third party VPNs so the standard workaround fails (Canopy support, checked 2026-08-16). Go in knowing its own reviewers report overblocking of ordinary content, heavy battery and data use, and slowdown (App Store, [Trustpilot](https://www.trustpilot.com/review/canopy.us), checked 2026-08-16).

**A report sent to another person.** Covenant Eyes filters device wide on iOS through a VPN and reports through a Safari extension, so filtering is broader than reporting: other browsers and apps are filtered but not reported ([TechLockdown](https://www.techlockdown.com/articles/covenant-eyes-iphone-review), checked 2026-08-16).

**Alerts about what someone sends a child.** Bark scans messages and social platforms, though on iPhone it depends on a physical accessory and coverage is periodic rather than continuous (Bark support, checked 2026-08-16).

If none of those three describes your situation, the free setup is genuinely sufficient and you can stop here.

---

## What None of This Covers

Worth being straight about the ceiling.

Content sent to you by another person is never requested from a server, so no filter sees it. An independent tester demonstrated this against Covenant Eyes on iPhone, installing a dating app and receiving suggestive images through messages without an alert firing ([Cranky Old Dan](https://crankyolddan.substack.com/p/you-cant-hide-those-covenant-eyes), checked 2026-08-16). That is not a flaw in one product, it is the boundary of the mechanism.

Filtering also changes availability rather than wanting, and it is not treatment. If several honest attempts have not moved the pattern and it is affecting sleep, work, or a relationship, a clinician is the useful next step. The [Psychology Today therapist directory](https://www.psychologytoday.com/us/therapists) filters by concern and location.

If any of this involves thoughts of self-harm, hopelessness, or a crisis of any kind, that comes first. In the US, the [988 Suicide and Crisis Lifeline](https://988lifeline.org/) is free, 24/7, by call, text, or chat, in English and Spanish.

---

## If the Trigger Is the App, Not the Browser

For some people the pattern is not searching for something. It is a reach for the phone with nothing in mind, at a predictable time, and the rest follows. A content filter has nothing to intercept there, because there was no decision.

[FaithLock](/) works on that layer, and only that layer. It is an iOS app that shields apps you choose using Apple's Family Controls API, and reopening one requires reading a Bible verse and answering a fill-in-the-blank question about it, drawn from the complete Berean Standard Bible library of 31,000 or more verses. **It is not a content filter and it does not report to anyone**, so it supplements the steps above rather than replacing any of them.

<a href="https://apps.apple.com/us/app/faith-lock-bible-prayer-focus/id6754208209">Get FaithLock on the App Store</a>

---

## Frequently Asked Questions

**How do I block adult content on iPhone for free?**
Settings, Screen Time, Content & Privacy Restrictions, App Store, Media, Web, & Games, Web Content, then Limit Adult Websites. Add a filtering DNS resolver for coverage across apps. Both are free and take under ten minutes together.

**Why can I not find Content Restrictions on my iPhone?**
Because the menu was reorganized. What older guides call Content Restrictions is now reached by tapping App Store, Media, Web, & Games inside Content & Privacy Restrictions. Web Content sits inside that screen.

**Does Limit Adult Websites work in all browsers?**
It applies to web content at the system level rather than to Safari alone. It does not reach content inside apps, and it does not see anything sent to you in a message.

**How do I stop myself from turning the filter off?**
Have another person set the Screen Time passcode without telling you. This is the only step that meaningfully changes the outcome for an adult filtering their own device, and it is free.

**Can I block adult content on iPhone without an app?**
Yes, completely. The built-in Screen Time restriction plus filtering DNS covers web content system wide and reaches apps on that connection, with nothing installed and nothing paid.

---

## Related Reading

- [Porn blocker for iPhone](/resources/porn-blocker-iphone)
- [Porn blocker: how each mechanism works](/resources/porn-blocker)
- [Free porn blocker options](/resources/free-porn-blocker)
- [Best porn blocker apps, scored](/resources/best-porn-blocker-apps)

---

*Sources: [Apple parental controls](https://support.apple.com/en-us/105121), [CleanBrowsing filters](https://cleanbrowsing.org/filters/), [Cloudflare 1.1.1.1 for Families](https://one.one.one.one/family/), [AdGuard public DNS](https://adguard-dns.io/en/public-dns.html), Canopy Shield iOS installation, Canopy on the App Store, [Canopy on Trustpilot](https://www.trustpilot.com/review/canopy.us), [TechLockdown on Covenant Eyes for iPhone](https://www.techlockdown.com/articles/covenant-eyes-iphone-review), Bark Sync support, [Cranky Old Dan](https://crankyolddan.substack.com/p/you-cant-hide-those-covenant-eyes), [988 Suicide and Crisis Lifeline](https://988lifeline.org/). All checked 2026-08-16.*
