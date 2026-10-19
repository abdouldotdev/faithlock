# Live Activities — Plan complet FaithLock

> Spec d'implémentation des Live Activities + Dynamic Island pour FaithLock.
> Couvre 5 cas d'usage classés par impact business, avec code Swift + Flutter prêt à l'emploi.

---

## 📋 Vue d'ensemble

| # | Cas d'usage | Impact | Effort | Priorité |
|---|-------------|--------|--------|----------|
| 1 | **Prière audio en cours** | 🟢🟢🟢 (rétention + WOW) | 1.5j | 🥇 P0 |
| 2 | **Welcome Gift promo** (non-subs) | 🟢🟢🟢 (+15-30% conversion) | 1j | 🥈 P0 |
| 3 | **App Lock countdown** | 🟢🟢 (différenciateur unique) | 1j | 🥉 P1 |
| 4 | **Verse of the Day** persistant | 🟢 (rétention émotionnelle) | 0.5j | P2 |
| 5 | **Streak quotidien** | 🟢 (engagement) | 0.5j | P3 |

**Roadmap suggérée** : P0 (Prière + Gift) en sprint 1 → P1 (Lock countdown) en sprint 2 → P2/P3 bonus.

---

## 🏗️ Setup commun (à faire UNE fois)

### 1. Plugin Flutter

```yaml
# pubspec.yaml
dependencies:
  live_activities: ^2.4.0
```

### 2. Xcode — Widget Extension target

1. Ouvrir `ios/Runner.xcworkspace`
2. **File → New → Target → Widget Extension**
3. Nom : `FaithLockActivities`
4. ✅ Cocher **"Include Live Activity"**
5. Deployment target : **iOS 16.2+** (16.1 a un bug Dynamic Island)

### 3. Info.plist (Runner)

```xml
<key>NSSupportsLiveActivities</key>
<true/>
<key>NSSupportsLiveActivitiesFrequentUpdates</key>
<true/>
```

### 4. App Group (pour le bridge Flutter ↔ Widget)

- Apple Developer Portal → créer App Group : `group.com.faithlock.app`
- L'activer sur les **2 targets** : `Runner` ET `FaithLockActivities`

### 5. Architecture globale

```
┌─────────────────────────┐
│  Flutter (Dart)         │
│  LiveActivityService    │
└──────────┬──────────────┘
           │ MethodChannel (live_activities plugin)
┌──────────▼──────────────┐
│  iOS Swift              │
│  ActivityKit            │
└──────────┬──────────────┘
           │
┌──────────▼──────────────┐
│  Widget Extension       │
│  - PrayerActivity       │
│  - GiftActivity         │
│  - LockCountdownActivity│
│  - VerseOfDayActivity   │
└─────────────────────────┘
```

---

## 🥇 Cas 1 — Prière audio en cours

### Vision UX

L'user lance une prière, verrouille son téléphone, et le Live Activity affiche en temps réel :
- Verset en cours (synchro avec flutter_tts)
- Progress bar
- Pause/skip controls
- Timer restant

**Pourquoi c'est puissant** : transforme le téléphone en compagnon de prière physique. L'user peut prier en marchant/conduisant — Spotify-like mais spirituel.

### Mockup

```
Lock Screen:
┌────────────────────────────────────────┐
│ 🕯️  Morning Gratitude     2:34 / 5:00 │
│                                        │
│ "The Lord is my shepherd,             │
│  I shall not want."                    │
│ PSALM 23:1                             │
│                                        │
│ ▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░  ⏸  ⏭            │
└────────────────────────────────────────┘

Dynamic Island compact:
🕯️  ●▓▓▓░     (icône + anneau progression)

Dynamic Island expanded:
🕯️  Morning Gratitude
    "The Lord is my shepherd..."
    ▓▓▓▓▓▓▓▓░░░  2:26 left
```

### Swift — Attributes

```swift
// ios/FaithLockActivities/PrayerActivityAttributes.swift
import ActivityKit

struct PrayerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var currentVerse: String
        var verseReference: String
        var progress: Double
        var elapsedSeconds: Int
        var totalSeconds: Int
        var isPaused: Bool
    }

    var prayerTitle: String
    var prayerDomain: String
}
```

### Swift — Widget UI

