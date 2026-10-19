//
//  FaithLockWidget.swift
//  FaithLockWidget
//
//  The @main entry point lives in FaithLockWidgetBundle.swift, which renders
//  this `FaithLockWidget`. Do not add @main here (would double-declare it).
//

import WidgetKit
import SwiftUI

// MARK: - Shared config

private let appGroupId = "group.com.appbiz.faithlock"
private let widgetKind = "FaithLockWidget"

// MARK: - Cozy palette (kept in sync with the Flutter CozyColors by eye)

private extension Color {
    static let cozyCream = Color(red: 0.98, green: 0.95, blue: 0.89)
    static let cozyInk = Color(red: 0.23, green: 0.16, blue: 0.12)
    static let cozyInkMuted = Color(red: 0.45, green: 0.37, blue: 0.31)
    static let cozyTerracotta = Color(red: 0.82, green: 0.45, blue: 0.29)
    static let cozySage = Color(red: 0.52, green: 0.60, blue: 0.47)
    static let cozySurface = Color(red: 1.0, green: 0.99, blue: 0.96)
}

// MARK: - Verse of the day

struct Verse {
    let text: String
    let ref: String
}

/// A small, self-contained bank so the widget changes EVERY DAY even if the app
/// is never opened. The index is the day-of-year, so it rotates at midnight.
private let verses: [Verse] = [
    Verse(text: "Blessed is the one whose delight is in the law of the Lord — like a tree planted by streams of water.", ref: "Psalm 1:1–3"),
    Verse(text: "Be still, and know that I am God.", ref: "Psalm 46:10"),
    Verse(text: "The Lord is my shepherd; I shall not want.", ref: "Psalm 23:1"),
    Verse(text: "I can do all things through Christ who strengthens me.", ref: "Philippians 4:13"),
    Verse(text: "Trust in the Lord with all your heart, and lean not on your own understanding.", ref: "Proverbs 3:5"),
    Verse(text: "Cast all your anxiety on him because he cares for you.", ref: "1 Peter 5:7"),
    Verse(text: "Come to me, all who are weary, and I will give you rest.", ref: "Matthew 11:28"),
    Verse(text: "The steadfast love of the Lord never ceases; his mercies are new every morning.", ref: "Lamentations 3:22–23"),
    Verse(text: "Wait for the Lord; be strong and take heart.", ref: "Psalm 27:14"),
    Verse(text: "Your word is a lamp to my feet and a light to my path.", ref: "Psalm 119:105"),
    Verse(text: "The Lord is near to the brokenhearted.", ref: "Psalm 34:18"),
    Verse(text: "Do not be anxious about anything, but in everything by prayer present your requests to God.", ref: "Philippians 4:6"),
    Verse(text: "This is the day the Lord has made; let us rejoice and be glad in it.", ref: "Psalm 118:24"),
    Verse(text: "For I know the plans I have for you, plans to give you hope and a future.", ref: "Jeremiah 29:11"),
    Verse(text: "Give thanks to the Lord, for he is good; his love endures forever.", ref: "Psalm 107:1"),
    Verse(text: "Be strong and courageous. The Lord your God will be with you wherever you go.", ref: "Joshua 1:9"),
    Verse(text: "Weeping may stay for the night, but joy comes in the morning.", ref: "Psalm 30:5"),
    Verse(text: "In quietness and trust is your strength.", ref: "Isaiah 30:15"),
    Verse(text: "The joy of the Lord is your strength.", ref: "Nehemiah 8:10"),
    Verse(text: "He gives strength to the weary and increases the power of the weak.", ref: "Isaiah 40:29"),
    Verse(text: "Love the Lord your God with all your heart and with all your soul.", ref: "Matthew 22:37"),
    Verse(text: "Let all that you do be done in love.", ref: "1 Corinthians 16:14"),
    Verse(text: "The Lord will fight for you; you need only to be still.", ref: "Exodus 14:14"),
    Verse(text: "Seek first the kingdom of God, and all these things will be added to you.", ref: "Matthew 6:33"),
    Verse(text: "Rejoice always, pray continually, give thanks in all circumstances.", ref: "1 Thessalonians 5:16–18"),
    Verse(text: "Whatever you do, work at it with all your heart, as working for the Lord.", ref: "Colossians 3:23"),
    Verse(text: "My grace is sufficient for you, for my power is made perfect in weakness.", ref: "2 Corinthians 12:9"),
    Verse(text: "The Lord is my light and my salvation — whom shall I fear?", ref: "Psalm 27:1"),
    Verse(text: "Let us not grow weary of doing good, for in due season we will reap.", ref: "Galatians 6:9"),
    Verse(text: "Peace I leave with you; my peace I give you.", ref: "John 14:27"),
    Verse(text: "As for me and my house, we will serve the Lord.", ref: "Joshua 24:15"),
    Verse(text: "The Lord bless you and keep you; the Lord make his face shine on you.", ref: "Numbers 6:24–25"),
    Verse(text: "Delight yourself in the Lord, and he will give you the desires of your heart.", ref: "Psalm 37:4"),
    Verse(text: "God is our refuge and strength, an ever-present help in trouble.", ref: "Psalm 46:1"),
    Verse(text: "Commit to the Lord whatever you do, and he will establish your plans.", ref: "Proverbs 16:3"),
    Verse(text: "Those who hope in the Lord will renew their strength.", ref: "Isaiah 40:31"),
    Verse(text: "Taste and see that the Lord is good.", ref: "Psalm 34:8"),
    Verse(text: "Let your light shine before others.", ref: "Matthew 5:16"),
    Verse(text: "The name of the Lord is a strong tower; the righteous run to it and are safe.", ref: "Proverbs 18:10"),
    Verse(text: "Be kind and compassionate to one another, forgiving each other.", ref: "Ephesians 4:32")
]

