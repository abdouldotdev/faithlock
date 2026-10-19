# Dynamic Island — offre promo « 1ère semaine à 1 $ »

> Live Activity + page d'offre. Implémenté le 2026-08-16.
> Complète `docs/live-activities-plan.md` (cas 2 « Welcome Gift »), qu'il remplace
> sur ce périmètre précis.

---

## 1. Le risque à connaître avant tout

L'HIG Apple est explicite :

> **« Don't use a Live Activity to display ads or promotions. »**
> Live Activities help people stay informed about ongoing events and tasks, so
> it's important to display only information that's related to those events and tasks.

**Ce que ça vaut en pratique :**

| Fait | Conséquence |
|---|---|
| C'est une règle **HIG**, pas une règle des App Store Review Guidelines | Pas de rejet automatique, mais activable via 4.0 (Design) au bon vouloir du reviewer |
| Duolingo l'a fait en janvier 2026 (offre « Super » dans la Dynamic Island) | Backlash presse (MacRumors, Michael Tsai), **aucun retrait de l'App Store** |
| Duolingo a arrêté peu après | Le coût réel a été réputationnel, pas réglementaire |
| Aucune API ne permet de « taguer » une Live Activity comme promo | Les utilisateurs ne peuvent pas filtrer → d'où l'agacement |

**Décision retenue** : on l'implémente, mais dans la version défendable. La Live
Activity ne suit pas « une promo », elle suit **un événement réel, borné dans le
temps, que l'utilisateur a lui-même déclenché** : sa réservation.

### Les 6 garde-fous encodés dans le code

1. **Opt-in explicite** — la Live Activity ne démarre que sur tap de « Reserve mine »
   (`PromoGiftCard`). Jamais au lancement, jamais en silence.
2. **Vraie échéance** — 8 h persistées à la réservation. Rouvrir l'app **ne
   prolonge pas** le compteur (`promo_la_expires_at`).
3. **Une seule fois par install** (`promo_la_reserved_at`). Pas de re-armement.
4. **Se termine sur achat**, et s'auto-dismisse à expiration (`staleDate`).
5. **Fermer la page = tuer la carte** — `dismiss()` appelle `end()`. Laisser la
   carte après un « non » explicite, c'est exactement le nagging visé par Apple.
6. **Feature flag distant** (`promo_live_activity`) — coupable sans release si
   App Review ou les users réagissent mal.

### Notes de soumission App Store

À coller dans « Notes for Review » :

> The Live Activity is started only by an explicit user action ("Reserve mine"),
> tracks a real 8-hour reservation window the user opted into, ends immediately
> when the user purchases or dismisses the offer, and can be shown at most once
> per install.

---

## 2. Ce qui est livré

### iOS (Swift)

| Fichier | Cible | Rôle |
|---|---|---|
| `ios/FaithLockWidget/PromoOfferAttributes.swift` | **Runner + FaithLockWidgetExtension** | Contrat `ActivityAttributes` partagé |
| `ios/FaithLockWidget/PromoOfferLiveActivity.swift` | FaithLockWidgetExtension | UI Lock Screen / Centre de notifs + Dynamic Island (compact, expanded, minimal) |
| `ios/Runner/LiveActivityBridge.swift` | Runner | MethodChannel `faithlock/live_activity` → ActivityKit |
| `ios/Runner/AppDelegate.swift` | — | Enregistre le bridge |
| `ios/Runner/Info.plist` | — | `NSSupportsLiveActivities = true` |

`NSSupportsLiveActivitiesFrequentUpdates` est **volontairement absent** : le
compteur est rendu par le système (`Text(timerInterval:)`), aucune mise à jour
push n'est nécessaire. L'activer inviterait un throttling de budget pour rien.

### Flutter (Dart)

| Fichier | Rôle |
|---|---|
| `lib/services/live_activity/promo_live_activity_service.dart` | Éligibilité, variantes de copy, start/restore/end, analytics |
| `lib/features/paywall/controllers/promo_offer_controller.dart` | Offering RevenueCat, countdown, achat, restore |
| `lib/features/paywall/screens/cozy_promo_offer_screen.dart` | Page d'offre (design cozy) |
| `lib/features/paywall/widgets/promo_gift_card.dart` | Point d'entrée in-app (le tap qui réserve) |
| `lib/app_routes.dart` | Route `/promo-offer` |
| `lib/services/deep_link_service.dart` | `faithlock://promo?src=live_activity` |
| `lib/main.dart` | **DeepLinkService réactivé** + `restoreIfNeeded()` |

⚠️ `DeepLinkService.initialize()` était **commenté** dans `main.dart`. Il est
réactivé : sans lui, ni le tap sur la Live Activity ni les liens de notification
prière/unlock ne routent nulle part. À surveiller au premier run — `uni_links`
0.5.1 est déprécié (remplaçant : `app_links`, déjà présent dans les pods).

