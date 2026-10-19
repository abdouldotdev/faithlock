# Backlog

Product/content ideas not yet scheduled. Newest first.

---

## Prayer catalog — add depth per life situation + deep generalist prayers

**Status:** idea / not started · **Added:** 2026-06-23

**Context.** The catalog is broad but shallow per situation. As of 2026-06-23 Supabase holds **58 prayers across 6 domains** (struggles 11 · daily_rhythm 10 · life_seasons 10 · scripture 10 · drawing_near 9 · digital_focus 8). Breadth is good, but most *specific* life situations have **only one** prayer:
- **Grief / deuil** → just "Comfort in Grief".
- **Failure / échec** → none directly (only oblique: "When You're Discouraged", "Released from Shame").
- Most `life_seasons` (singleness, marriage, sickness, children, new beginning…) = 1 prayer each.

**Ask.** Reach **2–3 prayers per heavy situation**, plus a few **very deep, generalist** prayers that meet someone in raw pain regardless of cause — the kind that "help just by listening to them."

**Concretely:**
- Grief: sudden loss · loss of a parent · loss of a child/spouse · anniversary of a loss.
- Failure: career/financial failure · moral failure · starting over after failure.
- 2–3 universal "being carried" prayers: "when everything is too much", "a prayer to be held", "when I have no words".
- Generally deepen thin `life_seasons` situations to 2–3 each.

**Why it matters:**
- Directly serves the "meets you where you are" promise.
- More prayers per domain ⇒ better variety for the mood→prayer **curated random pick** (less repetition).

**Notes:** new prayers need the full pipeline — script_text + ElevenLabs MP3 (`audio_path`) + Replicate forced-alignment `word_timings` — to play in audio mode rather than falling back to TTS.
