#!/usr/bin/env node
/**
 * Faith Lock — AI Content Generator
 * Generates a fresh TikTok slideshow post for a given format using GPT-4o.
 *
 * Usage:
 *   node generate-content.js --config <config.json> --format <F01|F02|...> --out <post.json> [--dry-run]
 */

'use strict';

const fs    = require('fs');
const path  = require('path');
const https = require('https');

const args = process.argv.slice(2);
function getArg(n) { const i = args.indexOf(`--${n}`); return i !== -1 ? args[i + 1] : null; }
const isDryRun   = args.includes('--dry-run');
const configPath = getArg('config');
const formatId   = getArg('format');
const outPath    = getArg('out');

if (!configPath || !formatId || !outPath) {
  console.error('Usage: node generate-content.js --config <config.json> --format <F01> --out <post.json> [--dry-run]');
  process.exit(1);
}

const config    = JSON.parse(fs.readFileSync(configPath, 'utf-8'));
const configDir = path.dirname(configPath);

// ─── Load format rules ────────────────────────────────────────────────────────
const registryPath = path.join(configDir, 'content-formats.json');
const registry     = JSON.parse(fs.readFileSync(registryPath, 'utf-8'));
const fmt          = registry.faithLockFormats[formatId];

if (!fmt) { console.error(`❌ Format "${formatId}" introuvable.`); process.exit(1); }
if (!fmt.enabled) { console.error(`❌ Format "${formatId}" désactivé.`); process.exit(1); }

// ─── Load post history ────────────────────────────────────────────────────────
const historyPath = path.join(configDir, 'post-history.json');
let usedTopics = [];
if (fs.existsSync(historyPath)) {
  const history = JSON.parse(fs.readFileSync(historyPath, 'utf-8'));
  usedTopics = (history.posted || [])
    .filter(p => p.format === formatId)
    .map(p => p.topic)
    .filter(Boolean)
    .slice(-20);
}

// ─── Load hook performance ────────────────────────────────────────────────────
const perfPath = path.join(configDir, 'hook-performance.json');
let hookInsights = '';
if (fs.existsSync(perfPath)) {
  const perf = JSON.parse(fs.readFileSync(perfPath, 'utf-8'));
  const fmtPerf = perf[formatId];
  if (fmtPerf?.topHooks?.length) {
    hookInsights = `\nTop performing hooks for this format:\n${fmtPerf.topHooks.slice(0, 5).map(h => `- "${h.text}" (${h.views} views)`).join('\n')}`;
  }
}

// ─── Build GPT prompt ─────────────────────────────────────────────────────────
const appDesc = `App: ${config.app?.name} — ${config.app?.description}
Target audience: ${config.app?.audience}
Strategy: No mention of the app in slides. Bio does the commercial work.`;

const formatDesc = `Format: ${formatId} — ${fmt.name}
Mechanic: ${fmt.mechanic}
Intent: ${fmt.intent}
Structure: ${fmt.structure || ''}
Copywriting rules:\n${(fmt.copywritingRules || []).map(r => `- ${r}`).join('\n')}
Example topics: ${(fmt.exampleTopics || []).join(' / ')}`;

const avoidSection = usedTopics.length
  ? `\nAlready posted topics for this format — DO NOT repeat:\n${usedTopics.map(t => `- ${t}`).join('\n')}`
  : '';

