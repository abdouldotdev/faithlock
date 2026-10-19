#!/usr/bin/env node
/**
 * FaithLock prayer pipeline.
 *   text   → generate guided-prayer scripts with an LLM (review before TTS!)
 *   audio  → synthesize mp3 from the reviewed text (Replicate · ElevenLabs v3)
 *   upload → push mp3 to Supabase Storage + upsert the `prayers` table
 *   align  → forced-align mp3 ↔ script → upsert word_timings (Replicate
 *            cureau/force-align-wordstamps). Runs against Supabase so it
 *            retrofits both fresh and already-uploaded prayers.
 *   all    → text → audio → upload → align
 *
 * Flags: --only=<id>  --domain=<d>  --lang=en|fr  --force
 * Requires Node 18+ (built-in fetch). Config via .env (see .env.example).
 */
import 'dotenv/config';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import Anthropic from '@anthropic-ai/sdk';
import { createClient } from '@supabase/supabase-js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(__dirname, 'output');
const TEXT_DIR = path.join(OUT, 'text');
const AUDIO_DIR = path.join(OUT, 'audio');
for (const d of [TEXT_DIR, AUDIO_DIR]) fs.mkdirSync(d, { recursive: true });

// ── args ──────────────────────────────────────────────────────────────────
const [phase = 'help', ...rest] = process.argv.slice(2);
const flags = Object.fromEntries(
  rest.filter((a) => a.startsWith('--')).map((a) => {
    const [k, v] = a.replace(/^--/, '').split('=');
    return [k, v ?? true];
  }),
);
const LANG = flags.lang || process.env.DEFAULT_LANG || 'en';
const FORCE = !!flags.force;

const catalog = JSON.parse(fs.readFileSync(path.join(__dirname, 'catalog.json'), 'utf8'));
let prayers = catalog.prayers;
if (flags.only) prayers = prayers.filter((p) => p.id === flags.only);
if (flags.domain) prayers = prayers.filter((p) => p.domain === flags.domain);

const textPath = (p) => path.join(TEXT_DIR, `${p.id}.${LANG}.json`);
const audioPath = (p) => path.join(AUDIO_DIR, `${p.id}.${LANG}.mp3`);
const log = (...a) => console.log(...a);

// ── providers ─────────────────────────────────────────────────────────────
function anthropic() {
  if (!process.env.ANTHROPIC_API_KEY) throw new Error('ANTHROPIC_API_KEY missing');
  return new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });
}
function supabase() {
  const { SUPABASE_URL } = process.env;
  // Prefer the secret (service_role) key — it bypasses RLS, so the pipeline can
  // upload + write regardless of client policies. Falls back to the publishable
  // key only if no secret is configured.
  const key = process.env.SUPABASE_SECRET_KEY || process.env.SUPABASE_ANON_KEY;
  if (!SUPABASE_URL || !key) {
    throw new Error('SUPABASE_URL / SUPABASE_SECRET_KEY missing');
  }
  return createClient(SUPABASE_URL, key, { auth: { persistSession: false } });
}

const SYSTEM_PROMPT = `You are a deeply pastoral writer crafting GUIDED PRAYER scripts to be read aloud (text-to-speech) in a premium prayer app. Your gift is meeting a real person in the truth of what they are carrying and walking them, tenderly, toward God.

VOICE
- Write to ONE person, as someone who knows and loves them. Warm, intimate, unhurried, real. Never cheesy, never preachy, never a performance, never a sales pitch.
- Go beneath the surface. Don't just set a calm scene — name the actual feeling underneath it (the loneliness, the shame, the exhaustion, the fear, the numbness, the quiet longing) with compassion and without flinching. People feel loved when they feel SEEN.
- Be specific and human, not abstract. One honest, concrete image lands deeper than three lines of gentle generality.
- Let there be tenderness, and where the theme calls for it, holy ache — then move toward hope. Earned comfort, not forced cheer.

SHAPE (a felt journey, not a lecture)
1. Arrive — a few short lines that help them stop and feel God draw near.
2. Name what's true — gently surface the real emotion this theme is about; let them feel met in it.
3. The Word — bring in the given Scripture as the turning point: the voice of God speaking into exactly that place.
4. Pray — speak honest words TO God on their behalf (and invite their own), carrying the feeling into his presence.
5. Receive & rest — let his love, truth, or promise settle over them; close with a short blessing.
- Use "(pause)" wherever silence should breathe — generously around the tender moments.

CRAFT
- Write for the EAR (to be spoken): short sentences, natural spoken rhythm, room to breathe. No headings, no markdown, no stage directions other than "(pause)".
- Use ONLY public-domain Scripture: World English Bible (WEB) for English, Louis Segond 1910 for French. Quote the given reference accurately and let it carry real weight.
- Theologically careful and orthodox — nothing a mainstream Christian tradition would object to. The depth comes from honesty and love, never from sentimentality or shaky theology.
- Return STRICT JSON only, no prose outside the JSON.`;

