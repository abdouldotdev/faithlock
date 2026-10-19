# Gamification — plan moment-par-moment (Cozy)

> Comment surface la gamification dans FaithLock en s'appuyant sur la
> plomberie déjà modélisée (`UserStats`, 12 `BadgeId`, `StreakFreezeState`)
> et le langage Cozy (cream / terracotta / chunky outlines / shadowHard).

---

## Principe directeur

C'est une app de foi, pas Duolingo. Trois garde-fous :

- **Consistance, pas score.** Pas de classement social, pas de "tu perds des XP". Le langage = "tu as nourri ta journée", pas "tu as gagné 10 pts".
- **Grâce intégrée.** Le streak freeze hebdo existe déjà — utilise-le visuellement comme une **bénédiction**, pas un consommable. Une icône feuille / colombe, pas un cube de glace.
- **Pas de slot-machine.** Pas d'animations sparkles, pas de loot boxes, pas de "spin daily". Le Cozy déjà ne s'y prête pas — chunky, calme, chaleureux.

---

## Ce qui existe déjà (modèles à habiller)

- `UserStats` — `currentStreak`, `longestStreak`, `totalVersesRead`, `screenTimeReducedMinutes`, `successfulUnlocks`, `failedAttempts`, `versesByCategory`, `averageQuizScore`
- 12 badges via `BadgeId` :
  - Streak — `streakStarter`, `streakWarrior`, `streakDevoted`, `streakLegendary`
  - Verses — `verseExplorer`, `verseScholar`, `verseMaster`
  - Session — `firstPrayer`, `perfectScore`
  - Special — `nightOwl`, `earlyBird`, `frozenSolid`
- `StreakFreezeState` — 1 freeze/sem gratuit, 3/sem premium, pas de double freeze

Il manque surtout la **surface UI** dans le langage Cozy et le **timing** :
quand on récompense, quand on rappelle, quand on célèbre.

---

## 1) Streak — la pièce centrale, partout

Composant réutilisable `CozyStreakPill` :

```
╭─────────────────╮
│ 🔥  12 day streak │   ← CozyColors.surface, ink border 2.5px,
╰─────────────────╯       shadowHard, HugeIcons.strokeRoundedFire
                          (terracotta), nombre en CozyText.heading
```

**Où la placer** :

- **Home/Today** — hero (gros, 56px de haut, terracotta border quand 7+ jours)
- **Bible header** & **Prayer header** — version mini (icône + chiffre seul, 28px), top-right à côté du titre
- **Unlock screen** (après un block réussi) — "Day 12 protected 🔥" pendant 2s puis fade
- **Verse library / Reflection note** — petit indicateur que cette action **compte** pour aujourd'hui (checkmark vert si déjà fait, contour pulsant si pas encore)

---

## 2) Streak freeze — révèle-le au bon moment

`StreakFreezeState.canUseFreeze` existe mais est mort si caché dans Settings.

- **Moment 1 — Onboarding fin** : "We give you a grace day each week — life happens 🤍" (1 carte, swipe pour continuer)
- **Moment 2 — Push de soir J+1 sans activité** : "Use your grace day for yesterday?" → un seul tap pour activer (modal cozy, pas un écran complet)
- **Moment 3 — Profile** : un compteur passif `🍃 2 grace days this week` (CozyIconChip sage)
- **Moment 4 — Paywall** : argument premium concret → "3 grace days/week instead of 1". Plus convaincant que des bullet points abstraits.

---

## 3) Badges — vitrine + révélation

**Vitrine permanente (Profile tab)** — grille 3-colonnes de `CozyAvatar` (rond, ink border, shadowHard, emoji du badge centré). Verrouillés = `inkMuted` + opacity 0.4 + HugeIcons.lock en overlay coin bas-droit.

**Révélation (toast modal)** — au moment où le badge est earned :

```
       ╭──────╮
       │  🏆  │   ← CozyAvatar 80px, scale-in 0.6→1.1→1.0 (spring),
       ╰──────╯     shadowHard apparaît en dernier (le "thud")
   STREAK WARRIOR
   7 days in a row
```

Pas de confettis. Juste le "thud" du shadowHard qui tombe + un haptic medium. **Cozy = chunky, pas glitter.**

---

## 4) Bible — progression de livre, vraiment visible

`cozy_book_detail_screen` a déjà les chips de chapitre (1, 2, 3, 4). Ajouts :

- **Chapitre lu** : le chip devient **sage** (pastel vert) avec un petit ✓ en HugeIcon dans le coin. Le `selected` reste terracotta. Donc 3 états : default / read / selected.
- **Hero du livre** (en haut, sous le titre "Malachi") : barre de progression cozy → `4/4 chapters · 100%` avec barre chunky outlined remplie terracotta. Quand 100% → **stamp "Completed"** apparaît en overlay sur la card du livre dans la liste.
- **Bible home** (`cozy_bible_home_screen`) : sur chaque book card, un mini ring de progression (CozyAvatar custom avec arc) — donne envie de finir les livres courts (Jude, Philémon, etc. — quick wins).

---

