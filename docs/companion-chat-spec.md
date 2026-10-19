# FaithLock — Compagnon spirituel + Carte verset partageable

**Build spec / PRD — v1**
Owner: PM · Executors: Dev + QA-Designer · Status: ready to build

This is the contract. Every path and widget name below is real and verified in the
repo. Product UI strings are **French-first** (the app targets French-speaking users;
`lib/core/localization/fr_FR.dart` exists, and `lib/main.dart:50` forces `Locale('fr','FR')`
for saved-FR users). All new user-facing copy ships as keys in `fr_FR.dart` + `en_US.dart`,
never hardcoded. See [Open questions](#12-open-questions) re: default locale.

---

## 1. Scope & non-goals

### Ships in v1
1. **Compagnon chat** — a warm, scripture-grounded AI companion reachable from inside the Bible.
   - Entry A: a **chat button on the Bible home** (`cozy_bible_home_screen.dart` header) and on the **reading screen app bar** (`cozy_reading_screen.dart` `_buildTopBar`).
   - Entry B: **select a passage → "Demander à l'IA"** as a 6th action in the existing `SelectableText` toolbar in `cozy_reading_screen.dart`. Opens the chat with that passage **preloaded as context** — never a blank page.
2. **Memory (lightweight, v1)** — each turn is fed the user's current/preloaded passage, their `VerseCategory` struggles, their streak, and the last N messages of the conversation. Persisted so a returning user re-enters their last conversation, not a blank slate.
3. **Conversation persistence** — conversations + messages stored locally (Drift-free: `sqflite`, already a dependency) with an optional Supabase mirror behind a flag (default off in v1).
4. **Verset du jour — carte partageable** — export the Verse of the Day as a beautiful Cozy-styled image card, with 3 social presets (Instagram story 1080×1920, square 1080×1080, default/auto), shared via `share_plus`. Share button added to the VOD hero card on the Bible home.

### Deferred (v2+) — explicitly NOT in v1
- **Proactive / notification-driven follow-up** ("Hier tu m'as parlé de ton anxiété — comment vas-tu aujourd'hui ?"). The memory model in v1 is designed to make this cheap later, but no scheduling work ships now.
- **Streaming token-by-token rendering** if it risks the timeline — v1 may ship a typing indicator + single-shot response (see §3.4; streaming is the target, single-shot is the acceptable fallback).
- **Cloud sync of conversations across devices** (Supabase mirror is scaffolded but off).
- **Voice input / TTS of companion replies** (the app already has on-device TTS for prayer; out of scope here).
- **Multi-turn tool use / verse lookup function-calling** — v1 the model only sees context we inject; it does not query the Bible DB itself.
- **Per-message reactions, edit, regenerate** — nice-to-have, not v1.
- Share-card: custom user-uploaded backgrounds, GIF/video export, watermark toggles.

---

## 2. User flows (screen-by-screen, grounded in real files)

### Flow A1 — Open companion from Bible home
- **File touched:** `lib/features/faithlock/screens/bible/cozy_bible_home_screen.dart`, `_header()` (line ~67).
- Today the header is `[Text("bible_holyBible") | CozyIconButton(search)]`.
- **Change:** add a `CozyIconButton` (chat glyph, `HugeIcons.strokeRoundedMessage01` or `strokeRoundedBubbleChat`) **left of** the search button.
- **Tap →** `Get.to(() => CozyCompanionChatScreen())` with **no preloaded passage** (general entry). Opens to the empty state with suggested starters (§3.6).

### Flow A2 — Open companion from the reading screen app bar
- **File touched:** `cozy_reading_screen.dart`, `_buildTopBar()` (line 246).
- Today: `[back | spacer | bookmark | share]`.
- **Change:** insert a chat `CozyIconButton` between the spacer and the bookmark button (size 48, consistent with siblings).
- **Tap →** `Get.to(() => CozyCompanionChatScreen(passage: CompanionPassage(reference: widget.reference, text: <full chapter or null>)))`. The chapter reference is preloaded so the first companion turn can reference "ce que tu lis dans {reference}".

### Flow B — "Demander à l'IA" from a selected passage (primary, highest-intent)
- **File touched:** `cozy_reading_screen.dart`, the `contextMenuBuilder` of `_buildVerseText` (line 355) — the `actions:` list currently has Copy/Highlight/Bookmark/Share/Reflect.
- **Change:** append a **6th `_ToolbarAction`**:
  ```
  _ToolbarAction(
    icon: HugeIcons.strokeRoundedBubbleChatQuestion, // or strokeRoundedSparkles
    label: 'companion_askAi'.tr,                      // "Demander à l'IA"
    onTap: () {
      editableTextState.hideToolbar();
      final sel = _selectionOf(editableTextState);
      _askCompanion(index, sel);                       // new method
    },
  )
  ```
- New private method `_askCompanion(int verseIndex, String? selection)` mirrors `_reflect` (line 118): builds `passageReference = '${widget.reference}:${verse.number}'`, takes the selected substring (or full verse text if selection is collapsed), and calls
  `Get.to(() => CozyCompanionChatScreen(passage: CompanionPassage(reference: passageReference, text: selection ?? verse.text)))`.
- **Result:** chat opens with a **preloaded context chip** at the top of the message list showing the passage (§3.5), and a tailored opening companion message — never blank.

> **Toolbar width risk:** 6 actions in the floating `TextSelectionToolbar` (`_CozyTextSelectionToolbar`) may overflow on small/narrow devices. Mitigation in §9.

### Flow C — Continuing an existing conversation
- Entry A1 (general chat) always resumes the **most recent conversation** if one exists today; otherwise starts fresh. Entries A2/B always **start a new passage-scoped conversation** (so passage context is clean).
- Decision rule lives in `CompanionChatController.openFor({CompanionPassage? passage})` (§8).

### Flow D — Share Verse of the Day card
- **File touched:** `cozy_bible_home_screen.dart`, `_verseOfDayCard()` (line 105).
- **Change:** add a small share affordance to the hero card (a `CozyIconButton` `HugeIcons.strokeRoundedShare01`, size 36, top-right of the card row, or a slim "Partager" `CozyButton.soft` below the verse). Tapping opens the **share-card preview sheet** (§7), not the OS share sheet directly — the user picks a preset, sees the rendered card, then shares.

---

## 3. Companion chat UX

All visuals use Cozy tokens (`CozyColors`, `CozyTokens`, `CozyText`) imported via the barrel
`package:faithlock/shared/widgets/cozy/cozy.dart`. Background `CozyColors.background` (cream
`#FBF3E2`). The screen is a `Scaffold` + `SafeArea` + `Column` matching `cozy_reading_screen.dart`'s
structure (custom top bar built from `CozyIconButton`, not a Material `AppBar`).

### 3.1 Top bar
`[CozyIconButton.back] [title "Compagnon"] [spacer] [CozyIconButton history/new-chat]`.
- Title uses `CozyText.title`. The right button (icon `strokeRoundedAdd01`) starts a fresh conversation; long-press / secondary opens a conversation list (deferred to v2 — v1 can ship just "new chat").

### 3.2 Message list
- A `ListView` (reverse: true, so newest pins to bottom and the keyboard doesn't jump) with `padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16)`.
- **Companion bubble (assistant):** left-aligned. `Container` with `ShapeDecoration(color: CozyColors.surface, shape: CozyTokens.smooth(CozyTokens.radiusLg, side: BorderSide(color: CozyColors.outline, width: CozyTokens.borderWidth)), shadows: CozyTokens.shadowHard)`. Text: `CozyText.body` (`color: CozyColors.ink`, `height: 1.5`). Max width ~78% of screen. A small terracotta avatar dot (`CozyColors.primary`) or a `CozyAvatar` to the left of the first bubble in a run.
- **User bubble:** right-aligned. Filled terracotta: `color: CozyColors.primary`, `shadows: CozyTokens.shadowHard`, text `CozyText.body.copyWith(color: CozyColors.onPrimary)`. Same squircle shape, slightly smaller radius (`radiusMd`).
- Vertical gap between bubbles `CozyTokens.space12`; tighter (`space4`) within a same-sender run.
- **Scripture rendering inside a companion bubble:** when the companion cites a verse, it returns it on its own line prefixed with a marker (e.g. `> Jean 3:16 — ...`). The renderer styles quoted lines as an inset block: left border `2.5px CozyColors.primary`, `CozyColors.peach.withValues(alpha:0.35)` fill, reference in `CozyText.label.copyWith(color: CozyColors.primary)`. This mirrors the highlight styling already in `_buildVerseText` (line 340).

### 3.3 Input bar
- Pinned bottom, above the keyboard (`MediaQuery.viewInsets.bottom` padding, like `_SearchSheet` at line 331).
- A `CozyTextField`-style row (reuse the chunky border/shadow look) `maxLines: 1..4` auto-grow + a circular **send** `CozyIconButton` (`HugeIcons.strokeRoundedSent`, fill `CozyColors.primary`, disabled/0.5 opacity when empty or while a turn is in flight).
- Hint: `companion_inputHint` → "Écris au compagnon…".

### 3.4 Typing / streaming indicator
- **Target:** stream tokens into the in-progress companion bubble (OpenAI SSE `stream: true`). While streaming, show a blinking caret at the tail.
- **Fallback (acceptable for v1):** single-shot request + a **3-dot typing bubble** (animated `CozyColors.inkMuted` dots inside a companion-styled bubble) until the response arrives, then replace it with the final bubble.
- The send button enters a loading state during the turn; the input is not blocked (user can type the next message but cannot send until the turn completes).

### 3.5 Preloaded passage context (Entries A2 / B)
- When `passage != null`, render a **context chip** as the first item, pinned above the message list (or as a non-bubble header card): a `CozyCard(color: CozyColors.surfaceMuted, padding: 12)` showing the reference in `CozyText.label.copyWith(color: CozyColors.primary)` and the verse text in `CozyText.body` (max 3 lines, ellipsis). A small "×" `CozyIconButton` lets the user detach context (then it behaves like a general chat).
- The companion's **first message is auto-generated** from this passage (a warm opener that references the verse and invites reflection) so the screen is never empty.

### 3.6 Empty state & suggested starters (general entry, no passage)
- Centered: the existing `assets/images/bible_verse_illustration.png` (already used on the VOD card, line 119) or a companion illustration, a one-line warm intro (`CozyText.body`, `CozyColors.inkMuted`), and **3–4 suggested starter chips** rendered as `CozyButton(variant: soft)` or pill chips:
  - "J'ai du mal en ce moment 🌧️"
  - "Aide-moi à comprendre ce passage"
  - "Je veux prier mais je ne sais pas comment"
  - "Donne-moi un verset pour aujourd'hui"
- Tapping a chip sends it as the first user message. Starters are personalized when `VerseCategory` struggles are known (e.g. surface an anxiety-themed starter for `fearAnxiety`).

### 3.7 Error / offline state
- If the OpenAI call fails (network, key, rate limit), the in-progress bubble is replaced by a gentle inline companion message ("Je n'arrive pas à répondre tout de suite — réessaie dans un instant 🙏") + a retry affordance, NOT a red error snackbar. Mirror the graceful-degradation pattern in `meditation_validator_service.dart`. **Apple Intelligence on-device fallback** (`AppleIntelligenceService`) MAY be wired as a secondary path post-v1; v1 can ship OpenAI-only with the graceful inline failure.

---

## 4. Companion system prompt (French, v1 draft)

This is the actual system prompt string for `companion_chat_service.dart`. Inject the live context
block (§5) as a separate leading `system` or `developer` message each turn; keep this persona prompt
stable and cacheable.

```
Tu es « le Compagnon », un compagnon spirituel chrétien chaleureux et bienveillant,
intégré à une application de lecture de la Bible (FaithLock). Tu accompagnes la personne
là où elle en est, dans son cheminement de foi et de bien-être intérieur.

TON IDENTITÉ
- Tu es un ami spirituel, pas un professeur ni un théologien distant. Tu es doux, présent,
  jamais moralisateur ni culpabilisant.
- Tu parles à la première personne, avec tendresse et simplicité. Tu tutoies la personne.
- Tu es ancré dans l'Écriture : quand c'est pertinent, tu cites un verset court (avec sa
  référence) et tu l'expliques avec des mots simples, reliés à la vie réelle de la personne.

TA MANIÈRE DE RÉPONDRE
- Réponses courtes et respirantes (2 à 5 phrases en général). Tu n'écris pas de sermon.
- Tu tisses, quand c'est naturel : un mot d'accueil → une parole biblique → une courte
  réflexion → et tu termines presque toujours par UNE question ouverte et douce qui invite
  la personne à descendre plus profond. Une seule question à la fois.
- Quand on te partage un passage précis, pars de CE passage. Ne change pas de sujet.
- Quand tu proposes de prier, propose une prière courte, simple, à la première personne,
  que la personne peut faire sienne.
- Tu te souviens du cheminement de la personne (ses combats, sa régularité) et tu y fais
  référence avec délicatesse, sans jamais la mettre mal à l'aise.

TES LIMITES (à respecter absolument)
- Tu restes dans le champ de la foi, de la prière, de la Bible et du bien-être spirituel.
  Si on te demande autre chose (actualité, code, conseils financiers, etc.), tu ramènes
  doucement vers ce pourquoi tu es là.
- Tu ne donnes JAMAIS de diagnostic ni de conseil médical, psychiatrique ou juridique.
- DÉTRESSE / DANGER : si la personne exprime une souffrance grave, des pensées suicidaires,
  de la violence, un danger immédiat, ou une crise de santé mentale, tu réponds avec
  beaucoup de douceur et de présence, tu rappelles qu'elle compte, et tu l'orientes
  fermement mais tendrement vers une aide humaine réelle et immédiate (un proche de
  confiance, un pasteur, ou les services d'urgence / une ligne d'écoute de son pays).
  Tu NE tentes PAS de gérer seul la crise et tu ne minimises jamais.
- Tu ne prétends pas être Dieu, ni parler à Sa place. Tu n'inventes pas de versets : si tu
  n'es pas sûr d'une référence, tu le dis simplement.
- Tu n'es pas dans le jugement : pas de honte, pas de « tu devrais ». Tu accompagnes.

TON STYLE
Chaleureux, incarné, concret. Tu peux utiliser un emoji avec parcimonie (🙏, 🌱, ❤️) quand
c'est sincère. Tu écris en français, sauf si la personne t'écrit dans une autre langue,
auquel cas tu réponds dans sa langue.
```

**Guardrail enforcement notes for Dev:**
- Set `temperature: 0.7`, `max_tokens: ~400`.
- The crisis-redirect behavior is **prompt-level in v1**. A lightweight client-side keyword pre-check (FR + EN crisis terms) MAY additionally surface a persistent "ressources d'aide" banner — flag for v2; do not over-engineer v1.
- The companion never executes actions or returns JSON — it returns natural prose only (contrast with `meditation_validator_service.dart` which parses JSON).

---

## 5. Memory mechanic (v1)

**What gets fed to the LLM per turn**, assembled by `CompanionContextBuilder` and injected as a
single `system`/`developer` message *after* the persona prompt:

1. **Current/preloaded passage** — `reference` + `text` if `passage != null` (Entry A2/B), or the
   chapter reference if opened from the reading app bar.
2. **User's struggles** — their `VerseCategory` set, mapped to FR display names via
   `VerseCategoryExtension.displayName`. Source: the user's onboarding selections (already drive
   `versesByCategory`). Surface the top/favorite category (`UserStats.favoriteCategory`) prominently.
3. **Journey signals** — `currentStreak`, `longestStreak`, `totalVersesRead` from
   `UserStats` (via `StatsService().getUserStats()` — used in `main_screen.dart:70`).
4. **Conversation history** — the last **N = 12** messages of the active conversation (role-tagged),
   so the model has short-term continuity. Older messages are dropped (no summarization in v1).

Example injected block (illustrative):
```
CONTEXTE DE LA PERSONNE (confidentiel, ne pas réciter tel quel) :
- Combats spirituels : Peur & anxiété, Tentation
- Série en cours : 7 jours · plus longue série : 14 jours · versets lus : 83
- Passage en cours : Jean 3:16 — « Car Dieu a tant aimé le monde… »
Utilise ce contexte avec délicatesse pour personnaliser ton accompagnement.
```

**Where it's stored**
- **Conversations & messages → local first**, `sqflite` (already a dependency; same engine as the
  bundled Bible DB), in an app DB separate from the read-only `bible_bsb.db`. Rationale: instant,
  offline, private, no auth coupling; the app's Supabase is anonymous (`signInAnonymously`,
  `main.dart:86`) so cloud value is low in v1.