const userPrompt = (p) => `Write a guided prayer in ${LANG === 'fr' ? 'French' : 'English'}.
Title: ${p.title}
Theme/domain: ${p.domain}
Scripture reference (quote it from ${LANG === 'fr' ? 'Louis Segond 1910' : 'World English Bible'}): ${p.scriptureRef}
Target spoken length: about ${p.lengthMin} minutes.
Brief: ${p.brief}

Reach the heart: meet the person honestly in what this theme stirs in them, then carry them toward God. Avoid generic "calm down / put your phone away" narration — go to the real feeling underneath and let the Scripture speak straight into it.

Return STRICT JSON (and nothing else) with this shape:
{
  "scriptureText": "the quoted verse(s)",
  "script": "the full spoken guided-prayer text, with (pause) markers where silence is intended",
  "estimatedDurationSec": <integer>
}`;

// ── phases ──────────────────────────────────────────────────────────────--
async function genText(p) {
  const out = textPath(p);
  if (fs.existsSync(out) && !FORCE) return log('  ⏭  text exists', p.id);
  // Opus 4.8 is the most capable model — worth it for emotional, literary
  // prayer writing. Adaptive thinking lets it plan the felt arc before it
  // writes. Override per run with LLM_MODEL in .env if your key lacks 4.8.
  const model = process.env.LLM_MODEL || 'claude-opus-4-8';
  const msg = await anthropic().messages.create({
    model,
    max_tokens: 5000,
    thinking: { type: 'adaptive' },
    system: SYSTEM_PROMPT,
    messages: [{ role: 'user', content: userPrompt(p) }],
  });
  const raw = msg.content.map((c) => c.text || '').join('').trim();
  const json = JSON.parse(raw.replace(/^```(?:json)?\s*|\s*```$/g, ''));
  fs.writeFileSync(out, JSON.stringify({ ...p, lang: LANG, ...json }, null, 2));
  log('  ✓ text', p.id, `~${json.estimatedDurationSec}s`);
}

async function genAudio(p) {
  const tp = textPath(p);
  const ap = audioPath(p);
  if (!fs.existsSync(tp)) return log('  !  no text (run `text` first)', p.id);
  if (fs.existsSync(ap) && !FORCE) return log('  ⏭  audio exists', p.id);
  const { REPLICATE_API_TOKEN } = process.env;
  if (!REPLICATE_API_TOKEN) throw new Error('REPLICATE_API_TOKEN missing');
  const model = process.env.REPLICATE_TTS_MODEL || 'elevenlabs/v3';
  const voice = process.env.REPLICATE_VOICE || 'Paul';
  const auth = { Authorization: `Bearer ${REPLICATE_API_TOKEN}` };

  const { script } = JSON.parse(fs.readFileSync(tp, 'utf8'));
  const prompt = script.replaceAll('(pause)', '<break time="2.0s" />');

  // Create the prediction. `Prefer: wait` holds the request open (~60s) so short
  // prayers return finished; longer ones fall through to polling below.
  let res = await fetch(`https://api.replicate.com/v1/models/${model}/predictions`, {
    method: 'POST',
    headers: { ...auth, 'Content-Type': 'application/json', Prefer: 'wait' },
    body: JSON.stringify({ input: { voice, prompt } }),
  });
  if (!res.ok) throw new Error(`Replicate ${res.status}: ${await res.text()}`);
  let pred = await res.json();

  // Poll until the prediction settles (guided prayers can exceed the wait window).
  while (pred.status === 'starting' || pred.status === 'processing') {
    await new Promise((r) => setTimeout(r, 2000));
    res = await fetch(pred.urls.get, { headers: auth });
    pred = await res.json();
  }
  if (pred.status !== 'succeeded') {
    throw new Error(`Replicate prediction ${pred.status}: ${pred.error ?? 'unknown error'}`);
  }

  const audioUrl = Array.isArray(pred.output) ? pred.output[0] : pred.output;
  if (!audioUrl) throw new Error('Replicate returned no audio output');
  const audioRes = await fetch(audioUrl);
  if (!audioRes.ok) throw new Error(`audio download ${audioRes.status} for ${p.id}`);
  const buf = Buffer.from(await audioRes.arrayBuffer());
  fs.writeFileSync(ap, buf);
  log('  ✓ audio', p.id, `${(buf.length / 1024).toFixed(0)}KB`);
}

