# Garden of Grace — Mobile Build Plan

> Working plan for porting the validated web prototype (`apps/garden-web/`) to the
> Flutter app (`faithlock`). Canonical design: `docs/garden-gamification-spec.md` (v2).
> Engine is frozen and rendering-independent; the surface is **rhythm, story, gift** —
> never possession, score, or dread.

**Frozen foundations (compile-clean, on the branch):**
- `lib/features/garden/domain/garden_engine.dart` — pure engine (FruitKey, kFruits, kVerses, derive, Plot/LogEntry/Season/Recap, JourneyStep).
- `lib/features/garden/controllers/grace_garden_controller.dart` — GetX port of the zustand store + `build30Days()` / `buildJourney()`.
- `lib/features/garden/render/plant_renderer.dart` — `PlantRenderer` contract + `PlantVisual` + `GardenPlant` widget (the single asset-swap point).
- `lib/features/garden/screens/grace_garden_screen.dart`, route `/garden`.
- Assets are CustomPainter placeholders; real `.glb` swaps in behind `PlantRenderer` later.

Owners: **lead** (main / Tech Lead) · **dev1** (rendering + world) · **dev2** (onboarding + sim + overlays) · **qa** (tests).

---

## 1. Spec → mobile mapping

| Spec § | Concrete Flutter deliverable | Owner |
|---|---|---|
| §0 Covenant, §2 Theology guardrails | Anchor screen + covenant copy (first run, replayable); all copy uses *tend/water/abide* | dev2 |
| §1 Structure (9 plots) | 9-plot diorama layout in the garden world; `initialPlots()` already seeds 9 | dev1 |
| §3 Pip companion | Pip presence + voice strings table (single source); placeholder sprite behind a renderer hook | dev2 |
| §4 Resources / §5 Attribution | **Already in engine** (`readVerse`/`pray`/`talk`/`_applyActive`, `kVerses` awards). No new math. | lead (verify) |
| §6 Growth / endless tiers | `derive()` + named stages drive `PlantVisual.stage/tier`; renderer maps to art | dev1 |
| §7 Rhythm | `rhythm()` multiplier (engine) → surfaced as **warmth/light/creatures**, never a number | dev1 (surface) |
| §8 Health / resting / revival | `health` + `goAway`/`newMorning` (engine) → foliage shader/desaturation+droop in renderer | dev1 |
| §9 Tending gestures | Harvest tap, water animation, prune; wired to `shareHarvest`/per-action pop | dev1 + dev2 |
| §10 Bloom + harvest-you-share | Stage-up bloom + verse card; `shareHarvest` already increments `fruitShared` | dev2 |
| §11 Botanical realism (9 species) | `PlantArchetype` → species; aging states; seasonal/dormancy via `Season` + `evergreen` | dev1 |
| §12 Meta-progression | Decor/creatures/memory-stone/seasons/day-night overlays | dev2 |
| §13 Daily/weekly/seasonal loop | Recap-on-open (`Recap`), Sunday recap, Letter-from-Pip surfaces | dev2 |
| §14 Notifications | Pip-voice copy table (wiring to OneSignal deferred; copy + opt-out scaffold) | dev2 |
| §15 Growth journal | Per-plot Cozy sheet rendered from `log` (`LogEntry`), qualitative, gains-only | dev2 |
| §16 Data model | Engine state mirrors spec; **persistence (local store) is the one gap to add** | lead |
| §17 Tuning | **Engine-only constants — frozen; never shown** | lead (guard) |
| §18 Edge cases | Clock-clamp [0,14], local-calendar days, comeback warmth, offline | lead + qa |
| §19 Rendering path | Placeholder CustomPainter now → `.glb` behind `PlantRenderer` (see §4 below) | dev1 |
| §20 Ethical retention | No guilt / no streak-break / no dying garden — enforced by engine + copy review | all |
| §21 Onboarding tour | Auto-play cinematic (5 beats) + 30-day sim (`build30Days`) | dev2 |