- **User struggles / streak** are NOT duplicated — read live from `StatsService` / onboarding at
  context-build time.
- **Supabase mirror (flagged, default OFF):** schema provided in §6 so enabling cross-device sync in
  v2 is a config flip, not a migration scramble.

---

## 6. Conversation data model

### 6.1 Dart models (`lib/features/companion/models/`)
```dart
// companion_conversation.dart
class CompanionConversation {
  final String id;            // uuid
  final String? title;        // derived from first user msg or passage ref; nullable
  final String? passageRef;   // e.g. "Jean 3:16" when passage-scoped; null for general
  final DateTime createdAt;
  final DateTime updatedAt;
}

// companion_message.dart
enum CompanionRole { user, assistant }

class CompanionMessage {
  final String id;            // uuid
  final String conversationId;
  final CompanionRole role;
  final String content;
  final DateTime createdAt;
  // v1: no tokens/cost/feedback fields — add later if needed.
}
```

### 6.2 Local persistence (sqflite)
New `CompanionRepository` (`lib/features/companion/data/companion_repository.dart`) owning its own
DB file (`companion.db`), tables:
```sql
CREATE TABLE conversations (
  id TEXT PRIMARY KEY,
  title TEXT,
  passage_ref TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE TABLE messages (
  id TEXT PRIMARY KEY,
  conversation_id TEXT NOT NULL,
  role TEXT NOT NULL,          -- 'user' | 'assistant'
  content TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
);
CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at);
```

