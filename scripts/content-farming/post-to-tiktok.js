#!/usr/bin/env node
/**
 * Post a TikTok slideshow via TikTok Official Content Posting API v2.
 * Supports multiple accounts — posts to every account in config.tiktok.accounts.
 *
 * Flow per account:
 *   1. Refresh access_token if expired
 *   2. POST /v2/post/publish/content/init/ → PULL_FROM_URL mode
 *   3. TikTok pulls images from R2 CDN URLs
 *
 * Usage:
 *   node post-to-tiktok.js --config <config.json> --dir <slides-dir> --caption "caption" [--account "name"]
 *
 * Config expected:
 * {
 *   "tiktok": {
 *     "client_key": "...",
 *     "client_secret": "...",
 *     "accounts": {
 *       "marina-faith": { "access_token": "...", "refresh_token": "...", "expires_at": "..." },
 *       "marc-faith":   { "access_token": "...", "refresh_token": "...", "expires_at": "..." }
 *     }
 *   }
 * }
 */

'use strict';

const fs    = require('fs');
const path  = require('path');
const https = require('https');
const { uploadSlides } = require('./upload-to-r2');

// ─── CLI ──────────────────────────────────────────────────────────────────────
const args = process.argv.slice(2);
function getArg(n) { const i = args.indexOf(`--${n}`); return i !== -1 ? args[i + 1] : null; }

const configPath    = getArg('config');
const dir           = getArg('dir');
const caption       = getArg('caption');
const title         = getArg('title') || '';
const targetAccount = getArg('account'); // optional — post to one specific account only
const EACH_SLIDE    = args.includes('--each'); // post each slide as a separate TikTok post

const urlsArg = getArg('urls');
if (!configPath || (!dir && !urlsArg) || !caption) {
  console.error('Usage: node post-to-tiktok.js --config <config.json> [--dir <dir> | --urls "url1,url2"] --caption "text" [--title "text"] [--account "name"] [--each]');
  process.exit(1);
}

const config = JSON.parse(fs.readFileSync(configPath, 'utf-8'));

if (!config.tiktok?.client_key || !config.tiktok?.client_secret) {
  console.error('❌ Missing tiktok.client_key or tiktok.client_secret in config');
  process.exit(1);
}

const accounts = config.tiktok?.accounts || {};
const accountNames = targetAccount ? [targetAccount] : Object.keys(accounts);

if (accountNames.length === 0) {
  console.error('❌ No TikTok accounts found in config.tiktok.accounts — run auth-tiktok.js first');
  process.exit(1);
}

const CLIENT_KEY    = config.tiktok.client_key;
const CLIENT_SECRET = config.tiktok.client_secret;

// ─── HTTP helpers ─────────────────────────────────────────────────────────────
function httpsRequest(options, body = null) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, res => {
      let data = '';
      res.on('data', c => data += c);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, body: JSON.parse(data) }); }
        catch { resolve({ status: res.statusCode, body: data }); }
      });
    });
    req.on('error', reject);
    if (body) req.write(body);
    req.end();
  });
}

// ─── Token refresh ─────────────────────────────────────────────────────────────
async function refreshToken(accountName, accountData) {
  console.log(`   🔄 [${accountName}] Token expiré — refresh...`);
  const payload = new URLSearchParams({
    client_key:    CLIENT_KEY,
    client_secret: CLIENT_SECRET,
    grant_type:    'refresh_token',
    refresh_token: accountData.refresh_token,
  }).toString();

  const res = await httpsRequest({
    hostname: 'open.tiktokapis.com',
    path:     '/v2/oauth/token/',
    method:   'POST',
    headers: {
      'Content-Type':   'application/x-www-form-urlencoded',
      'Content-Length': Buffer.byteLength(payload),
    }
  }, payload);

  if (res.status !== 200 || res.body.error) {
    throw new Error(`Token refresh failed: ${JSON.stringify(res.body)}`);
  }

  const { access_token, refresh_token, expires_in } = res.body;
  const expiresAt = new Date(Date.now() + expires_in * 1000).toISOString();

  // Save refreshed tokens
  config.tiktok.accounts[accountName] = {
    ...accountData,
    access_token,
    refresh_token,
    expires_at: expiresAt,
  };
  fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
  console.log(`   ✅ [${accountName}] Token rafraîchi, expire le ${new Date(expiresAt).toLocaleString()}`);
  return access_token;
}

// ─── Get valid access token (auto-refresh if expired) ────────────────────────
async function getAccessToken(accountName) {
  const accountData = config.tiktok.accounts[accountName];
  if (!accountData) throw new Error(`Account "${accountName}" not found in config.tiktok.accounts — run auth-tiktok.js`);
  if (!accountData.access_token) throw new Error(`No access_token for "${accountName}" — run auth-tiktok.js`);

  const isExpired = accountData.expires_at && new Date(accountData.expires_at) < new Date(Date.now() + 60000);
  if (isExpired) return await refreshToken(accountName, accountData);
  return accountData.access_token;
}

