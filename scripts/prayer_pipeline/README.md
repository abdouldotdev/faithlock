# FaithLock — Prayer Content Pipeline

Generates guided prayers end-to-end:

**catalog → LLM (text) → Replicate · ElevenLabs v3 (audio) → Supabase Storage + `prayers` table.**

## Setup (once)

```bash
cd scripts/prayer_pipeline
npm install
cp .env.example .env      # then fill in your keys
```

Fill `.env`:
- `ANTHROPIC_API_KEY` — generates the prayer scripts (`LLM_MODEL` default `claude-sonnet-4-6`).
- `REPLICATE_API_TOKEN` — synthesizes audio via Replicate's `elevenlabs/v3` model. Set `REPLICATE_VOICE` to the voice name (default `Paul`).
- `SUPABASE_URL` + `SUPABASE_SERVICE_ROLE_KEY` — the **service_role** key (Settings → API). Keep secret; never ship it in the app.

In Supabase:
1. Run `schema.sql` (SQL editor) → creates the `prayers` table + read policy **and** the public `prayer-audio` storage bucket. That's it — no manual bucket step.

## Run (3 phases — review before TTS)

```bash
npm run text     # 1. generate scripts → output/text/*.json
#   2. ⟵ READ output/text/*.json and tweak any wording before spending TTS credits
npm run audio    # 3. synthesize mp3 → output/audio/*.mp3
npm run upload   # 4. upload mp3 to Storage + upsert the prayers table
```

Or everything at once: `npm run all`.

### Flags
- `--only=morning-prayer` — a single prayer
- `--domain=struggles` — one domain (`daily_rhythm`, `struggles`, `drawing_near`, `scripture`, `life_seasons`)
- `--lang=fr` — French (Louis Segond 1910); default `en` (WEB)
- `--force` — regenerate even if the output already exists

Example: `node generate.mjs all --domain=daily_rhythm --lang=fr`

## Adding prayers
Append entries to `catalog.json` (`id`, `title`, `domain`, `scriptureRef`, `lengthMin`, `brief`). Re-run the phases — existing outputs are skipped unless `--force`.

## Notes
- **Idempotent**: each phase skips work already done (resume-safe).
- **Licensing**: scripts are original (we own them); Scripture is public-domain (WEB / Segond 1910). Add only royalty-free music beds later.
- `output/` and `.env` are git-ignored.
- The Flutter app reads the `prayers` table (public read) and streams `audio_url`.