---

## 3. Le flux

```
Home cozy
  └─ PromoGiftCard  « A small gift, just for you · Reserve it »
        │ tap  ← LE consentement explicite
        ▼
   reserveOffer()
        ├─ persiste expiresAt = now + 8h   (une seule fois par install)
        ├─ variante ≠ control → Activity.request(...)
        └─ navigue vers /promo-offer

   ┌──────────────── pendant 8 h ─────────────────┐
   │  Lock Screen / Centre de notifications :      │
   │   🎁  A small gift, just for you              │
   │       Your first week for $1                  │
   │       Yours for 07:14:02        [ Unwrap ]    │
   │                                               │
   │  Dynamic Island (compact) :   🎁    07:14     │
   │  Dynamic Island (expanded) :  🎁 $1 for 7 days│
   │                               07:14 left      │
   │                               [ Unwrap ]      │
   └───────────────────────────────────────────────┘
        │ tap
        ▼
   faithlock://promo?src=live_activity&offer=...&variant=...
        ▼
   CozyPromoOfferScreen  →  achat  →  end()
```

---

## 3 bis. La page d'offre, ordonnée par pouvoir de conversion

Refonte du 2026-08-16. Ordre d'écran, du plus persuasif au moins :

1. **Prix** en héros (68pt, w800) — seul argument qui décide vraiment
2. **Échéance** — pill terracotta, virant au rouge et pulsant sous 10 min
3. **Bénéfices** — 3 lignes, apparition décalée
4. **CTA** à la première personne (« Unwrap my gift » / « Start my free trial »)
5. **Renouvellement** — *sous* le bouton, complet et lisible avant tout débit,
   mais plus en travers du chemin de décision (il était au-dessus)

La carte qui enfermait le prix a été supprimée : elle mettait le prix et la
mention de renouvellement à égalité visuelle.

**Champs de copy séparés** (une seule surface ≠ un seul texte) :

| Champ | Où | Contrainte |
|---|---|---|
| `ctaLabel` | page | première personne, long |
| `ctaShort` | Live Activity | un mot — la DI tronque |
| `priceLabel` | Live Activity | phrase : « $1 for 7 days » |
| `priceShort` | héros de la page | **token seul** : « $1 » — rendu à 68pt |

Confondre `priceLabel` et `priceShort` a produit un « $1 for 7 » tronqué à
l'écran. Le héros est en plus dans un `FittedBox(scaleDown)` : les devises
longues (« CHF 1.00 ») doivent rétrécir, jamais être coupées.

**Animations** : entrée décalée (illustration en overshoot → titre → prix →
compteur → bénéfices), pulsation du compteur uniquement sous 10 min — pour
qu'elle signifie quelque chose. Tout est coupé si `MediaQuery.disableAnimations`
est actif.

**Robustesse** : `getOfferings()` a un timeout de 10 s, et le héros affiche
toujours un prix (fallback `priceShort`) — jamais un spinner nu. Le CTA reste
désactivé tant que StoreKit n'a pas répondu, donc personne n'achète contre un
prix provisoire, et la mention de renouvellement est masquée tant qu'elle
n'aurait dit que « Then — per year ».

---

## 4. Configuration à faire (hors code)

### App Store Connect

L'offre « 1 $ la 1ʳᵉ semaine puis abonnement annuel » **n'est pas** un produit :
c'est une **offre introductive payante** posée sur le produit **annuel**.

1. Abonnement annuel → **Introductory Offer** → Create
2. Type : **Pay Up Front** · Durée : **1 week** · Prix : **1 $** (tier le plus bas)
3. Le renouvellement bascule automatiquement au prix annuel plein

> Une offre introductive n'est consommable **qu'une fois par compte Apple** — les
> anciens abonnés n'y sont pas éligibles et verront le prix plein. `introPrice`
> retombe alors proprement sur le libellé de la variante.

### RevenueCat

1. Créer l'offering **`promo_dollar_week`** (identifiant attendu par
   `PromoLiveActivityService.offeringId`)
2. Y attacher le package **annual** portant l'offre introductive
3. Si l'offering n'existe pas encore, le contrôleur retombe sur l'offering par
   défaut — la page n'est jamais un cul-de-sac

### PostHog

Flag multivarié **`promo_live_activity`** :