**Gaps to schedule (not yet in foundations):** local persistence of `GardenState` (§16), notification wiring (§14), real `.glb` assets (§19). Everything else is render/copy/UX over a frozen engine.

---

## 2. Parity checklist — engine math that MUST match the web

Verified against `grace_garden_controller.dart` today; QA owns the regression. **No user-facing numbers anywhere.**

- [ ] **Read a verse** (`readVerse`): each award → `growth += round(10 · weight · rhythm)`; **splash** `+round(2 · rhythm)` to **all 9**; pop signal on awarded fruits.
- [ ] **Pray** (`pray`): `growth += round(1 · 3 · rhythm)` to **all 9** (rain/splash, **no Faithfulness award**).
- [ ] **Talk with Pip** (`talk`): `growth += round(15 · rhythm)` to target (selected, else lowest-growth).
- [ ] **First practice of day** (`_applyActive`, once/day): Faithfulness **+3**, health **+10** (**+12** if returning), rhythm window **+1**; no-op on later same-day practices.
- [ ] **Rhythm** (`rhythm`): `1 + 0.04 · activeDaysWindow`, **cap ×1.28** (7/7).
- [ ] **Go away** (`goAway`): health **−6** (floor **20**), window **−1** (floor 0), day **+1**.
- [ ] **New morning** (`newMorning`): set `harvestReady = true` for any plot with `growth ≥ 80`; warm comeback recap if `wasAway`.
- [ ] **Derive tiers** (`derive`): youth 20/40/60/80/100 (stage 1–5); endless **100→160→256→410→656** = tiers 6–10 with boosts **1.25 / 1.45 / 1.65 / 1.95 / 2.25**; growth **monotonic & unbounded** (never decreases).
- [ ] **Milestone log** on tier-up (`_checkMilestone`) → `LogEntry(milestone: true)`.
- [ ] **Two-fruit split** 70/30 preserved via `kVerses` award weights (anger, pride-adjacent, perseverance, service).
- [ ] **Verse cursor** deterministic seed (`_rand = 3`) for web parity.

QA cross-check: a fixed action sequence must produce **identical growth/health/tier** in Dart and the web engine (`apps/garden-web/src/engine/garden.ts`).

---

## 3. Onboarding requirements (§21) + the 30-day sim

**Cinematic, auto-play, ~40s, skippable + replayable.** The garden is shown as a **render of actions done elsewhere** (read/pray/talk in the app), not a place you "play." 5 beats:

1. **Welcome / covenant** — Pip: *"I can't make anything grow here — that's not my job, or yours…"*. Pulsing **Begin** affordance to invite the tap.
2. **"This is your garden"** — nine plots / nine fruits growing together.
3. **"Tending is simple"** — read / pray / talk.
4. **The aha (interactive)** — user reads one verse → a plant **visibly grows** → grace/anti-guilt reassurance (*"nothing you grow is ever lost… coming back is always enough"*).
5. **"It tells your story" + preview** — time-lapse reusing the auto-journey → **Begin**.

Required behaviors (mirror `Onboarding.tsx`):
- **Element isolation in sync with narration** — `setIntro(focus:/solo:)` highlights one fruit while Pip speaks about it; others dimmed.
- **Attribution demo** — show *verse on anxiety → Peace deepens* (uses `readVerse('fearAnxiety')`) so the cause→fruit link is felt.
- **Tree states** — sweep a plant through stages (`setGrowth`) so aging reads as endless.
- **Regression-when-you-stop** — demo `goAway` showing **health dips / plant rests** but **growth is intact** (resting, never failing, never dying).
- **Pulsing Begin** until the user acts.
- **Full live garden underneath** the overlay (engine runs; not a faked screen).