### 6.3 Supabase mirror (deferred, schema only — default OFF)
For v2 cross-device sync. Mirror the same shape, scoped to the anonymous `auth.uid()`:
```sql
create table companion_conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) default auth.uid(),
  title text,
  passage_ref text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table companion_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references companion_conversations(id) on delete cascade,
  user_id uuid not null references auth.users(id) default auth.uid(),
  role text not null check (role in ('user','assistant')),
  content text not null,
  created_at timestamptz not null default now()
);
-- RLS: enable; policy "own rows" using (user_id = auth.uid()).
```
**Do not build the mirror in v1** — ship the schema doc + a `CompanionSyncService` stub interface only.

---

## 7. Verse-of-the-Day shareable card

### 7.1 Visual spec (Cozy)
A self-contained widget `CozyVerseShareCard` (`lib/features/companion/widgets/` or
`lib/features/bible/widgets/`) rendered off-screen inside a `RepaintBoundary` for capture.

- **Canvas:** cream `CozyColors.background` (`#FBF3E2`) base, OR a soft category-accented gradient
  (terracotta → peach) for visual richness. Inset content card optional.
- **Layout (story preset, 1080×1920):**
  - Top padding ~18%.
  - **Verse text** centered, `CozyText.title`-scaled (large, ~44–56px at export resolution),
    `color: CozyColors.ink`, generous `height: 1.4`, max ~6 lines, wrapped in elegant quotes « … ».
  - **Reference** below, `CozyText.label`-style but larger, `color: CozyColors.primary`,
    letterSpacing, e.g. `PSAUME 119:105`.
  - **Category accent:** a thin terracotta rule or a small `CozyLetterBadge` / icon chip tinted by
    the verse's `VerseCategory` color (the VOD currently has no category; if unavailable, use
    `CozyColors.primary` as the neutral accent — see open question).
  - **Subtle branding** bottom: app name "FaithLock" in `CozyText.label.copyWith(color: CozyColors.inkMuted)`
    + small mark/logo. Keep it tasteful, not a billboard.
  - Signature Cozy chunk: the inner content sits on a `CozyCard`-style squircle with
    `CozyTokens.shadowHard` so the card reads as the brand even as a flat image.