// ─── Post one photo post to one account (single URL or carousel) ─────────────
async function postOneToAccount(accountName, photoUrls, slideTitle) {
  const accessToken = await getAccessToken(accountName);

  // TikTok requires ≥2 images for photo carousel — duplicate if single
  const images = photoUrls.length === 1 ? [photoUrls[0], photoUrls[0]] : photoUrls;

  const initPayload = JSON.stringify({
    post_info: {
      title:           slideTitle || caption,
      description:     caption,
      privacy_level:   'SELF_ONLY',
      disable_duet:    false,
      disable_stitch:  false,
      disable_comment: false,
    },
    source_info: {
      source:            'PULL_FROM_URL',
      photo_cover_index: 1,
      photo_images:      images,
    },
    post_mode:  'MEDIA_UPLOAD',
    media_type: 'PHOTO',
  });

  const initRes = await httpsRequest({
    hostname: 'open.tiktokapis.com',
    path:     '/v2/post/publish/content/init/',
    method:   'POST',
    headers: {
      'Authorization':  `Bearer ${accessToken}`,
      'Content-Type':   'application/json; charset=UTF-8',
      'Content-Length': Buffer.byteLength(initPayload),
    }
  }, initPayload);

  if (initRes.status !== 200 || initRes.body?.error?.code !== 'ok') {
    throw new Error(`Init failed (${initRes.status}): ${JSON.stringify(initRes.body)}`);
  }

  const publishId = initRes.body.data?.publish_id;
  try {
    const ct = require('./cost-tracker');
    ct.logPost({ format: path.basename(dir || '').split('_')[0] || 'unknown', account: accountName });
  } catch(_) {}

  return { publish_id: publishId };
}

// ─── Post slideshow or each slide individually ───────────────────────────────
async function postToAccount(accountName, slideFiles) {
  if (EACH_SLIDE) {
    // Post each slide as its own separate TikTok post
    console.log(`\n📤 [${accountName}] Posting ${slideFiles.length} individual slides...`);
    const results = [];
    for (let i = 0; i < slideFiles.length; i++) {
      const slideTitle = `${title || caption} (${i + 1}/${slideFiles.length})`;
      console.log(`   📸 Slide ${i + 1}/${slideFiles.length}...`);
      const r = await postOneToAccount(accountName, [slideFiles[i]], slideTitle);
      console.log(`   ✅ Slide ${i + 1} → publish_id: ${r.publish_id}`);
      results.push(r);
      // Small delay between posts
      if (i < slideFiles.length - 1) await new Promise(res => setTimeout(res, 2000));
    }
    return { slides: results };
  } else {
    // Post all slides as one carousel
    console.log(`\n📤 [${accountName}] Posting ${slideFiles.length}-slide carousel...`);
    const result = await postOneToAccount(accountName, slideFiles, title || caption);
    console.log(`   ✅ [${accountName}] Draft créé ! publish_id: ${result.publish_id}`);
    return result;
  }
}

// ─── Main ─────────────────────────────────────────────────────────────────────
(async () => {
  // Support --urls "url1,url2,url3" OR --dir for local files
  let slideFiles = [];

  if (urlsArg) {
    // URL mode — pass URLs directly to TikTok PULL_FROM_URL
    slideFiles = urlsArg.split(',').map(u => u.trim()).filter(Boolean);
    if (slideFiles.length < 2) { console.error('❌ Minimum 2 URLs requises'); process.exit(1); }
    slideFiles.forEach((u, i) => console.log(`  ✅ slide${i + 1}: ${u}`));
  } else if (dir) {
    // Local dir mode — convert PNG→JPEG + upload to R2 → get public URLs
    console.log('\n📦 Upload des slides vers R2...');
    try {
      slideFiles = await uploadSlides(dir, config);
    } catch (err) {
      console.error(`❌ Upload R2 échoué : ${err.message}`);
      process.exit(1);
    }
  } else {
    console.error('❌ --dir ou --urls requis');
    process.exit(1);
  }

  console.log(`\n📋 Comptes cibles : ${accountNames.join(', ')}`);

  const results = {};
  let failures  = 0;

  for (const accountName of accountNames) {
    try {
      results[accountName] = await postToAccount(accountName, slideFiles);
    } catch (err) {
      console.error(`   ❌ [${accountName}] Échec : ${err.message}`);
      results[accountName] = { error: err.message };
      failures++;
    }
  }

  // Save metadata (only if --dir provided)
  if (dir) {
    const metaPath = path.join(dir, 'meta.json');
    fs.writeFileSync(metaPath, JSON.stringify({
      caption, title,
      slides: slideFiles.length,
      postedAt: new Date().toISOString(),
      accounts: results,
    }, null, 2));
    console.log(`\n📋 Metadata → ${metaPath}`);
  }

  if (failures > 0) {
    console.error(`\n⚠️  ${failures}/${accountNames.length} compte(s) ont échoué.`);
    process.exit(1);
  }

  console.log(`\n✅ Posté sur ${accountNames.length} compte(s) : ${accountNames.join(', ')}`);
  console.log('🎵 TikTok app → ajoute un son → publie !');
})();