const prompt = `You are a viral TikTok content creator for a Christian audience. Generate ONE fresh slideshow post for Faith Lock.

${appDesc}

${formatDesc}
${hookInsights}
${avoidSection}

OUTPUT REQUIREMENTS:
- Generate exactly ONE post in valid JSON
- topic: short descriptive title
- slide1.hookText: scroll-stopping opening sentence (5-13 words max)
- slide1.gridTheme: description of 4-image 2x2 grid for hook slide (if format uses grid)
- slides2to5: array of 3-4 middle slides, each with scene + text (5-13 words) + styleNote
- slide6: divine/spiritual finale ending with (Amen)
- caption: punchy 1-line TikTok caption with 1 emoji
- hashtags: 6-8 hashtags space-separated, mix of big and niche (#christian #faith #bible #jesus #christianitytiktok #worshipgod #prayertime #dailyprayers)
- All text in ENGLISH

Respond with ONLY valid JSON:
{
  "id": "GEN_${Date.now()}",
  "topic": "<topic title>",
  "caption": "<caption with emoji>",
  "hashtags": "#tag1 #tag2 ...",
  "slide1": {
    "hookText": "<hook>",
    "gridTheme": "<4-image grid description>",
    "visualStyle": "<visual style>"
  },
  "slides2to5": [
    { "scene": "<image prompt>", "text": "<text>", "styleNote": "<style>" }
  ],
  "slide6": {
    "scene": "<image prompt>",
    "text": "<finale text (Amen)>",
    "styleNote": "<divine style>"
  }
}`;

// ─── Call GPT-4o ──────────────────────────────────────────────────────────────
async function callGPT(prompt) {
  const apiKey = config.imageGen?.apiKey;
  if (!apiKey) throw new Error('Missing imageGen.apiKey in config');

  const payload = JSON.stringify({
    model: 'gpt-4o',
    messages: [{ role: 'user', content: prompt }],
    temperature: 0.9,
    max_tokens: 2000,
    response_format: { type: 'json_object' }
  });

  return new Promise((resolve, reject) => {
    const req = https.request({
      hostname: 'api.openai.com',
      path: '/v1/chat/completions',
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload)
      }
    }, res => {
      let data = '';
      res.on('data', c => data += c);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          if (parsed.error) { reject(new Error(parsed.error.message)); return; }
          const content = parsed.choices?.[0]?.message?.content;
          if (!content) { reject(new Error('No content in GPT response')); return; }
          resolve(JSON.parse(content));
        } catch (e) { reject(e); }
      });
    });
    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

// ─── Main ──────────────────────────────────────────────────────────────────────
(async () => {
  console.log(`\n🧠 Generating content for format ${formatId} — ${fmt.name}...`);

  if (isDryRun) {
    const mock = {
      id: `GEN_${Date.now()}`,
      topic: `[DRY RUN] ${fmt.name}`,
      caption: 'Dry run. 🙏',
      hashtags: '#christian #faith #jesus',
      slide1: { hookText: 'Dry run hook.', gridTheme: 'Mock grid', visualStyle: 'mock' },
      slides2to5: [
        { scene: 'Mock scene', text: 'Mock slide 2.', styleNote: 'mock' },
        { scene: 'Mock scene', text: 'Mock slide 3.', styleNote: 'mock' },
        { scene: 'Mock scene', text: 'Mock slide 4.', styleNote: 'mock' }
      ],
      slide6: { scene: 'Mock finale', text: 'Dry run finale. (Amen)', styleNote: 'divine mock' }
    };
    fs.writeFileSync(outPath, JSON.stringify(mock, null, 2));
    console.log(`✅ [DRY RUN] Mock post written to: ${outPath}`);
    return;
  }

  try {
    const post = await callGPT(prompt);
    post.id = `GEN_${Date.now()}`;
    post.generatedFor = formatId;
    post.generatedAt  = new Date().toISOString();

    if (!post.slide1 || !post.slides2to5 || !post.slide6 || !post.topic) {
      throw new Error('GPT response missing required fields');
    }

    fs.writeFileSync(outPath, JSON.stringify(post, null, 2));
    console.log(`✅ Content generated: "${post.topic}"`);
    console.log(`   Slides: 1 hook + ${post.slides2to5.length} middle + 1 finale = ${2 + post.slides2to5.length} total`);
    console.log(`   Saved to: ${outPath.replace(configDir + '/', '')}`);
  } catch (err) {
    console.error(`❌ Content generation failed: ${err.message}`);
    process.exit(1);
  }
})();