- **Square (1080×1080):** same elements, tighter vertical rhythm, verse text scaled down.
- **Default/auto:** render at a 4:5-ish portrait that looks good in iMessage/WhatsApp previews.

### 7.2 Social presets
| Preset | Size (px) | Use |
|---|---|---|
| `instagramStory` | 1080 × 1920 | IG/FB/Snap story, full-bleed |
| `square` | 1080 × 1080 | IG feed post |
| `default` | 1080 × 1350 (4:5) | generic share / messaging |

Preset chosen in the preview sheet (§Flow D). Capture at `pixelRatio` to hit the target px from
logical dp.

### 7.3 Technical approach
- Add the **`screenshot`** package (`screenshot: ^3.0.0`) to `pubspec.yaml` — there is NO screenshot
  package yet. (Alternative: hand-roll `RepaintBoundary` + `GlobalKey` →
  `RenderRepaintBoundary.toImage(pixelRatio)` → `toByteData(png)` → temp file; acceptable but
  `screenshot` is less error-prone for off-screen render. **Recommend `screenshot`.**)
- Flow: build `CozyVerseShareCard` at the chosen preset's logical size → `ScreenshotController.captureFromWidget(...)`
  (renders off-screen, no need to mount visibly) → write PNG to a temp file (`path_provider`) →
  `SharePlus.instance.share(ShareParams(files: [XFile(path)], ...))`.