/// Date-seed identical to the app's BibleRepository.verseOfDay():
/// year*10000 + month*100 + day. Guarantees the widget picks the SAME verse
/// as the in-app Bible screen for a given day.
private func daySeed(_ date: Date) -> Int {
    let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
    return (c.year ?? 2024) * 10000 + (c.month ?? 1) * 100 + (c.day ?? 1)
}

private func verseForToday(_ date: Date) -> Verse {
    let seed = daySeed(date)
    let d = UserDefaults(suiteName: appGroupId)

    // 1) The exact verse the app pushed for today (already localized FR/EN) —
    //    matches the Bible screen verse-for-verse, including language.
    if d?.integer(forKey: "verseSeed") == seed,
       let t = d?.string(forKey: "verseText"), !t.isEmpty {
        return Verse(text: t, ref: d?.string(forKey: "verseRef") ?? "")
    }

    // 2) Same curriculum pool + same seed as the app → same reference, so future
    //    days advance correctly even if the app isn't opened (BSB text).
    if let shared = sharedVerses(), !shared.isEmpty {
        return shared[seed % shared.count]
    }

    // 3) Bundled fallback so it still rotates daily if the app has never run.
    return verses[seed % verses.count]
}

/// Reads the verse pool Flutter may have written into the App Group as a JSON
/// array of `{ "t": text, "r": ref }`. Returns nil if absent/unparseable.
private func sharedVerses() -> [Verse]? {
    guard
        let raw = UserDefaults(suiteName: appGroupId)?.string(forKey: "versePool"),
        let data = raw.data(using: .utf8),
        let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: String]]
    else { return nil }
    let mapped = arr.compactMap { dict -> Verse? in
        guard let t = dict["t"], let r = dict["r"] else { return nil }
        return Verse(text: t, ref: r)
    }
    return mapped.isEmpty ? nil : mapped
}

// MARK: - Garden stage

private func stageLabel(_ stage: Int) -> (emoji: String, name: String) {
    switch stage {
    case 5: return ("🍎", "Bearing fruit")
    case 4: return ("🌸", "Blooming")
    case 3: return ("🪴", "Growing strong")
    case 2: return ("🌿", "Sprouting")
    default: return ("🌱", "Freshly planted")
    }
}

// MARK: - Timeline

struct FaithEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let prayedToday: Bool
    let prayedMinutes: Int
    let versesToday: Int
    let stage: Int
    let health: Int // 0..100
    let verse: Verse
}