| Variante | Comportement |
|---|---|
| `control` | Réservation créée, **pas de Live Activity** — la baseline |
| _(flag absent)_ | Release → `control` (rien ne s'affiche tant que l'XP n'est pas allumée) · Debug → `gift`, pour pouvoir tester sur device |
| `gift` | Live Activity, copy « A small gift, just for you » |
| `value` | Live Activity, copy « Your welcome offer is ready » |

### Xcode / capabilities

- App Group `group.com.appbiz.faithlock` : déjà sur les 2 cibles ✅
- `NSSupportsLiveActivities` : ajouté ✅
- Deployment target widget : 16.0, code gardé en `@available(iOS 16.2, *)` ✅

---

## 5. Plan d'A/B test

### Test 1 — La Live Activity sert-elle à quelque chose ? (le seul qui compte d'abord)

| | |
|---|---|
| **Hypothèse** | Un compteur persistant sur l'écran verrouillé augmente le taux de conversion de l'offre réservée |
| **Bras** | `control` (pas de LA) vs `gift` (LA) |
| **Métrique primaire** | `promo_offer_purchased` / `promo_offer_reserved` |
| **Métriques secondaires** | `promo_offer_viewed` par réservation (retours multiples), délai réservation → achat |
| **Garde-fou** | Désinstalls D1-D7, et `promo_live_activity_blocked` (users qui ont coupé les LA) |

### Test 2 — Copy (à ne lancer qu'après un test 1 positif)

`gift` (émotionnel) vs `value` (utilitaire). Les deux variantes sont déjà
codées ; ne changer que la donnée, jamais le layout.

### Dimensionnement

Avec une conversion paywall d'onboarding de référence à **~1,78 %**, détecter un
effet relatif de +30 % avec 80 % de puissance demande **~10 000 réservations par
bras**. En dessous, on lit du bruit. Si le volume ne suit pas, viser un effet
plus gros (+50 %) et accepter un test plus long plutôt qu'une conclusion fausse.

### Repères marché (2026)

| Repère | Chiffre | Source |
|---|---|---|
| Paywall onboarding avec trial | **1,78 %** de conversion moyenne | Adapty |
| Hard paywall vs freemium (trial→payant J35) | **10,7 %** vs **2,1 %** | Adapty / RevenueCat |
| Ajout d'un trial 7 jours | **+38 à +52 %** de conversion payante effective | Adapty |
| Apps faisant 50+ tests paywall | **×18,7** de revenu médian vs 1 seul test | RevenueCat |
| Cadence moyenne réelle | **14,7 tests/an** (≈ 1 toutes les 3-4 semaines) | RevenueCat |
| Annuel choisi quand la remise est de 30-40 % | **59 %** des users | Adapty |
| LTV 1 an, annuel avec trial | **66,70 $** vs 49,92 $ moyenne | Adapty |

⚠️ **Aucun benchmark public n'existe sur les Live Activities promotionnelles.**
C'est une pratique trop récente et trop peu répandue (Duolingo est le cas notable,
et il l'a retirée). Les chiffres ci-dessus encadrent l'**offre**, pas le canal.
Le test 1 est donc une vraie mesure, pas une confirmation.

### Événements PostHog émis

| Événement | Quand |
|---|---|
| `promo_offer_reserved` | Tap sur « Reserve mine » (props : `variant`, `live_activity`) |
| `promo_live_activity_started` | ActivityKit a accepté |
| `promo_live_activity_blocked` | LA désactivées dans les Réglages |
| `promo_offer_viewed` | Page ouverte (props : `source`, `seconds_left`) |
| `promo_offer_cta_tapped` | Tap achat |
| `promo_offer_purchased` / `_purchase_failed` | Résultat |
| `promo_offer_dismissed` | Fermeture explicite |
| `promo_offer_expired` | Fin du compteur |

---

## 6. Contraintes ActivityKit à ne pas oublier

- **8 h** max en activité, puis **jusqu'à 12 h** dans le Centre de notifications
  avant retrait système. C'est **la raison** pour laquelle la fenêtre de
  réservation est de 8 h et non 24 h : un compteur de 24 h disparaîtrait aux
  deux tiers de sa course. La carte doit survivre au nombre qu'elle affiche.
  `restoreIfNeeded()` la relance au prochain lancement tant que la fenêtre est
  ouverte.
- L'utilisateur peut swiper la carte à tout moment — c'est voulu, ne pas la
  relancer derrière.
- Les Live Activities se désactivent par app dans Réglages → géré
  (`areActivitiesEnabled`).
- Simulateur : la Dynamic Island n'existe que sur les modèles Pro. Tester sur
  iPhone 15/16/17 Pro.

---

## 7. Ce que le test sur simulateur a validé (2026-08-16)

Simulateur iPhone 17 Pro, iOS 26.2, build debug.

| Vérifié | Résultat |
|---|---|
| Build Runner + FaithLockWidgetExtension | ✅ (le fichier d'attributs partagé compile dans les 2 cibles) |
| `DeepLinkService` réactivé | ✅ `✅ DeepLinkService initialized` |
| `restoreIfNeeded()` → décision → bridge | ✅ `🎁 restoring activity until … (gift)` |
| MethodChannel → `Activity.request` | ✅ `✅ activity started (id=D2A6A770-…)` |
| Rendu Dynamic Island (compact) | ✅ 🎁 + compteur pêche monospacé, décompte réel |
| Page d'offre cozy | ✅ rendu conforme, prix/échéance/disclosure corrects |
| Écran verrouillé / DI expanded | ❌ non capturé — verrouiller ou long-presser demande un contrôle tactile indisponible ici |

### Deux bugs trouvés **par** ce test (et corrigés)

1. **Crash natif RevenueCat.** Ouvrir la page avant `Purchases.configure` déclenche
   un `fatalError` Swift — non rattrapable côté Dart, l'app meurt. C'est atteignable
   en prod : tap sur la Live Activity à froid, ou init RevenueCat en échec.
   → `_waitForRevenueCat()` attend la configuration puis dégrade en état d'erreur.
2. **« $0.00 for 7 days ».** Le prix d'intro et la durée étaient affichés bruts et
   en dur. Sur un produit à essai gratuit, ça affichait un prix de zéro dollar et
   une durée fausse. → `introPrice` / `introPeriod` / `offerSummary` dérivent
   désormais de StoreKit (`Free for 3 days`, `Start free · 3 days`).

### Test sur device physique (iPhone 15 Pro, iOS 26.5)

⚠️ **Un build debug ne se lance pas seul sur un device** : `devicectl` répond
*« Flutter application in debug mode can only be launched from Flutter tooling »*,
et `flutter run` en Wi-Fi échoue souvent sur la découverte du Dart VM Service
(l'app reste sur le splash). D'où l'override QA :

```bash
flutter build ios --profile --dart-define=PROMO_LA_VARIANT=gift
xcrun devicectl device install app --device <UDID> build/ios/iphoneos/Runner.app
xcrun devicectl device process launch --device <UDID> --terminate-existing --console com.appbiz.faithlock
```

`PROMO_LA_VARIANT` existe parce qu'en profile/release `kDebugMode` est faux : sans
lui, la variante retombe sur `control` et rien ne s'affiche tant que le flag
PostHog n'existe pas. Vide par défaut → aucun effet sur une vraie release.

Résultat : réservation créée depuis la carte 🎁 (prefs device :
`promo_la_reserved_at`, variante `gift`, échéance +8 h), puis relance sans
nouvel événement `promo_live_activity_started` — `restoreIfNeeded()` sort sur
`isRunning`, l'activité tourne déjà. Comportement idempotent confirmé.

Lire/écrire les prefs d'un device (le tap n'est pas scriptable) :

```bash
xcrun devicectl device copy from --device <UDID> --domain-type appDataContainer \
  --domain-identifier com.appbiz.faithlock \
  --source Library/Preferences/com.appbiz.faithlock.plist --destination ./prefs.plist
```

### Comment rejouer le test

```bash
# le simulateur de test existe déjà (supprimable : xcrun simctl delete FaithLock-Test-17Pro)
xcrun simctl boot FaithLock-Test-17Pro
flutter run -d FaithLock-Test-17Pro

# semer une réservation (le tap sur la carte n'est pas scriptable) :
C=$(xcrun simctl get_app_container booted com.appbiz.faithlock data)
xcrun simctl spawn booted defaults write "$C/Library/Preferences/com.appbiz.faithlock" \
  flutter.promo_la_expires_at -string "$(date -u -v+8H '+%Y-%m-%dT%H:%M:%S.000Z')"
xcrun simctl spawn booted defaults write "$C/Library/Preferences/com.appbiz.faithlock" \
  flutter.promo_la_variant -string gift
```

⚠️ Les préférences de l'app **ne sont pas** dans le domaine `defaults` du simulateur :
`shared_preferences` écrit dans le plist du conteneur de données. Écrire dans
`defaults write com.appbiz.faithlock` ne fait rien de visible pour l'app.

---

## 8. Reste à faire

- [ ] Créer l'offre introductive (App Store Connect) + l'offering `promo_dollar_week`
- [ ] Créer le flag `promo_live_activity` dans PostHog (démarrer 100 % `control`)
- [ ] Remplacer l'emoji 🎁 par l'asset cozy (prompt dans `live-activities-plan.md` §Cas 2)
- [ ] Localiser les strings (actuellement en dur en anglais — voir `lib/core/localization/`)
- [ ] Vérifier le premier run avec `DeepLinkService` réactivé
- [ ] QA sur device physique Pro : Lock Screen, Centre de notifs, DI compact/expanded/minimal