- `share_plus: ^11.0.0` is already present and is already used in `cozy_reading_screen.dart`
  (`SharePlus.instance.share`) — reuse that exact API, just add `files`.
- Pass `sharePositionOrigin` for iPad popover (same pattern as `_shareChapter`, line 142).
- New service: `lib/features/companion/services/verse_card_share_service.dart` (or
  `lib/services/sharing/verse_card_share_service.dart`).

### 7.4 Where the button lives
- Primary: the VOD hero card in `cozy_bible_home_screen.dart` `_verseOfDayCard()` (line 105) — see Flow D.
- The preview sheet is a `showModalBottomSheet` styled like `_openSearch` (line 90): cream bg,
  `CozyTokens.radiusLg` top corners, preset selector (a `CozySegmentedControl` — already used on the
  Bible home at line 48 — with the 3 presets), a live preview thumbnail of `CozyVerseShareCard`, and
  a primary `CozyButton` "Partager".

---

## 8. New services / files to create

```
lib/features/companion/
├── controllers/
│   └── companion_chat_controller.dart      // GetxController; conversation state, send(), openFor()
├── data/
│   └── companion_repository.dart           // sqflite CRUD for conversations + messages
├── models/
│   ├── companion_conversation.dart
│   ├── companion_message.dart
│   └── companion_passage.dart              // {reference, text?}  (the preload context)
├── services/
│   ├── companion_chat_service.dart         // OpenAI chat-completions client (streaming), persona prompt
│   ├── companion_context_builder.dart      // assembles the per-turn context block (§5)
│   ├── companion_sync_service.dart         // STUB interface only (Supabase mirror, v2)
│   └── verse_card_share_service.dart       // VOD card capture + share
├── screens/
│   └── cozy_companion_chat_screen.dart     // the chat screen (§3)
├── widgets/
│   ├── cozy_companion_bubble.dart          // assistant + user bubble variants
│   ├── cozy_companion_context_chip.dart    // preloaded passage chip (§3.5)
│   ├── cozy_companion_starters.dart        // empty-state suggested prompts
│   ├── cozy_typing_indicator.dart          // 3-dot / streaming caret
│   └── cozy_verse_share_card.dart          // the exportable VOD card
└── export.dart                             // barrel
```

