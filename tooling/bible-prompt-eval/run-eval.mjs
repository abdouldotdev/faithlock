#!/usr/bin/env node
/**
 * Bible Companion — OpenRouter model bake-off (collector).
 *
 * Runs the hardened system prompt (forged by the brainstorm workflow) against a
 * battery of hard test cases on the 5 strongest available OpenRouter models, and
 * COLLECTS every response so a human (Claude, the main agent) can judge them.
 *
 * Two outputs:
 *   - results.json : structured, every model × every case + deterministic gates
 *   - report.md    : human-readable, grouped by test case, 5 answers side by side
 *
 * Deterministic gates only (no LLM judge): must_include present? must_avoid absent?
 *
 * Usage:
 *   OPENROUTER_API_KEY=sk-or-... node tooling/bible-prompt-eval/run-eval.mjs
 *   (or drop the key in tooling/bible-prompt-eval/.env.local — gitignored)
 */
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, '..', '..');
const OR_BASE = 'https://openrouter.ai/api/v1';

// ---- Load key (env or local gitignored file) ----------------------------------
function loadKey() {
  if (process.env.OPENROUTER_API_KEY) return process.env.OPENROUTER_API_KEY.trim();
  const envFile = resolve(__dirname, '.env.local');
  if (existsSync(envFile)) {
    const m = readFileSync(envFile, 'utf8').match(/OPENROUTER_API_KEY\s*=\s*(.+)/);
    if (m) return m[1].trim().replace(/^["']|["']$/g, '');
  }
  console.error('✖ OPENROUTER_API_KEY not found (env or tooling/bible-prompt-eval/.env.local)');
  process.exit(1);
}
const KEY = loadKey();

// Optional overrides (used for the fair re-run of reasoning models):
//   MAX_TOKENS=4000 ONLY_MODELS=openai/gpt-5,google/gemini-2.5-pro
//   REASONING_EFFORT=low OUT_SUFFIX=-reasoning node run-eval.mjs
const MAX_TOKENS = Number(process.env.MAX_TOKENS || 500);
const ONLY = (process.env.ONLY_MODELS || '').split(',').map((s) => s.trim()).filter(Boolean);
const SUF = process.env.OUT_SUFFIX || '';

// ---- Candidate models. Verified available on OpenRouter (2026-06). pickModels()
//      takes one-per-provider first (diversity), then fills to 5. ---------------
const PREFERRED = [
  'anthropic/claude-opus-4.1',   // Anthropic flagship
  'openai/gpt-5',                // OpenAI flagship
  'google/gemini-2.5-pro',       // Google flagship
  'deepseek/deepseek-r1',        // DeepSeek reasoning
  'anthropic/claude-sonnet-4.5', // 5th slot (2nd Anthropic — strong + cheaper)
  // Reserves (used only if a flagship drops offline):
  'openai/o3', 'openai/gpt-4.1', 'anthropic/claude-opus-4', 'deepseek/deepseek-chat',
];
const PROVIDER = (id) => id.split('/')[0];

const headers = {
  'Authorization': `Bearer ${KEY}`,
  'Content-Type': 'application/json',
  'HTTP-Referer': 'https://faithlock.app',
  'X-Title': 'FaithLock Bible Companion Eval',
};

async function listAvailable() {
  const r = await fetch(`${OR_BASE}/models`, { headers });
  if (!r.ok) { console.error('✖ /models failed', r.status); return new Set(); }
  const j = await r.json();
  return new Set((j.data || []).map((m) => m.id));
}

function pickModels(available) {
  if (ONLY.length) return ONLY.filter((id) => available.has(id));
  const picked = [], usedProvider = new Set();
  for (const id of PREFERRED) {
    if (picked.length >= 5) break;
    if (available.has(id) && !usedProvider.has(PROVIDER(id))) { picked.push(id); usedProvider.add(PROVIDER(id)); }
  }
  for (const id of PREFERRED) {
    if (picked.length >= 5) break;
    if (available.has(id) && !picked.includes(id)) picked.push(id);
  }
  return picked;
}

const sleep = (ms) => new Promise((res) => setTimeout(res, ms));

async function chat(model, messages, { temperature = 0.6, max_tokens = 500, retries = 2 } = {}) {
  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      const body = { model, messages, temperature, max_tokens };
      if (process.env.REASONING_EFFORT) body.reasoning = { effort: process.env.REASONING_EFFORT };
      const r = await fetch(`${OR_BASE}/chat/completions`, {
        method: 'POST', headers, body: JSON.stringify(body),
      });
      if (r.status === 429 || r.status >= 500) { await sleep(1500 * (attempt + 1)); continue; }
      const j = await r.json();
      if (!r.ok) return { error: `${r.status}: ${JSON.stringify(j).slice(0, 200)}` };
      return { text: j.choices?.[0]?.message?.content?.trim() ?? '' };
    } catch (e) {
      if (attempt === retries) return { error: String(e) };
      await sleep(1500 * (attempt + 1));
    }
  }
  return { error: 'exhausted retries' };
}

// ---- Extract the actual system prompt from the markdown file ------------------
function loadSystemPrompt(battery) {
  if (typeof battery.system_prompt === 'string' && battery.system_prompt.trim()) return battery.system_prompt;
  const p = resolve(REPO_ROOT, battery.system_prompt_path);
  const raw = readFileSync(p, 'utf8');
  const blocks = [...raw.matchAll(/```[a-zA-Z]*\n([\s\S]*?)```/g)].map((m) => m[1]);
  if (blocks.length) return blocks.sort((a, b) => b.length - a.length)[0].trim();
  return raw.trim();
}

