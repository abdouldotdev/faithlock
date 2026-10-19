#!/usr/bin/env node
/**
 * Faith Lock — Auto-poster unifié
 *
 * Flow :
 *   1. Lit content-formats.json → slots actifs = formats enabled (F01, F02…)
 *   2. Choisit le format le moins utilisé cette semaine (rotation équitable)
 *      + alterne les mécaniques (share-driven / ragebait)
 *   3. generate-content.js → GPT-4o génère un post frais pour ce format
 *   4. generate-slides.js  → OpenAI Images génère les slides
 *   5. post-to-tiktok.js   → Upload-Post envoie le slideshow en draft schedulé
 *   6. Enregistre dans post-history.json
 *
 * Usage:
 *   node auto-post.js --config <config.json> [--dry-run] [--format <F01>]
 */

const fs   = require('fs');
const path = require('path');
const https = require('https');
const { execSync } = require('child_process');

// ─── CLI ──────────────────────────────────────────────────────────────────────
const args = process.argv.slice(2);
function getArg(n) { const i = args.indexOf(`--${n}`); return i !== -1 ? args[i + 1] : null; }
const isDryRun   = args.includes('--dry-run');
const forcedFmt  = getArg('format');
const configPath = getArg('config');

if (!configPath) {
  console.error('Usage: node auto-post.js --config <config.json> [--dry-run] [--format <F01>]');
  process.exit(1);
}

const config    = JSON.parse(fs.readFileSync(configPath, 'utf-8'));
const configDir = path.dirname(configPath);
const scriptDir = __dirname;

// ─── Load format registry ─────────────────────────────────────────────────────
const registryPath = path.join(configDir, 'content-formats.json');
if (!fs.existsSync(registryPath)) {
  console.error(`❌ content-formats.json introuvable dans ${configDir}`);
  process.exit(1);
}
const registry  = JSON.parse(fs.readFileSync(registryPath, 'utf-8'));
const faithFmts = registry.faithLockFormats;

// ─── Build active slots (1 slot = 1 enabled format) ──────────────────────────
const activeSlots = Object.entries(faithFmts)
  .filter(([id, fmt]) => !id.startsWith('_') && fmt.enabled)
  .map(([id, fmt]) => ({
    id,
    name:             fmt.name,
    mechanic:         fmt.mechanic,
    defaultVisualFmt: fmt.defaultVisualFormat || 'purifiee',
  }));

if (activeSlots.length === 0) {
  console.error('❌ Aucun format actif dans content-formats.json.');
  process.exit(1);
}

console.log(`\n📋 Formats actifs (${activeSlots.length}) : ${activeSlots.map(s => s.id).join(', ')}`);

// ─── History ──────────────────────────────────────────────────────────────────
const historyPath = path.join(configDir, 'post-history.json');
let history = { posted: [], lastPostedAt: null, weekStartedAt: null };
if (fs.existsSync(historyPath)) history = JSON.parse(fs.readFileSync(historyPath, 'utf-8'));
if (!history.weekStartedAt) history.weekStartedAt = new Date().toISOString();

// ─── Format selection ─────────────────────────────────────────────────────────
function getNextSlot() {
  if (forcedFmt) {
    const s = activeSlots.find(s => s.id === forcedFmt);
    if (!s) {
      console.error(`❌ Format "${forcedFmt}" inconnu. Actifs : ${activeSlots.map(s => s.id).join(', ')}`);
      process.exit(1);
    }
    return s;
  }

  // Count posts this week per format
  const weekStart = new Date(history.weekStartedAt);
  const thisWeek  = history.posted.filter(p => new Date(p.postedAt) >= weekStart);
  const counts    = {};
  for (const s of activeSlots) counts[s.id] = 0;
  thisWeek.forEach(p => { if (counts[p.format] !== undefined) counts[p.format]++; });

  // Alternate mechanics: never two same mechanic in a row
  const lastMechanic = history.posted.slice(-1)[0]?.mechanic;
  const preferOther  = lastMechanic
    ? activeSlots.filter(s => s.mechanic !== lastMechanic)
    : activeSlots;
  const pool = preferOther.length > 0 ? preferOther : activeSlots;

  // Pick least used in pool
  return pool.reduce((min, s) => (counts[s.id] < counts[min.id] ? s : min), pool[0]);
}