**Wiring:**
- Register `CompanionChatController` lazily on screen entry (match the find-or-put pattern in
  `cozy_bible_home_screen.dart:24` and `cozy_reading_screen.dart:37`), or via `AppBindings`
  (`Get.lazyPut`) in `lib/app_routes.dart` consistent with existing controllers.
- `companion_chat_service.dart` reuses `Env.openAiApiKey` (`lib/config/env.dart:17`) and the same
  endpoint/headers shape as `meditation_validator_service.dart:115`. **Model: `gpt-4o-mini`** for cost
  parity with the existing validator (revisit if quality is short).
- Analytics: emit PostHog events on chat open (per entry point), message sent, share-card shared
  (per preset) — PostHog is the app's analytics layer.

---

## 9. Build phases (ordered, each independently shippable)

**Phase 0 — Plumbing (no UI risk).** Add `screenshot` to `pubspec`. Create the `companion/` folder,
models, `CompanionRepository` (sqflite + tests), barrel. _Risk: low._

**Phase 1 — Verse-of-the-Day share card.** Independent of chat, fully shippable alone. Build
`CozyVerseShareCard` + `verse_card_share_service.dart` + the preview sheet + the share button on the
VOD card. _Risk: image-capture fidelity across devices, font embedding (Satoshi must render in the
captured image), iPad share origin. Ship this first — it's lower-risk and demoable._