```swift
// ios/FaithLockActivities/PrayerActivityWidget.swift
import WidgetKit
import SwiftUI
import ActivityKit

struct PrayerActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PrayerActivityAttributes.self) { context in
            // ── Lock Screen ──
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(Color("CozyTerracotta"))
                    Text(context.attributes.prayerTitle)
                        .font(.headline)
                    Spacer()
                }
                Text("\u{201C}\(context.state.currentVerse)\u{201D}")
                    .font(.body).italic()
                    .lineLimit(3)
                Text(context.state.verseReference.uppercased())
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                ProgressView(value: context.state.progress)
                    .tint(Color("CozyTerracotta"))
            }
            .padding()
            .activityBackgroundTint(Color("CozyCream"))

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "flame.fill").foregroundColor(.orange)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date()...Date().addingTimeInterval(
                        TimeInterval(context.state.totalSeconds - context.state.elapsedSeconds)
                    )).monospacedDigit().font(.caption)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.currentVerse).font(.caption).lineLimit(2)
                }
            } compactLeading: {
                Image(systemName: "flame.fill")
            } compactTrailing: {
                ProgressView(value: context.state.progress)
                    .progressViewStyle(.circular)
                    .frame(width: 18, height: 18)
            } minimal: {
                Image(systemName: "flame.fill")
            }
        }
    }
}
```

### Flutter Service

```dart
// lib/services/prayer_live_activity_service.dart
import 'package:live_activities/live_activities.dart';

class PrayerLiveActivityService {
  static final _plugin = LiveActivities();
  static String? _activityId;

  static Future<void> init() async {
    await _plugin.init(appGroupId: 'group.com.faithlock.app');
  }

  static Future<void> start({
    required String prayerTitle,
    required String prayerDomain,
    required String firstVerse,
    required String reference,
    required int totalSeconds,
  }) async {
    _activityId = await _plugin.createActivity({
      'prayerTitle': prayerTitle,
      'prayerDomain': prayerDomain,
      'currentVerse': firstVerse,
      'verseReference': reference,
      'progress': 0.0,
      'elapsedSeconds': 0,
      'totalSeconds': totalSeconds,
      'isPaused': false,
    });
  }

  static Future<void> update({
    required String verse,
    required String reference,
    required int elapsed,
    required int total,
    bool isPaused = false,
  }) async {
    if (_activityId == null) return;
    await _plugin.updateActivity(_activityId!, {
      'currentVerse': verse,
      'verseReference': reference,
      'progress': elapsed / total,
      'elapsedSeconds': elapsed,
      'totalSeconds': total,
      'isPaused': isPaused,
    });
  }

  static Future<void> end() async {
    if (_activityId == null) return;
    await _plugin.endActivity(_activityId!);
    _activityId = null;
  }
}
```

### Hook dans le PrayerAudioController

```dart
// Au démarrage de la prière
await PrayerLiveActivityService.start(
  prayerTitle: prayer.title,
  prayerDomain: prayer.domain.id,
  firstVerse: prayer.verses.first.text,
  reference: prayer.verses.first.reference,
  totalSeconds: prayer.durationSeconds,
);

// Update PAR VERSET (pas par mot — throttle Apple)
void onVerseChanged(Verse newVerse) {
  PrayerLiveActivityService.update(
    verse: newVerse.text,
    reference: newVerse.reference,
    elapsed: _elapsedSeconds,
    total: prayer.durationSeconds,
  );
}

// À la fin / stop
await PrayerLiveActivityService.end();
```

### ⚠️ Gotchas

- **Throttle Apple** : max ~1 update / 2-3s. Update par **verset**, pas par mot.
- **Self-running timer** : utiliser `Text(timerInterval:...)` côté Swift → le timer tourne tout seul sans push depuis Flutter.
- **8h max sans push** : OK pour une prière < 8h.

---

## 🥈 Cas 2 — Welcome Gift Promo (non-subscribers)

### Vision UX

Pour les users non-abonnés, afficher un **gift mystérieux avec countdown** sur le Lock Screen pendant les 7 premiers jours après install.
- Tap → ouvre la paywall avec deeplink trackable
- Vraie expiration après 7 jours (anti-rejet Apple)
- Pause pendant les autres Live Activities (prière)

### Mockup

```
Lock Screen:
┌──────────────────────────────────────────┐
│   ┌─────┐    ✨ A small gift, just for   │
│   │ 🎁  │       you                      │
│   │  🕊️ │                                │
│   └─────┘       Yours until 23:37:48     │
│                                          │
│              ╭──────────────────╮        │
│              │ 👉 Unwrap mine   │        │
│              ╰──────────────────╯        │
└──────────────────────────────────────────┘
   fond cream + bordure terracotta chunky

Dynamic Island compact:
🎁              23h 14m

Dynamic Island expanded:
🎁  Day 2 of 7
    Tap to claim your gift →
    23h 14m left
```

### Copy validés (naturel, on-brand)