// ─── Next scheduled date ──────────────────────────────────────────────────────
function getNextScheduledDate() {
  const slots    = config.posting?.schedule || ['07:30', '16:30', '21:00'];
  const timezone = config.posting?.timezone || 'UTC';
  const now      = new Date();
  const todayStr = now.toLocaleDateString('en-CA', { timeZone: timezone });

  // Current time in target timezone as HH:MM
  const nowTimeStr = now.toLocaleTimeString('en-GB', { timeZone: timezone, hour: '2-digit', minute: '2-digit' });

  const usedToday = history.posted
    .filter(p => p.scheduledFor && p.scheduledFor.startsWith(todayStr))
    .map(p => p.scheduledFor.substring(11, 16));

  // Pick first slot that is: (a) not already used AND (b) still in the future (with 5 min buffer)
  const nextSlot = slots.find(s => !usedToday.includes(s) && s > nowTimeStr);

  if (nextSlot) return `${todayStr}T${nextSlot}:00`;

  // All today's future slots are taken or passed → use tomorrow
  const tomorrow    = new Date(now);
  tomorrow.setDate(tomorrow.getDate() + 1);
  const tomorrowStr = tomorrow.toLocaleDateString('en-CA', { timeZone: timezone });

  // Pick first tomorrow slot not already in history
  const usedTomorrow = history.posted
    .filter(p => p.scheduledFor && p.scheduledFor.startsWith(tomorrowStr))
    .map(p => p.scheduledFor.substring(11, 16));
  const tomorrowSlot = slots.find(s => !usedTomorrow.includes(s)) || slots[0];

  console.log(`   ℹ️  Slots d'aujourd'hui passés → demain (${tomorrowStr}T${tomorrowSlot}:00)`);
  return `${tomorrowStr}T${tomorrowSlot}:00`;
}

// ─── Weekly performance check ─────────────────────────────────────────────────
async function fetchApifyPerformance() {
  const apifyToken = config.apify?.apiKey;
  if (!apifyToken) { console.log('⚠️  Pas de clé Apify — skip.'); return null; }
  const handle = config.app?.tiktokHandle;
  if (!handle) { console.log('⚠️  config.app.tiktokHandle manquant — skip.'); return null; }

  console.log(`\n📊 Apify — Scrape @${handle}...`);
  const runPayload = JSON.stringify({ profiles: [handle], resultsPerPage: 50, shouldDownloadCovers: false });

  const runData = await new Promise((resolve, reject) => {
    const req = https.request({
      hostname: 'api.apify.com',
      path: '/v2/acts/clockworks~tiktok-scraper/runs?token=' + apifyToken,
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(runPayload) }
    }, res => { let d = ''; res.on('data', c => d += c); res.on('end', () => resolve(JSON.parse(d))); });
    req.on('error', reject);
    req.write(runPayload); req.end();
  });

  const runId = runData?.data?.id;
  if (!runId) { console.error('❌ Apify run failed.'); return null; }
  console.log(`   Run ID: ${runId} — attente 60s...`);
  await new Promise(r => setTimeout(r, 60000));

  const runInfo = await new Promise((resolve, reject) => {
    https.get(`https://api.apify.com/v2/actor-runs/${runId}?token=${apifyToken}`, res => {
      let d = ''; res.on('data', c => d += c); res.on('end', () => resolve(JSON.parse(d)));
    }).on('error', reject);
  });

  const datasetId = runInfo?.data?.defaultDatasetId;
  if (!datasetId) return null;

  return new Promise((resolve, reject) => {
    https.get(`https://api.apify.com/v2/datasets/${datasetId}/items?token=${apifyToken}`, res => {
      let d = ''; res.on('data', c => d += c); res.on('end', () => resolve(JSON.parse(d)));
    }).on('error', reject);
  });
}

function isNewWeek() {
  return (new Date() - new Date(history.weekStartedAt)) >= 7 * 24 * 3600 * 1000;
}