function fill(prompt, c) {
  return prompt
    .replaceAll('{{BIBLE_VERSION}}', c.bible_version || 'King James Version')
    .replaceAll('{{VERSE_CONTEXT}}', c.verse_context || '');
}

// ---- Deterministic gates ------------------------------------------------------
function gateCheck(text, c) {
  const lc = (text || '').toLowerCase();
  const missing = (c.must_include || []).filter((s) => !lc.includes(String(s).toLowerCase()));
  const violated = (c.must_avoid || []).filter((s) => lc.includes(String(s).toLowerCase()));
  return { passed: missing.length === 0 && violated.length === 0, missing, violated };
}

async function mapLimit(items, limit, fn) {
  const out = new Array(items.length);
  let i = 0;
  await Promise.all(Array.from({ length: Math.min(limit, items.length) }, async () => {
    while (i < items.length) { const idx = i++; out[idx] = await fn(items[idx], idx); }
  }));
  return out;
}

function mdEscape(s) { return (s || '').replace(/\r/g, '').trim(); }

(async () => {
  const batteryPath = resolve(__dirname, 'test-battery.json');
  if (!existsSync(batteryPath)) {
    console.error('✖ test-battery.json not found — the prompt-forge workflow must finish first.');
    process.exit(1);
  }
  const battery = JSON.parse(readFileSync(batteryPath, 'utf8'));
  const cases = battery.cases || [];
  const systemPrompt = loadSystemPrompt(battery);
  console.log(`▸ Loaded ${cases.length} test cases · system prompt ${systemPrompt.length} chars`);

  const available = await listAvailable();
  const models = pickModels(available);
  if (!models.length) { console.error('✖ No preferred models available on OpenRouter'); process.exit(1); }
  console.log(`▸ Models: ${models.join(', ')}\n`);

  const perModelGate = Object.fromEntries(models.map((m) => [m, { pass: 0, total: 0, errors: 0 }]));
  const collected = []; // {case, answers:[{model,text,error,gate}]}

  for (const c of cases) {
    process.stdout.write(`• ${c.id} [${c.category}] (${c.bible_version}) ... `);
    const sys = fill(systemPrompt, c);
    const msgs = [{ role: 'system', content: sys }, { role: 'user', content: c.user_input }];
    const answers = await mapLimit(models, 4, async (model) => {
      const { text, error } = await chat(model, msgs, { max_tokens: MAX_TOKENS });
      const slot = perModelGate[model];
      if (error) { slot.errors++; return { model, error }; }
      const gate = gateCheck(text, c);
      slot.total++; if (gate.passed) slot.pass++;
      return { model, text, gate };
    });
    collected.push({ case: c, answers });
    console.log('done');
  }

  // ---- results.json ----
  writeFileSync(resolve(__dirname, `results${SUF}.json`),
    JSON.stringify({ generatedFor: 'faithlock-bible-companion', models, gates: perModelGate, collected }, null, 2));

  // ---- report.md (human-judge friendly) ----
  const lines = [];
  lines.push('# Bible Companion — Model Bake-off (raw outputs for human judging)\n');
  lines.push(`Models: ${models.map((m) => `\`${m}\``).join(' · ')}\n`);
  lines.push('## Deterministic gate summary\n');
  lines.push('| Model | Gates passed | API errors |');
  lines.push('|---|---|---|');
  for (const m of models) lines.push(`| ${m} | ${perModelGate[m].pass}/${perModelGate[m].total} | ${perModelGate[m].errors} |`);
  lines.push('\n---\n');
  for (const { case: c, answers } of collected) {
    lines.push(`## ${c.id} · ${c.category} · _${c.bible_version}_\n`);
    lines.push(`**User:** ${mdEscape(c.user_input)}\n`);
    lines.push(`**Expected:** ${mdEscape(c.expected_behavior)}  `);
    lines.push(`**Must include:** ${(c.must_include || []).join(' | ') || '—'}  `);
    lines.push(`**Must avoid:** ${(c.must_avoid || []).join(' | ') || '—'}\n`);
    for (const a of answers) {
      if (a.error) { lines.push(`### ${a.model}\n\n\`API error: ${a.error}\`\n`); continue; }
      const flag = a.gate.passed ? '✅ gate pass' : `❌ gate fail (${[...a.gate.missing.map((x) => `missing:${x}`), ...a.gate.violated.map((x) => `violated:${x}`)].join(', ')})`;
      lines.push(`### ${a.model} — ${flag}\n`);
      lines.push('> ' + mdEscape(a.text).split('\n').join('\n> ') + '\n');
    }
    lines.push('\n---\n');
  }
  writeFileSync(resolve(__dirname, `report${SUF}.md`), lines.join('\n'));

  console.log('\n════════ GATE SUMMARY ════════');
  console.table(Object.fromEntries(models.map((m) => [m, `${perModelGate[m].pass}/${perModelGate[m].total} (err ${perModelGate[m].errors})`])));
  console.log('\n▸ report.md  → side-by-side answers for human judging');
  console.log('▸ results.json → structured detail');
})();