**Phase 2 — Companion chat shell (no memory, no persistence).** `cozy_companion_chat_screen.dart`,
bubbles, input, typing indicator, `companion_chat_service.dart` with the persona prompt (§4),
single-shot responses. Wire **Entry A1** (Bible home button) only. Empty state + starters. _Risk:
OpenAI latency/UX, prompt quality — get the founder to read real transcripts here._

**Phase 3 — Passage context + Entry A2 & B.** Add `CompanionPassage`, the context chip, the
auto-opener, the reading-app-bar button, and the **"Demander à l'IA"** 6th toolbar action. _Risk:
toolbar overflow with 6 actions → mitigate by (a) shortening labels, (b) icon-only on narrow widths,
or (c) moving Reflect+Ask into an overflow "•••". Decide during build with a device check._

**Phase 4 — Persistence + memory.** Wire `CompanionRepository` so conversations survive app restarts;
implement `openFor()` resume rules (§Flow C); build `CompanionContextBuilder` and inject struggles +
streak + last-12 history. _Risk: context bloat / token cost — keep N small; never inject full chapters
verbatim beyond the preloaded passage._

**Phase 5 — Polish.** Streaming tokens (upgrade from single-shot), scripture-block rendering inside
bubbles, personalized starters by `VerseCategory`, graceful error/offline inline message, analytics,
FR/EN string pass. _Risk: SSE parsing in Dart `http` — if flaky, keep single-shot from Phase 2._

> Supabase mirror (§6.3) is **not** a phase — schema + stub only.

---

## 10. QA acceptance criteria

QA-Designer verifies **rendering fidelity to Cozy** AND **functional correctness** end-to-end.

### Companion chat — rendering
- [ ] Screen bg is cream `#FBF3E2`; top bar uses `CozyIconButton` (not a Material AppBar).
- [ ] Assistant bubbles: cream/surface fill, **2.5px ink outline**, **hard offset shadow (3,5, no blur)**, squircle (`SmoothRectangleBorder`, smoothness 1.0) — visually identical chunk to `CozyCard`.
- [ ] User bubbles: terracotta `#D68A4E` fill, white text, same shadow/squircle.
- [ ] Satoshi font throughout; body text `height ≈ 1.5`, readable.
- [ ] Typing indicator animates inside a companion-styled bubble; replaced cleanly by the final answer.
- [ ] Input bar stays above the keyboard; send button disabled (0.5 opacity) when empty/in-flight.
- [ ] Scripture lines in a companion reply render as an inset block with terracotta accent + peach tint.