struct Provider: TimelineProvider {
    private func read() -> FaithEntry {
        let d = UserDefaults(suiteName: appGroupId)
        let now = Date()
        return FaithEntry(
            date: now,
            streak: d?.integer(forKey: "streak") ?? 0,
            prayedToday: d?.bool(forKey: "prayedToday") ?? false,
            prayedMinutes: d?.integer(forKey: "prayedMinutes") ?? 0,
            versesToday: d?.integer(forKey: "versesToday") ?? 0,
            stage: max(1, d?.integer(forKey: "gardenStage") ?? 1),
            health: d?.object(forKey: "gardenHealth") == nil ? 100 : (d?.integer(forKey: "gardenHealth") ?? 100),
            verse: verseForToday(now)
        )
    }

    func placeholder(in context: Context) -> FaithEntry {
        FaithEntry(date: Date(), streak: 5, prayedToday: true, prayedMinutes: 8,
                   versesToday: 3, stage: 4, health: 100, verse: verseForToday(Date()))
    }

    func getSnapshot(in context: Context, completion: @escaping (FaithEntry) -> Void) {
        completion(read())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FaithEntry>) -> Void) {
        let entry = read()
        // Reload at the start of tomorrow so the verse (and "prayed today")
        // flip over at midnight even without an app-triggered refresh.
        let startOfTomorrow = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date().addingTimeInterval(86400))
        completion(Timeline(entries: [entry], policy: .after(startOfTomorrow)))
    }
}

// MARK: - Views

private struct StreakBadge: View {
    let streak: Int
    let prayedToday: Bool
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .foregroundColor(streak > 0 ? .cozyTerracotta : .cozyInkMuted)
                .font(.system(size: 15, weight: .bold))
            Text("\(streak)")
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundColor(.cozyInk)
            Text(streak == 1 ? "day" : "days")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.cozyInkMuted)
        }
    }
}

struct SmallView: View {
    let entry: FaithEntry
    var body: some View {
        let s = stageLabel(entry.stage)
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundColor(entry.streak > 0 ? .cozyTerracotta : .cozyInkMuted)
                    .font(.system(size: 18, weight: .bold))
                Text("\(entry.streak)")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundColor(.cozyInk)
            }
            Text("day streak")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.cozyInkMuted)
            Spacer(minLength: 0)
            Text("\(s.emoji)  \(s.name)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.cozyInk)
                .lineLimit(1)
            Text(entry.prayedToday ? "Prayed today ✓" : "Not yet today")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(entry.prayedToday ? .cozySage : .cozyTerracotta)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(14)
    }
}

struct MediumView: View {
    let entry: FaithEntry
    var body: some View {
        let s = stageLabel(entry.stage)
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                StreakBadge(streak: entry.streak, prayedToday: entry.prayedToday)
                Text("\(s.emoji) \(s.name)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.cozyInk)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: "hands.sparkles.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.cozyInkMuted)
                    Text("\(entry.prayedMinutes) min today")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.cozyInkMuted)
                }
                Spacer(minLength: 0)
                Text(entry.prayedToday ? "Prayed today ✓" : "Tend it today 💧")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(entry.prayedToday ? .cozySage : .cozyTerracotta)
            }
            .frame(width: 120, alignment: .leading)

            Rectangle()
                .fill(Color.cozyInkMuted.opacity(0.15))
                .frame(width: 1)

            VStack(alignment: .leading, spacing: 6) {
                Text("VERSE OF THE DAY")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundColor(.cozyTerracotta)
                    .tracking(0.5)
                Text("“\(entry.verse.text)”")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.cozyInk)
                    .lineLimit(4)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 0)
                Text("— \(entry.verse.ref)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.cozyInkMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
    }
}

struct FaithLockWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: FaithEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall: SmallView(entry: entry)
            default: MediumView(entry: entry)
            }
        }
        .widgetBackground(Color.cozyCream)
    }
}

// Applies the iOS-17 containerBackground when available, plain background before.
private extension View {
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOS 17.0, *) {
            return AnyView(self.containerBackground(color, for: .widget))
        } else {
            return AnyView(self.background(color))
        }
    }
}

// MARK: - Widget

struct FaithLockWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: widgetKind, provider: Provider()) { entry in
            FaithLockWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("FaithLock")
        .description("Your streak, your garden, and a verse that changes every day.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