| Élément | Texte |
|---------|-------|
| **Title** | "A small gift, just for you" |
| **Urgency label** | "Yours until" |
| **CTA** | "Unwrap mine →" |
| **DI expanded subtitle** | "Day {N} of 7" |

❌ À éviter : "FREE TRIAL", caps lock, "BUY NOW", urgency fake.

### Swift — Attributes

```swift
struct GiftActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var dayNumber: Int
        var totalDays: Int
        var expiresAt: Date
    }
    var giftTitle: String
}
```

### Swift — Widget UI

```swift
struct GiftActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GiftActivityAttributes.self) { context in
            Link(destination: URL(string: "faithlock://paywall?src=gift")!) {
                HStack(spacing: 14) {
                    ZStack {
                        Image("gift_cozy").resizable().scaledToFit()
                            .frame(width: 72, height: 72)
                        Text("✨").font(.system(size: 16))
                            .offset(x: 28, y: -28)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("A small gift, just for you")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color("CozyInk"))
                            .lineLimit(1)
                        HStack(spacing: 4) {
                            Text("Yours until")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color("CozyInkMuted"))
                            Text(timerInterval: Date()...context.state.expiresAt,
                                 countsDown: true)
                                .font(.system(size: 18, weight: .heavy).monospacedDigit())
                                .foregroundColor(Color("CozyInk"))
                        }
                        HStack(spacing: 6) {
                            Text("👉")
                            Text("Unwrap mine")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().fill(Color("CozyTerracotta")))
                        .overlay(Capsule().stroke(Color("CozyInk"), lineWidth: 1.5))
                    }
                    Spacer()
                }
                .padding(14)
            }
            .activityBackgroundTint(Color("CozyCream"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) { Text("🎁").font(.title2) }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date()...context.state.expiresAt, countsDown: true)
                        .monospacedDigit().font(.caption)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Tap to claim your free trial →")
                        .font(.caption).foregroundColor(.orange)
                }
            } compactLeading: { Text("🎁") }
            compactTrailing: {
                Text(timerInterval: Date()...context.state.expiresAt, countsDown: true)
                    .monospacedDigit().font(.caption2).frame(maxWidth: 50)
            } minimal: { Text("🎁") }
            .widgetURL(URL(string: "faithlock://paywall?src=gift"))
        }
    }
}
```

### Flutter Service

```dart
class GiftLiveActivityService {
  static const _trialDays = 7;
  static String? _activityId;

  static Future<void> startIfEligible() async {
    if (await SubscriptionService.isPremium) return;
    if (_activityId != null) return;

    final installDate = await StorageService.getInstallDate();
    final daysSinceInstall = DateTime.now().difference(installDate).inDays;

    if (daysSinceInstall >= _trialDays) return; // vraie expiration

    final dayNumber = daysSinceInstall + 1;
    final expiresAt = DateTime.now().add(const Duration(hours: 24));

    _activityId = await LiveActivities().createActivity({
      'giftTitle': '7-Day Welcome Gift',
      'dayNumber': dayNumber,
      'totalDays': _trialDays,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
    });

    AnalyticsService.track('gift_activity_shown', {'day': dayNumber});
  }

  static Future<void> end() async {
    if (_activityId != null) {
      await LiveActivities().endActivity(_activityId!);
      _activityId = null;
    }
  }
}
```

### Triggers

```dart
// main.dart après init
GiftLiveActivityService.startIfEligible();

// Quand l'user subscribe
SubscriptionService.onPurchased.listen((_) => GiftLiveActivityService.end());

// Deep link handler
uriLinkStream.listen((Uri? uri) {
  if (uri?.path == '/paywall' && uri?.queryParameters['src'] == 'gift') {
    AnalyticsService.track('gift_activity_tapped');
    Get.toNamed('/paywall', arguments: {'source': 'live_activity_gift'});
  }
});
```

### Asset à générer

Prompt (style cohérent avec `bible_verse_illustration.png`) :

```
Cozy hand-drawn illustration of a wrapped gift box,
warm terracotta and cream colors, fluffy cream ribbon with a bow on top,
small white dove or olive branch decoration sitting on the bow,
chunky thick brown outlines, flat shading,
slightly imperfect hand-drawn lines, storybook illustration style,
small sparkles floating around the gift,
centered composition, isolated on pure transparent background, PNG with alpha,
palette: cream #F5E9D4, terracotta #C9663E, warm brown #6B4226, soft gold #D4A056
--ar 1:1 --style raw
```

→ Sauvegarde : `assets/images/gift_cozy.png` + copier dans `ios/FaithLockActivities/Assets.xcassets/`.

---

## 🥉 Cas 3 — App Lock countdown

### Vision UX

