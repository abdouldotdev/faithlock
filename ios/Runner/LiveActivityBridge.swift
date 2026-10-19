//
//  LiveActivityBridge.swift
//  Runner
//
//  MethodChannel bridge between Flutter and ActivityKit for the promo-offer
//  Live Activity. Registered from `AppDelegate`.
//
//  ⚠️ TARGET MEMBERSHIP: `Runner` only — but it needs `PromoOfferAttributes.swift`
//  (which lives in ios/FaithLockWidget/) added to the Runner target as well.
//

import ActivityKit
import Flutter
import Foundation

final class LiveActivityBridge {

    static let channelName = "faithlock/live_activity"

    /// Tracks the activity we started so `update`/`end` can target it without
    /// Flutter having to persist an id across launches.
    private static let promoOfferKind = "PromoOffer"

    static func register(with registrar: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar)
        channel.setMethodCallHandler { call, result in
            handle(call: call, result: result)
        }
    }

    // MARK: - Dispatch

    private static func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 16.2, *) else {
            switch call.method {
            case "isSupported", "areActivitiesEnabled", "isRunning":
                result(false)
            case "start":
                result(FlutterError(code: "unsupported",
                                    message: "Live Activities require iOS 16.2+",
                                    details: nil))
            default:
                result(nil)
            }
            return
        }

        switch call.method {
        case "isSupported":
            result(true)

        case "areActivitiesEnabled":
            result(ActivityAuthorizationInfo().areActivitiesEnabled)

        case "isRunning":
            result(!Activity<PromoOfferAttributes>.activities.isEmpty)

        case "start":
            start(args: call.arguments as? [String: Any] ?? [:], result: result)

        case "update":
            update(args: call.arguments as? [String: Any] ?? [:], result: result)

        case "end":
            end(immediately: (call.arguments as? [String: Any])?["immediately"] as? Bool ?? true,
                result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Operations

    @available(iOS 16.2, *)
    private static func start(args: [String: Any], result: @escaping FlutterResult) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            result(FlutterError(code: "disabled",
                                message: "Live Activities are disabled in Settings",
                                details: nil))
            return
        }

        // One at a time: a second reservation card would read as spam.
        for activity in Activity<PromoOfferAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }

        let attributes = PromoOfferAttributes(
            offerId: args["offerId"] as? String ?? "promo_dollar_week",
            variant: args["variant"] as? String ?? "control"
        )

        guard let state = contentState(from: args) else {
            result(FlutterError(code: "bad_args",
                                message: "Missing or invalid expiresAt",
                                details: nil))
            return
        }

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: state.expiresAt),
                pushType: nil
            )
            result(activity.id)
        } catch {
            result(FlutterError(code: "start_failed",
                                message: error.localizedDescription,
                                details: nil))
        }
    }

    @available(iOS 16.2, *)
    private static func update(args: [String: Any], result: @escaping FlutterResult) {
        guard let state = contentState(from: args) else {
            result(FlutterError(code: "bad_args", message: "Invalid state", details: nil))
            return
        }
        let activities = Activity<PromoOfferAttributes>.activities
        guard !activities.isEmpty else {
            result(false)
            return
        }
        Task {
            for activity in activities {
                await activity.update(
                    ActivityContent(state: state, staleDate: state.expiresAt)
                )
            }
            await MainActor.run { result(true) }
        }
    }

    @available(iOS 16.2, *)
    private static func end(immediately: Bool, result: @escaping FlutterResult) {
        let activities = Activity<PromoOfferAttributes>.activities
        guard !activities.isEmpty else {
            result(false)
            return
        }
        Task {
            for activity in activities {
                await activity.end(
                    nil,
                    dismissalPolicy: immediately ? .immediate : .default
                )
            }
            await MainActor.run { result(true) }
        }
    }

    // MARK: - Decoding

    @available(iOS 16.2, *)
    private static func contentState(from args: [String: Any]) -> PromoOfferAttributes.ContentState? {
        guard let expiresAtMs = args["expiresAtMs"] as? NSNumber else { return nil }
        let expiresAt = Date(timeIntervalSince1970: expiresAtMs.doubleValue / 1000.0)
        guard expiresAt > Date() else { return nil }

        return PromoOfferAttributes.ContentState(
            headline: args["headline"] as? String ?? "A small gift, just for you",
            subhead: args["subhead"] as? String ?? "Your first week for $1",
            ctaLabel: args["ctaLabel"] as? String ?? "Unwrap",
            priceLabel: args["priceLabel"] as? String ?? "$1 for 7 days",
            expiresAt: expiresAt
        )
    }
}