// ─── Post one slot ────────────────────────────────────────────────────────────
async function postOneSlot(slotIndex, totalSlots, accountOverride = null) {
  const slot      = getNextSlot();
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').substring(0, 19);
  const slidesDir = path.join(configDir, 'generated-slides', `${slot.id}_${timestamp}`);
  const postFile  = path.join(configDir, 'generated-slides', `${slot.id}_${timestamp}_post.json`);

  console.log(`\n${'─'.repeat(60)}`);
  console.log(`🎯 Post ${slotIndex}/${totalSlots} — ${slot.id} (${slot.name})`);
  console.log(`   Visuel  : ${slot.defaultVisualFmt}`);

  fs.mkdirSync(path.dirname(postFile), { recursive: true });
  fs.mkdirSync(slidesDir, { recursive: true });

  const dryArg        = isDryRun ? '--dry-run' : '';
  const contentScript = path.join(scriptDir, 'generate-content.js');
  const genScript     = path.join(scriptDir, 'generate-slides.js');
  const postScript    = path.join(scriptDir, 'post-to-tiktok.js');

  // Step 1 — Generate content
  console.log('\n🧠 Génération du contenu (GPT-4o)...');
  try {
    execSync(
      `node "${contentScript}" --config "${configPath}" --format "${slot.id}" --out "${postFile}" ${dryArg}`,
      { stdio: 'inherit' }
    );
  } catch {
    console.error(`❌ Contenu échoué pour ${slot.id} — slot ignoré.`);
    return false;
  }

  const post = JSON.parse(fs.readFileSync(postFile, 'utf-8'));

  // Add CTA to finale slide — per account
  const FIXED_HASHTAGS = '#christianitytiktok #worshipgod #prayertime #dailyprayers #psalms';
  const CTA_BY_ACCOUNT = {
    'marina-faith': 'build strong faith now\n(bio)',
    'marc-faith':   'build strong faith with\nFaithlock (on appstore)',
  };
  const CTA_TEXT = CTA_BY_ACCOUNT[accountOverride] || 'build strong faith now (bio)';
  post.slide6.cta = CTA_TEXT;
  // Append fixed hashtags to caption
  post.caption = `${post.caption || ''}\n${post.hashtags || ''}\n${FIXED_HASHTAGS}`.trim();
  fs.writeFileSync(postFile, JSON.stringify(post, null, 2));

  // Step 2 — Generate slides
  console.log('\n📸 Génération des slides (OpenAI Images)...');
  try {
    execSync(
      `node "${genScript}" --config "${configPath}" --post-file "${postFile}" --format "${slot.defaultVisualFmt}" --out "${slidesDir}" ${dryArg}`,
      { stdio: 'inherit' }
    );
  } catch {
    console.error(`❌ Slides échouées pour ${slot.id} — slot ignoré.`);
    return false;
  }

  if (isDryRun) {
    console.log(`\n✅ [DRY RUN] ${slot.id} — "${post.topic}"`);
    return true;
  }

  // Step 3 — Post to TikTok
  console.log('\n📤 Post vers TikTok...');
  const scheduledDate = getNextScheduledDate();
  console.log(`   ⏰ Schedulé : ${scheduledDate} (${config.posting?.timezone || 'UTC'})`);

  try {
    execSync(
      `node "${postScript}" --config "${configPath}" --dir "${slidesDir}" --caption "${(post.caption || '').replace(/"/g, '\\"')}" --title "${(post.topic || '').replace(/"/g, '\\"')}" --schedule "${scheduledDate}"`,
      { stdio: 'inherit' }
    );
  } catch {
    console.error(`❌ Post TikTok échoué pour ${slot.id}.`);
    return false;
  }

  // Save to history
  history.posted.push({
    postId:       post.id,
    topic:        post.topic,
    format:       slot.id,
    mechanic:     slot.mechanic,
    postedAt:     new Date().toISOString(),
    scheduledFor: scheduledDate,
    slidesDir,
  });
  history.lastPostedAt = new Date().toISOString();
  fs.writeFileSync(historyPath, JSON.stringify(history, null, 2));

  console.log(`\n✅ ${slot.id} envoyé — schedulé pour ${scheduledDate}`);
  return true;
}

// ─── Main ──────────────────────────────────────────────────────────────────────
(async () => {
  // Weekly review
  if (isNewWeek()) {
    console.log('\n📅 Nouvelle semaine — revue de performance...');
    await fetchApifyPerformance();
    history.weekStartedAt = new Date().toISOString();
    fs.writeFileSync(historyPath, JSON.stringify(history, null, 2));
    console.log('🔄 Nouvelle semaine démarrée.\n');
  }

  // How many slots to post — default: all daily slots (3), override with --slots N
  const slotsPerRun   = parseInt(getArg('slots') || String(config.posting?.schedule?.length || 3), 10);
  const forcedCount   = forcedFmt ? 1 : slotsPerRun;
  const forcedAccount = getArg('account'); // optional: run for one account only

  // Accounts to post to — each gets UNIQUE content generated separately
  const allAccounts = config.uploadpost?.users || (config.uploadpost?.user ? [config.uploadpost.user] : []);
  const accounts    = forcedAccount ? [forcedAccount] : allAccounts;

  const totalPosts = forcedCount * accounts.length;
  console.log(`\n🚀 Faith Lock — Daily run`);
  console.log(`   Comptes  : ${accounts.join(', ')}`);
  console.log(`   Posts    : ${forcedCount} par compte × ${accounts.length} comptes = ${totalPosts} posts uniques`);
  if (isDryRun) console.log('   MODE : DRY RUN');

  let success = 0;
  let postIndex = 0;
  const totalPosts2 = forcedCount * accounts.length;

  for (const account of accounts) {
    console.log(`\n${'━'.repeat(60)}`);
    console.log(`👤 Compte : ${account}`);
    for (let i = 0; i < forcedCount; i++) {
      const ok = await postOneSlot(i + 1, forcedCount, account);
      if (ok) success++;
      postIndex++;
      // 30s delay between posts (skip after last post)
      if (postIndex < totalPosts2) {
        console.log(`\n⏳ Pause 30s avant le prochain post...`);
        await new Promise(r => setTimeout(r, 30000));
      }
    }
  }

  // Final summary
  console.log(`\n${'═'.repeat(60)}`);
  console.log(`📊 Run terminé — ${success}/${totalPosts} posts envoyés`);

  const weekStart = new Date(history.weekStartedAt);
  const thisWeek  = history.posted.filter(p => new Date(p.postedAt) >= weekStart);
  const counts    = {};
  for (const s of activeSlots) counts[s.id] = 0;
  thisWeek.forEach(p => { if (counts[p.format] !== undefined) counts[p.format]++; });

  console.log(`\n📊 Cette semaine :`);
  for (const s of activeSlots) {
    console.log(`   ${s.id.padEnd(5)} ${s.name.padEnd(35)} : ${counts[s.id]} posts`);
  }
  if (!isDryRun) console.log('\n🎵 TikTok inbox → ajoute un son tendance → change privacy → publie !');
})();