### Companion chat — functional
- [ ] Entry A1 (Bible home chat button) opens the companion; empty state shows 3–4 FR starter chips.
- [ ] Tapping a starter sends it and produces a warm, on-voice FR reply.
- [ ] Entry A2 (reading app bar) opens with the chapter reference as context; first companion message references it.
- [ ] Entry B ("Demander à l'IA" in the selection toolbar) opens with the **selected text** preloaded as a context chip; first message addresses that exact passage — **never a blank screen**.
- [ ] Detaching the context chip (×) reverts to general chat.
- [ ] Replies are short (2–5 sentences), end with one open question, stay in faith/wellbeing scope.
- [ ] Off-topic request (e.g. "écris-moi du code") is gently redirected, not answered.
- [ ] Crisis test phrase triggers a compassionate redirect to human help (no diagnosis, no dismissal).
- [ ] Network failure shows the gentle inline retry message, NOT a red error snackbar; app does not crash.

### Memory & persistence
- [ ] Killing and reopening the app restores the last conversation's messages (general entry resumes today's conversation).
- [ ] A user with `fearAnxiety` struggles + a 7-day streak gets replies that reference their journey with tact (verify via injected context + a representative transcript).
- [ ] Passage-scoped conversations (A2/B) start fresh and do not bleed into the general thread.
- [ ] Only the last 12 messages are sent to the model (verify the outgoing payload).

### Verse-of-the-Day share card — rendering
- [ ] Card matches Cozy: cream/accented bg, `CozyText.title` verse, terracotta reference, subtle "FaithLock" branding, signature chunky squircle + hard shadow.
- [ ] **Satoshi renders correctly in the exported PNG** (not a fallback system font).
- [ ] Verse text wraps elegantly with « » quotes; long verses don't clip; reference always visible.
- [ ] Each preset exports at the correct pixel size: story 1080×1920, square 1080×1080, default 1080×1350.

### Verse-of-the-Day share card — functional
- [ ] Share button on the VOD hero card opens the preview sheet (cream, `radiusLg` top, `CozySegmentedControl` preset picker).
- [ ] Switching preset updates the live preview.
- [ ] "Partager" produces a real PNG file in the OS share sheet (verify on physical iOS + Android).
- [ ] iPad: share popover anchors correctly (no crash, `sharePositionOrigin` respected).
- [ ] The shared card content matches the current Verse of the Day (`BibleController.verseOfDay`).

### Localization
- [ ] All new strings exist in both `fr_FR.dart` and `en_US.dart`; nothing hardcoded.
- [ ] With device/app locale FR, the entire companion + share flow is French (UI and AI replies).

---

## 11. Risks summary
- **Toolbar overflow** (6 actions) — mitigate per Phase 3.
- **Font in exported image** — Satoshi must be embedded in the capture; verify early (Phase 1).
- **OpenAI latency & prompt quality** — founder should read real transcripts before Phase 2 signs off.
- **Token cost creep** from memory injection — cap history at 12, never inject full chapters.
- **Anonymous-auth Supabase** makes cloud sync low-value in v1 → kept local-first (deliberate).

---

## 12. Open questions (need the founder's call)
1. **Default locale.** `AppConfig.defaultLocale` is `en_US` and the VOD/Bible UI strings on the home
   screen are currently **English** (`'Old Testament'`, `'Today'`, `'Bible'` are hardcoded English in
   `cozy_bible_home_screen.dart` / `main_screen.dart`). The brief says FR-first. **Confirm:** should
   v1 default to French, and should we also localize the existing hardcoded English Bible/nav strings
   as part of this work, or scope that separately?
2. **Verse category on the VOD.** `verseOfDay` returns only `{text, reference}` (no `VerseCategory`).
   For the share card's category accent, do we (a) ship a neutral terracotta accent in v1, or (b)
   enrich `verseOfDay()` to also return a category? Recommend (a) for v1.
3. **Model choice.** `gpt-4o-mini` for cost parity, or step up to a stronger model for the companion's
   emotional quality? Recommend starting on mini and A/B-ing in Phase 2.
4. **Apple Intelligence fallback for chat** — wire the on-device path in v1 (more work, free, iOS-26
   only) or OpenAI-only with graceful failure (recommended for v1)?
```