async function upload(p) {
  const tp = textPath(p);
  const ap = audioPath(p);
  if (!fs.existsSync(ap)) return log('  !  no audio (run `audio` first)', p.id);
  const meta = JSON.parse(fs.readFileSync(tp, 'utf8'));
  const sb = supabase();
  const bucket = process.env.SUPABASE_BUCKET || 'prayer-audio';
  const objectPath = `${p.domain}/${p.id}.${LANG}.mp3`;
  const { error: upErr } = await sb.storage
    .from(bucket)
    .upload(objectPath, fs.readFileSync(ap), { contentType: 'audio/mpeg', upsert: true });
  if (upErr) throw upErr;
  const { data: pub } = sb.storage.from(bucket).getPublicUrl(objectPath);
  const { error: dbErr } = await sb.from(process.env.SUPABASE_TABLE || 'prayers').upsert({
    id: p.id,
    title: p.title,
    domain: p.domain,
    lang: LANG,
    scripture_ref: p.scriptureRef,
    scripture_text: meta.scriptureText,
    script_text: meta.script,
    duration_sec: meta.estimatedDurationSec,
    audio_path: objectPath,
    audio_url: pub.publicUrl,
    updated_at: new Date().toISOString(),
  }, { onConflict: 'id,lang' });
  if (dbErr) throw dbErr;
  log('  ✓ upload', p.id, pub.publicUrl);
}

// ── align: forced word timestamps via Replicate ─────────────────────────--
//
// Reads `audio_path` + `script_text` from Supabase, mints a signed URL for the
// MP3, sends both to cureau/force-align-wordstamps, normalises the model's
// seconds → ms, and writes the result into `prayers.word_timings` (jsonb).
//
// Note on the Replicate endpoint: cureau/force-align-wordstamps is a community
// model (`is_official: false`), so we MUST use `POST /v1/predictions` with a
// `version` hash — `/v1/models/{owner}/{name}/predictions` (which works for
// `elevenlabs/v3` in genAudio) returns 404 for community models. The latest
// version is fetched once per process and cached in [_alignVersion].
let _alignVersion = null;