Quand l'user a bloqué Instagram/TikTok via FaithLock, afficher sur Lock Screen :
- Nom de l'app bloquée
- Countdown jusqu'au déverrouillage
- Bouton "Pray to unlock now" (iOS 17+ interactive)

**Pourquoi c'est génial** : résout l'anxiété "quand est-ce que je peux check ?" sans ouvrir l'app. Le bouton transforme la friction en moment spirituel.

### Mockup

```
Lock Screen:
┌──────────────────────────────────────────┐
│ 🔒 Instagram is locked                   │
│    Unlocks in 47 min                     │
│                                          │
│    ╭───────────────────────────╮         │
│    │ 🙏 Pray to unlock now      │         │
│    ╰───────────────────────────╯         │
└──────────────────────────────────────────┘

Dynamic Island compact:
🔒  47m
```

### Swift — Attributes

```swift
struct LockCountdownAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var unlocksAt: Date
        var lockedAppName: String
    }
    var lockedAppIconName: String  // SF Symbol ou asset
}
```

### Interactive button (iOS 17+)

```swift
// AppIntent pour le bouton "Pray to unlock"
struct PrayToUnlockIntent: AppIntent {
    static var title: LocalizedStringResource = "Pray to unlock"

    func perform() async throws -> some IntentResult {
        // Deep link vers le challenge
        // L'app s'ouvre via faithlock://challenge/start
        return .result()
    }
}

// Dans le widget
Button(intent: PrayToUnlockIntent()) {
    Label("Pray to unlock", systemImage: "hands.sparkles.fill")
}
.buttonStyle(.borderedProminent)
.tint(Color("CozyTerracotta"))
```

### Flutter triggers

```dart
// Quand un blocage commence
LockCountdownActivityService.start(
  appName: 'Instagram',
  iconName: 'instagram_icon',
  unlocksAt: schedule.endTime,
);

// Quand l'user complete un challenge
LockCountdownActivityService.end();
```

---

## 📖 Cas 4 — Verse of the Day persistant

### Vision UX

Toute la journée, le verset du jour reste sur le lock screen comme un fond spirituel passif. Auto-refresh à minuit.

### Mockup

```
Lock Screen:
┌──────────────────────────────────────────┐
│ 📖  Verse of the Day                     │
│                                          │
│ "Be still, and know that I am God."     │
│                                          │
│ PSALM 46:10                              │
└──────────────────────────────────────────┘
```

### Swift — Attributes

```swift
struct VerseOfDayAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var verseText: String
        var verseReference: String
        var refreshesAt: Date  // minuit
    }
}
```

### Stratégie

- Activity démarre au premier launch du jour
- Update à minuit avec nouveau verset
- Si user subscribe à un autre verset (ex: Psalms only), filter côté Flutter

### Conflit avec autres activities

