//
//  PromoOfferAttributes.swift
//  FaithLock
//
//  Shared ActivityKit contract for the "reserved gift" Live Activity.
//
//  ⚠️ TARGET MEMBERSHIP: this file must belong to BOTH targets —
//  `Runner` (which starts/updates/ends the activity) and
//  `FaithLockWidgetExtension` (which renders it). ActivityKit matches the
//  activity to its UI by the *type*, so the two targets must compile the
//  exact same declaration.
//

import ActivityKit
import Foundation

/// A time-boxed welcome gift the user explicitly reserved.
///
/// The dynamic part is only the countdown target + the copy variant, so a
/// running activity never needs a server push: `Text(timerInterval:)` ticks on
/// its own and the activity self-dismisses at `expiresAt`.
@available(iOS 16.2, *)
struct PromoOfferAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// Lock Screen headline, e.g. "A small gift, just for you".
        var headline: String
        /// Secondary line, e.g. "Your first week for $1".
        var subhead: String
        /// Button copy, e.g. "Unwrap mine".
        var ctaLabel: String
        /// Short price token shown in the Dynamic Island expanded view.
        var priceLabel: String
        /// Real expiry. Drives the countdown AND the auto-dismissal.
        var expiresAt: Date
    }

    /// Offer identifier — mirrors the RevenueCat offering id so analytics on
    /// both sides can be joined.
    var offerId: String

    /// A/B variant tag, forwarded into the deep link for attribution.
    var variant: String
}