async function align(p) {
  const sb = supabase();
  const { REPLICATE_API_TOKEN } = process.env;
  if (!REPLICATE_API_TOKEN) throw new Error('REPLICATE_API_TOKEN missing');
  const auth = { Authorization: `Bearer ${REPLICATE_API_TOKEN}` };
  const model = process.env.REPLICATE_ALIGN_MODEL || 'cureau/force-align-wordstamps';
  const table = process.env.SUPABASE_TABLE || 'prayers';
  const bucket = process.env.SUPABASE_BUCKET || 'prayer-audio';

  // Pull the prayer's audio + transcript (and any existing timings to skip).
  const { data: row, error: fetchErr } = await sb
    .from(table)
    .select('audio_path, script_text, scripture_text, word_timings')
    .eq('id', p.id)
    .eq('lang', LANG)
    .maybeSingle();
  if (fetchErr) throw fetchErr;
  if (!row) return log('  !  not in db (run `upload` first)', p.id);
  if (!FORCE && Array.isArray(row.word_timings) && row.word_timings.length) {
    return log('  ⏭  timings exist', p.id);
  }
  if (!row.audio_path) return log('  !  no audio_path', p.id);

  // Sign the audio so the Replicate worker can fetch it.
  const { data: signed, error: signErr } = await sb.storage
    .from(bucket)
    .createSignedUrl(row.audio_path, 3600);
  if (signErr) throw signErr;

  // The transcript fed to the aligner must match what's actually spoken in the
  // MP3 — strip (pause) markers (they're SSML hints to ElevenLabs, not words).
  const transcript = String(row.script_text || row.scripture_text || '')
    .replaceAll('(pause)', ' ')
    .replace(/\s+/g, ' ')
    .trim();
  if (!transcript) return log('  !  no transcript', p.id);

  // Resolve the model's latest version once, then reuse for the rest of the run.
  if (!_alignVersion) {
    _alignVersion = process.env.REPLICATE_ALIGN_VERSION;
    if (!_alignVersion) {
      const mRes = await fetch(`https://api.replicate.com/v1/models/${model}`, {
        headers: auth,
      });
      if (!mRes.ok) {
        throw new Error(`Replicate model fetch ${mRes.status}: ${await mRes.text()}`);
      }
      const mData = await mRes.json();
      _alignVersion = mData.latest_version?.id;
      if (!_alignVersion) throw new Error('align: no latest_version id on model');
    }
  }

  // Community models: versioned predictions endpoint (NOT /models/.../predictions).
  let res = await fetch(`https://api.replicate.com/v1/predictions`, {
    method: 'POST',
    headers: { ...auth, 'Content-Type': 'application/json', Prefer: 'wait' },
    body: JSON.stringify({
      version: _alignVersion,
      input: {
        audio_file: signed.signedUrl,
        transcript,
      },
    }),
  });
  if (!res.ok) throw new Error(`Replicate ${res.status}: ${await res.text()}`);
  let pred = await res.json();
  while (pred.status === 'starting' || pred.status === 'processing') {
    await new Promise((r) => setTimeout(r, 2000));
    res = await fetch(pred.urls.get, { headers: auth });
    pred = await res.json();
  }
  if (pred.status !== 'succeeded') {
    throw new Error(`Replicate prediction ${pred.status}: ${pred.error ?? 'unknown error'}`);
  }

  // Output shape on the current `cureau/force-align-wordstamps` version
  // (44dedb84…) is `{ "wordstamps": [{ word, start, end, probability }, ...] }`.
  // Older versions used `{ "output": [...] }`. We accept any of the known
  // wrappers so a future model bump doesn't silently break the pipeline.
  const o = pred.output;
  const rawWords = Array.isArray(o?.wordstamps)
    ? o.wordstamps
    : Array.isArray(o?.output)
        ? o.output
        : Array.isArray(o?.words)
            ? o.words
            : Array.isArray(o)
                ? o
                : [];
  if (rawWords.length === 0) {
    throw new Error(`align: empty word list (output keys: ${Object.keys(o || {}).join(',')})`);
  }
  const words = rawWords.map((w) => ({
    word: String(w.word ?? w.text ?? '').trim(),
    start_ms: Math.round((Number(w.start ?? w.start_time ?? 0)) * 1000),
    end_ms: Math.round((Number(w.end ?? w.end_time ?? 0)) * 1000),
  })).filter((w) => w.word.length > 0);

  // Persist.
  const { error: updErr } = await sb
    .from(table)
    .update({ word_timings: words, updated_at: new Date().toISOString() })
    .eq('id', p.id)
    .eq('lang', LANG);
  if (updErr) throw updErr;
  log('  ✓ align', p.id, `${words.length} words`);
}

// ── runner ──────────────────────────────────────────────────────────────--
async function run(fn, label) {
  log(`\n▶ ${label} — ${prayers.length} prayer(s) · lang=${LANG}${FORCE ? ' · force' : ''}\n`);
  let ok = 0;
  for (const p of prayers) {
    try {
      await fn(p);
      ok++;
    } catch (e) {
      console.error(`  ✗ ${p.id}: ${e.message}`);
    }
  }
  log(`\n${label} done (${ok}/${prayers.length}).`);
}

const HELP = `FaithLock prayer pipeline

  node generate.mjs text    [--only=id] [--domain=d] [--lang=en|fr] [--force]
  node generate.mjs audio   [...same flags]
  node generate.mjs upload  [...same flags]
  node generate.mjs align   [...same flags]
  node generate.mjs all     [...same flags]

Recommended flow:
  1) npm run text            # generate scripts
  2) review output/text/*.json   # ← read the prayers before spending TTS credits
  3) npm run audio           # synthesize mp3
  4) npm run upload          # push to Supabase Storage + prayers table
  5) npm run align           # forced-align mp3 ↔ script → word_timings

Retrofit an already-uploaded prayer: just run \`npm run align --only=<id>\`.

Catalog: catalog.json   ·   Config: .env (see .env.example)   ·   DB: schema.sql`;

(async () => {
  switch (phase) {
    case 'text':
      await run(genText, 'Generating text (LLM)');
      break;
    case 'audio':
      await run(genAudio, 'Generating audio (Replicate · ElevenLabs v3)');
      break;
    case 'upload':
      await run(upload, 'Uploading to Supabase');
      break;
    case 'align':
      await run(align, 'Aligning words (Replicate · cureau/force-align-wordstamps)');
      break;
    case 'all':
      await run(genText, 'Generating text (LLM)');
      await run(genAudio, 'Generating audio (Replicate · ElevenLabs v3)');
      await run(upload, 'Uploading to Supabase');
      await run(align, 'Aligning words (Replicate · cureau/force-align-wordstamps)');
      break;
    default:
      log(HELP);
  }
})();
