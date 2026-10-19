---
slug: freedom-app-blocker-guide
title: Freedom App Blocker Guide (2026)
category: Guides
meta_title: "Freedom App Blocker Guide (2026): Setup, Locked Mode, Real Limits"
meta_description: "How to set up the Freedom app blocker across phone and computer, why Locked Mode needs a Screen Time passcode on iOS, and the billing complaints to know about."
---

## Quick Answer

The Freedom app blocker syncs one block list across iPhone, Android, Mac, Windows, and your browser, so a session you start on your laptop also hits your phone. On iOS it uses Apple's Screen Time API for apps and a local VPN profile for websites, with traffic staying on the device. Setup takes about ten minutes across two devices. The detail that catches people out: Freedom's own documentation says Locked Mode does not stop you from disabling Freedom's Screen Time permission on iPhone unless you have also set a separate Screen Time passcode.

*This page covers setup, configuration, and the things that break. For a verdict on Freedom against its closest rivals, see [Freedom vs Opal](/resources/freedom-vs-opal) and [Freedom vs Cold Turkey](/resources/freedom-vs-cold-turkey).*

---

## What Makes Freedom Different

Most blockers treat your phone as the problem. The Freedom app blocker, from Eighty Percent Solutions Corporation, treats your attention as the problem and your devices as interchangeable places where it leaks.

That difference is the whole reason to choose it. If you block Instagram on your iPhone and then open it in a laptop browser, you have not blocked Instagram; you have relocated it. Freedom is the only widely used consumer tool that closes that loop by default, covering iOS, Android, macOS, Windows, and extensions for Chrome, Safari, and Firefox from a single block list.

**Pricing, verified on freedom.to/pricing on 2026-08-15**: free plan $0, Premium $8.99 per month, Premium annual billed upfront at the equivalent of $3.33 per month, and a lifetime offer at $99.50, shown as 50% off a $199 list price.

---

## How Freedom Blocks on Each Platform

Worth understanding, because it explains both the strengths and the failure modes.

**iOS**: Apple's Screen Time API handles app blocking on iOS 16 and later. Website blocking runs through a local VPN, the "Freedom Profile," implemented with Network Extensions. Traffic never leaves your device; the profile exists so Freedom can filter across every browser rather than just Safari.

**Android**: a combination of the Device Admin API, the Accessibility API, and a local proxy or VPN. Device Admin blocks uninstalling from the home screen, though revoking admin rights is still possible.

**Desktop**: a local agent plus browser extensions on Windows and macOS.

---

## Setting Up the Freedom App Blocker

### 1. Create the account first, then install everywhere

Freedom syncs through your account, so install on every device you actually use before building any lists. A block list that covers two of your three devices is the same as no block list.

### 2. Approve the Freedom Profile on iPhone

On iOS you will be asked to install the Freedom Profile (the local VPN) and to grant Screen Time access. Both are needed: Screen Time handles apps, the profile handles websites across browsers. You can verify it later under Settings, VPN & Device Management.

### 3. Build one block list, not five

Freedom lets you create custom block lists synced across devices. Resist making a separate list for every mood. Two is usually right: a work list (social, news, video) and a much harder evening list. More than that and you will spend the session choosing a list rather than working.

### 4. Schedule recurring sessions

Scheduled and recurring sessions are the point of the product. Set the block to start at 9am and at 9pm on the days that matter, and stop deciding in the moment. Ambient focus sounds (music, cafe, office, nature) are built in if you use audio to anchor a work block.

### 5. Turn on Locked Mode, and understand what it covers

Locked Mode prevents editing or stopping an active session, with one early exit allowed every seven days. It is the feature that makes Freedom stick for most people.

Read this part carefully: Freedom's own support documentation states that on iOS, Locked Mode does not by itself prevent disabling Freedom's Screen Time permission in the phone's settings, unless a separate Screen Time passcode is also configured. On Android, Device Admin blocks uninstalling from the home screen, but revoking admin rights still gets around it.

### 6. Set a Screen Time passcode you do not control

This is the step that turns Locked Mode from a speed bump into a wall on iPhone. Go to Settings, Screen Time, and have someone else set the passcode. Every third-party blocker on iOS is stronger with this done, and Freedom explicitly needs it.

---

## Known Problems Worth Knowing

From App Store reviews and Trustpilot, not from speculation:

- **Over-blocking.** App Store reviews report a limited block accidentally blocking "the entirety of the internet," and one case where the app made an iPhone unusable to the point of requiring a reinstall. Test a new list on a short session before locking it for eight hours.
- **Partial enforcement on iOS.** An independent review reports that outside an active Screen Time session, the app can show a blocked message rather than genuinely preventing the app from opening, and that blocking is bypassable by switching browsers, using a proxy, or uninstalling.
- **Billing complaints.** Trustpilot reviews report refund difficulties and billing described as not transparent. If you are trying Freedom, know your cancellation route before the trial converts.

---

## Getting the Most Out of It

**Do not run a second Screen Time blocker.** Jomo's own troubleshooting documentation names conflicts with other Screen Time apps as a common cause of blocks failing to engage or failing to release. If you already run Opal or Jomo, pick one.

**Start the block on the computer.** Sessions sync, so triggering from the device you are already sitting at removes the temptation to "just not start it" on the phone.

**Use the seven-day early exit as a diagnostic.** If you burn it every week, your schedule is wrong rather than your willpower. Move the block window rather than shortening it.

**Keep a short allowlist mindset.** The most common Freedom failure is a block list so aggressive that the user disables everything to get one legitimate site back.

---

## How It Compares

**Cold Turkey Blocker** is stricter than Freedom on Windows, with a Frozen Turkey mode that cannot be stopped before its deadline, blocking of unsupported browsers, and prevention of system clock or region changes to cheat the schedule. Pro is a $39 one-time purchase per a 2026-dated review. It has no mobile version at all, so it solves half the problem. Reviews also report notably poorer reliability on macOS due to sandboxing. See [Freedom vs Cold Turkey](/resources/freedom-vs-cold-turkey).

**Opal** is the stronger single-device iPhone tool, with a Deep Focus mode that cannot be cancelled once started and much deeper reporting. It costs more, with Pro at $99.99 per year per an independent review published March 2026, checked 2026-08-15, and its free plan excludes Deep Focus. See [Freedom vs Opal](/resources/freedom-vs-opal).

**FaithLock** takes the opposite approach to Freedom's breadth. It covers one platform, iOS, through Apple's Family Controls (Screen Time) API, and puts its effort into the moment you hit a blocked app: a Bible verse from the complete BSB library of 31,000+ verses, and a question about what you just read. Scheduled lock times cover morning devotion, work hours, and bedtime. There is no desktop version and no Android version, so it will not replace Freedom if the laptop is your real problem. If your phone is the whole problem and a countdown timer has never held you, it is a different kind of friction worth trying.

[Download FaithLock on the App Store](https://apps.apple.com/us/app/faith-lock-bible-prayer-focus/id6754208209)

---

## Frequently Asked Questions

**Is the Freedom app blocker free?**
There is a free plan at $0, verified on freedom.to/pricing on 2026-08-15. Premium runs $8.99 per month, or annual billing that works out to $3.33 per month paid upfront, with a lifetime offer at $99.50 shown as 50% off a $199 list price. The free plan is limited enough that most people evaluating Freedom are really evaluating Premium.

**Why does Freedom install a VPN on my iPhone?**
To block websites across every browser rather than just Safari. Freedom's documentation describes the Freedom Profile as a local VPN built with Network Extensions, with traffic never leaving your device. App blocking on iOS is handled separately, through Apple's Screen Time API.

**Can I bypass Freedom's Locked Mode?**
On iOS, yes, unless you have taken one extra step. Freedom's own support documentation states Locked Mode does not by itself prevent disabling Freedom's Screen Time permission in Settings, unless a separate Screen Time passcode is configured. On Android, revoking Device Admin rights gets around the uninstall protection.

**Does the Freedom app blocker work on a phone and a computer at the same time?**
Yes, and that is its main advantage over single-device blockers. One block list and one session apply across iOS, Android, macOS, Windows, and the Chrome, Safari, and Firefox extensions.

**What is a stricter alternative to the Freedom app blocker?**
On Windows, Cold Turkey Blocker, whose Frozen Turkey mode cannot be interrupted before its deadline. On iPhone alone, Opal's Deep Focus or Jomo's Strict Mode. All three are compared in our roundup of the [best app blockers for iPhone](/resources/best-app-blockers-iphone) and the [best time blocker apps](/resources/best-time-blocker-apps).

---

*Sources: Freedom pricing, Freedom, how Freedom blocks apps and websites on iOS, Freedom Profile VPN explained, Freedom Locked Mode, Freedom for Android options, Freedom on the App Store, [Freedom on Trustpilot](https://www.trustpilot.com/review/freedom.to), Blok.so Freedom review, Cold Turkey pricing, tryhugo.app Cold Turkey review*