**30-day sim follows** (`build30Days()`): plays right after onboarding — early fast youth growth, a comeback (`goAway`→`newMorning` warmth), then a steadier rhythm; each `JourneyStep.toast` narrates the day. Confirms "it works, and it's mine" inside the 7-day habit window (§20).

---

## 4. Asset-swap plan (§19) — placeholder → real

**Single swap point:** `PlantRenderer`. Today a `CustomPainter` impl returns a `PlantVisual` for a given `(archetype, stage, tier, health, season)`. Real art swaps by registering a new `PlantRenderer` (a `model_viewer`/glTF-backed widget); **no engine, controller, or screen changes.**

**Target format:** low-poly **`.glb`** (glTF) — the same files validated in R3F on web port directly to Flutter; only the renderer wrapper is re-authored (per `docs/garden-asset-prompts.md`). Flat-faceted shading, single watertight mesh, foliage as a distinct material so **health = a shader on foliage** (desaturate ~30% at <60, brown ~55% + droop at <35) — **no baked wilt models**.

**Per plant:** aging states on a shared origin so they cross-fade — seedling → mature → ancient → grove (maps to `derive` tiers 1–5 / 6 / 9 / 10+), plus creature/nest add-ons. 9 species (Love rose, Joy sunflower, Peace olive·evergreen, Patience oak, Kindness cherry, Goodness apple, Faithfulness pine·evergreen, Gentleness willow, Self-control grapevine).

**Recommended pipeline — pick ONE; you do NOT need every tool:**
- **Meshy 6 — primary, all-in-one.** Rig + animate Pip *and* generate the 9 plants/aging states. Use this if you want a single tool end-to-end.
- **Tripo v3.1 — optional** fast/cheap batch generation of plants and small props (bench, well, birdbath, cross). Use only if you want to parallelize asset volume.
- **TRELLIS 2 — optional, self-host only** to cut per-asset cost at scale.
- **Skip Rodin** — it targets photoreal humans; off-brief for low-poly cozy.

Acceptance for the swap: drop-in `PlantRenderer` produces visually correct stage/health/season output for all 9 species with **zero diff** in engine/controller/screen.

---

## 5. Acceptance criteria (Definition of Done per teammate)

**lead (main):**
- Engine + tuning constants stay frozen and **never surfaced as numbers**; §16 local persistence added (`GardenState` survives restart); §18 edge cases enforced (day-delta clamp [0,14], local-calendar days, offline). PR compiles clean; `flutter analyze` clean.

**dev1 (rendering + world):**
- Fullscreen navigable diorama with 9 plots; orbit camera (drag-rotate, scroll/pinch-zoom). Placeholder `PlantRenderer` renders all 6 archetypes across stages 1–10 and reads **health** (desaturate/droop) and **rhythm** (warmth/light/creatures) **without showing any number**. Day/night from device time. Asset-swap seam proven (one renderer registration point).

**dev2 (onboarding + sim + overlays):**
- 5-beat cinematic (auto-play, skippable, replayable, pulsing Begin) with narration-synced element isolation, attribution demo, tree-state sweep, and regression-when-you-stop. 30-day sim plays via `build30Days()`. Growth-journal sheet (qualitative, gains-only) from `log`. Recap-on-open + Pip-voice copy tables (notifications copy, **opt-out + ≤1/day, never guilt**).

**qa (tests):**
- Engine unit tests assert every box in §2 (read/pray/talk/firstPractice/rhythm-cap/goAway/newMorning/derive-tiers/milestone/split) and the **web-parity** sequence. Plant golden tests cover stages × health × season. Guardrail tests: growth never decreases; health floor 20 (never dies); no user-facing growth number reachable in UI.

---

### Notes
- All copy goes through Pip's voice rules (§3): short, "we/your/you," deflect glory to God, never guilt/"you missed"/"X days since."
- Retention rests on ethical levers only (§20): no streak-break, no dying garden, recap-before-effort, nature-based variable reward.