## 5) Stats dashboard — "ce que tu as gagné", pas "ce que tu as fait"

Reformule en `CozyStatCard` :

```
╭───────────╮  ╭───────────╮
│    🕐     │  │    📖     │
│   8h 42m  │  │    127    │
│  reclaimed│  │ verses ✕  │   ← "verses" et "fed your soul"
╰───────────╯  ╰───────────╯
```

Le ratio **temps écran économisé** est ton meilleur argument viscéral. Mets-le en hero card, pas en stat parmi d'autres.

---

## Idées nouvelles (cohérentes avec le système)

### 6) "Daily quest" — UNE chose par jour

Pas 5 trucs. **Une carte sur Home** :

```
╭───────────────────────────────╮
│  ✦ TODAY                       │   ← CozyText.label, inkMuted
│  Read Psalm 23                 │   ← CozyText.heading
│  ╭─ Start ─╮                   │   ← mini CozyButton primary
│  ╰────────╯                    │
╰───────────────────────────────╯
```

Quand terminée → la carte se transforme en stamp "Done ✓" + un soft haptic.

> **Important** : le **streak n'incrémente que si la quest est faite** (ou un équivalent : prière ouverte, ou chapitre lu). Sinon "streak" devient juste "j'ai ouvert l'app" et perd son sens.

### 7) "Faith garden" — accumulation visuelle au lieu de chiffres

Plutôt qu'un compteur XP froid, chaque action **fait pousser quelque chose** sur une page dédiée (ou en hero de Profile) :

- chapitre lu = +1 fleur dans le jardin (HugeIcons stroke : `strokeRoundedFlower`, `strokeRoundedLeaf`, `strokeRoundedPlant02`)
- prière terminée = arrose le jardin (visuel : 1 goutte)
- block réussi = pousse un peu plus

Le jardin = grid 5×7 avec un état par jour, fond cream, icons en pastel sage / peach / primaryLight. Très **cozy**, très **non-numérique**, et donne un sens au mot "spiritual growth" répété dans le paywall.

> Bonus : c'est aussi le visuel parfait pour le screenshot ASO ("Watch your faith grow").

### 8) Lock challenge — récompense le bon côté

`lock_challenge_screen` existe. Quand le user **résiste** (ne déverrouille pas pendant la prière) :

- mini stamp à la fin : "Stayed focused 🕊"
- contribue au badge `perfectScore`

Quand il **craque** : zéro shaming. Verset doux sur cream background + "Try again tomorrow — every day is new."

### 9) Niveaux ? — Oui mais doux

Pas "Level 42". Plutôt des **paliers nommés** alignés avec le voyage spirituel :

- **Seeker** (0–7 jours)
- **Disciple** (8–30)
- **Devoted** (31–90)
- **Steadfast** (91+)

Affichés discrètement dans Profile en `CozyText.label` sous le nom user, jamais dans la nav. **Pas de XP bar agressive** — la progression est implicite via la streak et le jardin.

---

## Carte moment-par-moment (TL;DR)

| Moment | Surface | Mécanique |
|---|---|---|
| App ouverture (premier de la journée) | Home hero | Streak pill + daily quest card |
| Quest terminée | In-place transform | Stamp "Done ✓" + haptic medium |
| Chapitre lu | Reading mode close | Mini toast streak ping + fleur dans le jardin |
| Block réussi (unlock évité) | Relock in progress | "+1 focus seed" subtle stamp |
| Badge unlocked | Plein écran modal (interrompt rarement) | CozyAvatar scale-in + shadow drop |
| Streak en danger (J+1 sans activité) | Push notif soir | "Use your grace day?" → 1 tap |
| Streak cassée | Home la fois suivante | "Welcome back. Every day is new." (zéro guilt) |
| Premium upsell | Paywall existant | Ajoute "3 grace days/week" comme tier benefit |

---

## Anti-patterns à éviter

- ❌ Leaderboards / partage public de streak (compétition spirituelle = anti-pattern)
- ❌ XP visibles sur des actions de prière (transactionnaliser la foi)
- ❌ "Streak frozen for 1 day" comme un crash dramatique en plein écran
- ❌ Confetti / animations Lottie tape-à-l'œil → casse le Cozy
- ❌ Cumul de quêtes ("complete 5 tasks today") — focus = UNE chose/jour

---

## Ordre d'implémentation suggéré

1. **`CozyStreakPill`** — composant réutilisable, 3 tailles (hero / inline / mini). Le plus haut levier : visible partout.
2. **Daily Quest card** sur Home + transformation "Done" stamp. Donne du sens au streak.
3. **Faith Garden** sur Profile — le plus différenciant visuellement (et asset ASO).
4. **Badge unlock modal** + grille badges sur Profile — surface l'existant.
5. **Streak freeze surfacing** — onboarding teaser + push J+1 + Profile counter + paywall benefit.
6. **Book progression** — chips 3-states + completion stamp sur book cards.
7. **Lock challenge stamp** — "Stayed focused 🕊" + tie au badge `perfectScore`.
8. **Paliers nommés** (Seeker → Steadfast) en label sous le nom Profile.
