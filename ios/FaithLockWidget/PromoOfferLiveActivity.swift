//
//  PromoOfferLiveActivity.swift
//  FaithLockWidget
//
//  Lock Screen / Notification Center card + Dynamic Island presentation for
//  the reserved welcome gift. Registered from `FaithLockWidgetBundle`.
//
//  ⚠️ TARGET MEMBERSHIP: `FaithLockWidgetExtension` only.
//

import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Cozy palette
// Duplicated intentionally: `FaithLockWidget.swift` declares these as a
// file-private extension, so they are not visible here.

private extension Color {
    static let promoCream = Color(red: 0.98, green: 0.95, blue: 0.89)
    static let promoInk = Color(red: 0.23, green: 0.16, blue: 0.12)
    static let promoInkMuted = Color(red: 0.45, green: 0.37, blue: 0.31)
    static let promoTerracotta = Color(red: 0.82, green: 0.45, blue: 0.29)
    static let promoPeach = Color(red: 0.95, green: 0.85, blue: 0.74)
}

// MARK: - Deep link

@available(iOS 16.2, *)
private func promoURL(_ attributes: PromoOfferAttributes) -> URL {
    var components = URLComponents()
    components.scheme = "faithlock"
    components.host = "promo"
    components.queryItems = [
        URLQueryItem(name: "src", value: "live_activity"),
        URLQueryItem(name: "offer", value: attributes.offerId),
        URLQueryItem(name: "variant", value: attributes.variant),
    ]
    return components.url ?? URL(string: "faithlock://promo?src=live_activity")!
}

// MARK: - Countdown

/// Monospaced ticking countdown. `Text(timerInterval:)` is rendered by the
/// system, so it keeps counting without the app running.
@available(iOS 16.2, *)
private struct CountdownText: View {
    let expiresAt: Date
    var size: CGFloat = 18
    var color: Color = .promoInk

    var body: some View {
        Text(timerInterval: Date()...max(expiresAt, Date().addingTimeInterval(1)),
             countsDown: true)
            .font(.system(size: size, weight: .heavy, design: .rounded).monospacedDigit())
            .foregroundColor(color)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}

// MARK: - Gift mark

@available(iOS 16.2, *)
private struct GiftMark: View {
    var size: CGFloat = 54

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                .fill(Color.promoPeach)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                        .stroke(Color.promoInk, lineWidth: 2)
                )
            Text("🎁").font(.system(size: size * 0.5))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Lock Screen / Notification Center

@available(iOS 16.2, *)
private struct PromoLockScreenView: View {
    let context: ActivityViewContext<PromoOfferAttributes>

    var body: some View {
        HStack(spacing: 14) {
            GiftMark()

            VStack(alignment: .leading, spacing: 5) {
                Text(context.state.headline)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(.promoInk)
                    .lineLimit(1)

                Text(context.state.subhead)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.promoInkMuted)
                    .lineLimit(1)

                HStack(spacing: 5) {
                    Text("Yours for")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.promoInkMuted)
                    CountdownText(expiresAt: context.state.expiresAt, size: 16)
                }
                .padding(.top, 1)
            }

            Spacer(minLength: 4)

            Text(context.state.ctaLabel)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    Capsule()
                        .fill(Color.promoTerracotta)
                        .overlay(Capsule().stroke(Color.promoInk, lineWidth: 1.5))
                )
                .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .activityBackgroundTint(Color.promoCream)
        .activitySystemActionForegroundColor(Color.promoInk)
    }
}

// MARK: - Widget

@available(iOS 16.2, *)
struct PromoOfferLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PromoOfferAttributes.self) { context in
            PromoLockScreenView(context: context)
                .widgetURL(promoURL(context.attributes))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    GiftMark(size: 40)
                        .padding(.leading, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        CountdownText(
                            expiresAt: context.state.expiresAt,
                            size: 17,
                            color: .white
                        )
                        Text("left")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.trailing, 4)
                }

                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.priceLabel)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    Link(destination: promoURL(context.attributes)) {
                        Text(context.state.ctaLabel)
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                Capsule().fill(Color.promoTerracotta)
                            )
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 2)
                }
            } compactLeading: {
                Text("🎁").font(.system(size: 15))
            } compactTrailing: {
                CountdownText(
                    expiresAt: context.state.expiresAt,
                    size: 13,
                    color: .promoPeach
                )
                .frame(maxWidth: 52)
            } minimal: {
                Text("🎁").font(.system(size: 14))
            }
            .widgetURL(promoURL(context.attributes))
            .keylineTint(Color.promoTerracotta)
        }
    }
}