⚠️ Apple limite ~2 activities simultanées. Voir [Coexistence](#coexistence) ci-dessous.

---

## 🔥 Cas 5 — Streak quotidien (bonus)

### Vision UX

Petit badge "🔥 12 jours · À lire aujourd'hui" sur le lock screen.

```
Dynamic Island compact:
🔥  12

Lock Screen:
┌──────────────────────────────────────────┐
│ 🔥  12-day streak                        │
│     Read today's verse to keep it alive │
│     ╭──────────╮                         │
│     │ Read now │                         │
│     ╰──────────╯                         │
└──────────────────────────────────────────┘
```

### Combinaison possible avec Cas 4

Peut fusionner avec **Verse of the Day** dans une seule Live Activity (verset + streak badge).

---

## 🔀 Coexistence des activities

Apple limite ~2 activities actives simultanément. Logique de priorité :

```dart
class LiveActivityCoordinator {
  // Priorité : Prière > Gift > Lock countdown > Verse
  
  static Future<void> onPrayerStart() async {
    await GiftLiveActivityService.end();         // ⏸ pause gift
    await VerseOfDayService.end();               // ⏸ pause verse
    // Prière prend le devant
  }

  static Future<void> onPrayerEnd() async {
    // Restaurer les activities en background
    await GiftLiveActivityService.startIfEligible();
    await VerseOfDayService.startIfEligible();
  }

  static Future<void> onAppLockStart() async {
    // App lock peut coexister avec verse, mais pas avec prière
    if (!PrayerLiveActivityService.isActive) {
      await LockCountdownService.start(...);
    }
  }

  static Future<void> onSubscribed() async {
    await GiftLiveActivityService.end();  // plus de promo
  }
}
```

---

## ⚖️ Apple Review — guidelines

✅ **À faire**
- Vraie expiration (jamais de timer fake qui reset)
- Framing "Welcome offer" / "Limited welcome gift"
- Time-sensitive REAL information (countdown vrai, état app vrai)
- Mentionner les Live Activities dans les submission notes
- Privacy policy explicite

❌ **À éviter**
- "FREE TRIAL 50% OFF NOW" agressif
- CAPS LOCK
- Activities permanentes purement marketing
- Plus de 2 activities simultanées
- Updates > 1 par seconde (throttle)

---

## 🎨 Assets à générer

| Asset | Usage | Format | Notes |
|-------|-------|--------|-------|
| `gift_cozy.png` | Gift activity | PNG transparent 256×256 | Prompt fourni ci-dessus |
| `flame_cozy.png` | Prayer activity (optionnel) | PNG transparent 64×64 | Sinon SF Symbol `flame.fill` |
| `lock_cozy.png` | Lock countdown (optionnel) | PNG transparent 64×64 | Sinon SF Symbol `lock.fill` |
| `verse_book.png` | Verse of day | PNG transparent 64×64 | Réutiliser `bible_verse_illustration.png` |

**Couleurs Asset Catalog** (à créer dans `FaithLockActivities/Assets.xcassets/`) :
- `CozyCream` : `#F5E9D4`
- `CozyTerracotta` : `#C9663E`
- `CozyInk` : `#6B4226`
- `CozyInkMuted` : `#9B7B5A`
- `CozyPeach` : `#F5C8A3`

---

## 📊 Tracking analytics

### Events à logger

```dart
// Prayer
AnalyticsService.track('prayer_activity_started', {'prayer_id': id});
AnalyticsService.track('prayer_activity_ended', {'completion_pct': 0.87});

// Gift
AnalyticsService.track('gift_activity_shown', {'day': dayNumber});
AnalyticsService.track('gift_activity_tapped');
AnalyticsService.track('gift_activity_converted'); // après purchase

// Lock countdown
AnalyticsService.track('lock_activity_shown', {'app': 'instagram'});
AnalyticsService.track('lock_activity_pray_tapped');

// Verse
AnalyticsService.track('verse_activity_refreshed', {'verse_ref': '...'});
```

### Métriques clés à monitorer

- **Conversion rate** : `gift_activity_tapped` / `gift_activity_shown`
- **Paywall conversion** : `gift_activity_converted` / `gift_activity_tapped`
- **Prayer engagement** : durée moyenne d'écoute via Live Activity vs in-app
- **Lock unlock rate** : `lock_activity_pray_tapped` / `lock_activity_shown`

---

## ⏱️ Effort total estimé

| Phase | Tâches | Effort |
|-------|--------|--------|
| **Setup** | Xcode target, plugin, App Group, Info.plist | 2h |
| **P0a — Prière** | Attributes, Widget UI, service, hook TTS, test | 1.5j |
| **P0b — Gift** | Attributes, Widget UI, service, deep link, paywall integration | 1j |
| **P1 — Lock countdown** | Attributes, Widget UI (avec AppIntent), service | 1j |
| **P2 — Verse of Day** | Attributes, Widget UI, refresh logic | 0.5j |
| **P3 — Streak** | Fusion avec Verse of Day | 0.5j |
| **Coordinator** | Logique coexistence + transitions | 0.5j |
| **QA + tests** | Tests sur device, edge cases, lifecycle | 1j |

**Total : ~7-8 jours** pour les 5 cas. **Sprint MVP (P0 only) : 3 jours**.

---

## 🗺️ Roadmap suggérée

### Sprint 1 (3 jours) — MVP impact max
- [ ] Setup commun (Xcode target + plugin)
- [ ] Cas 1 (Prière audio)
- [ ] Cas 2 (Welcome Gift)
- [ ] Coordinator de base
- [ ] Tracking analytics

### Sprint 2 (2 jours) — Différenciation
- [ ] Cas 3 (Lock countdown + AppIntent)
- [ ] Génération assets manquants
- [ ] QA Live Activities

### Sprint 3 (1 jour) — Polish
- [ ] Cas 4 + 5 (Verse of Day + Streak fusionnés)
- [ ] A/B test sur copy Gift
- [ ] Soumission App Store avec notes Live Activities

---

## 📚 Références

- [Apple — Displaying live data with Live Activities](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities)
- [Apple — Designing for Live Activities (HIG)](https://developer.apple.com/design/human-interface-guidelines/live-activities)
- [`live_activities` Flutter plugin](https://pub.dev/packages/live_activities)
- [WWDC 2023 — Bring widgets to life with interactivity](https://developer.apple.com/videos/play/wwdc2023/10184/)
