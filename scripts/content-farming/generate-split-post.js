#!/usr/bin/env node
/**
 * Faith Lock — Format SPLIT (Jesus top + Grid 2x2 bottom)
 *
 * Layout par slide (1024x1792) :
 *   - Top 44% (1024x784)  : Jésus — MÊME image sur tous les slides
 *   - Bottom 56% (1024x1008) : Grille 2x2 — 4 images (512x504) différentes par slide
 *   - Texte : centré sur la ligne de séparation (y≈784)
 *
 * 3 slides + 1 amen slide = 4 slides total
 *
 * Usage:
 *   node generate-split-post.js --config <config.json> --out <dir>
 *     --hook "Jesus said He came to bring division, not peace."
 *     --slide2-text "Not peace. His exact words. Matt. 10:34"
 *     --slide3-text "He came to make you choose. (Amen)"
 *     --jesus-prompt "..."
 *     --slide1-grid "..."
 *     --slide2-grid "..."
 *     --slide3-grid "..."
 */

'use strict';

const fs    = require('fs');
const path  = require('path');
const https = require('https');
const http  = require('http');
const sharp = require('sharp');
const { addTextOverlay } = require('./add-text-overlay');

// ─── CLI ──────────────────────────────────────────────────────────────────────
const args = process.argv.slice(2);
function getArg(n) { const i = args.indexOf(`--${n}`); return i !== -1 ? args[i + 1] : null; }
const DRY_RUN = args.includes('--dry-run');

const configPath = getArg('config');
const outDir     = getArg('out') || './split-post';

if (!configPath) { console.error('Usage: node generate-split-post.js --config <config.json> --out <dir>'); process.exit(1); }

const config        = JSON.parse(fs.readFileSync(configPath, 'utf-8'));
const WAVESPEED_KEY = config.wavespeed?.apiKey;
if (!WAVESPEED_KEY && !DRY_RUN) { console.error('❌ Missing wavespeed.apiKey in config'); process.exit(1); }

fs.mkdirSync(outDir, { recursive: true });
fs.mkdirSync(path.join(outDir, 'raw'), { recursive: true });

// ─── Dimensions ───────────────────────────────────────────────────────────────
const W       = 1024;
const H       = 1792;
const TOP_H   = 896;   // Jesus top portion (50%)
const BOT_H   = H - TOP_H; // 896 — bottom section
const CELL_W  = W / 2;     // 512 — left / right
const CELL_H  = BOT_H;     // 896 — full height (2 cells side by side, not 2x2)

// ─── WaveSpeed generation ─────────────────────────────────────────────────────
async function generateWaveSpeed(prompt, width, height, label) {
  console.log(`\n🎨 Génération: ${label} (${width}x${height})...`);
  console.log(`   ${prompt.substring(0, 90)}...`);

  if (DRY_RUN) {
    console.log('   [DRY RUN]');
    return null;
  }

  const payload = JSON.stringify({
    prompt,
    width,
    height,
    num_inference_steps: 28,
    guidance_scale: 3.5,
    seed: Math.floor(Math.random() * 1e9),
    enable_safety_checker: true
  });

  // POST to WaveSpeed
  const taskId = await new Promise((resolve, reject) => {
    const req = https.request({
      hostname: 'api.wavespeed.ai',
      path: '/api/v3/wavespeed-ai/flux-dev-ultra-fast',
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${WAVESPEED_KEY}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload)
      }
    }, res => {
      let data = '';
      res.on('data', c => data += c);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          const id = parsed?.data?.id;
          if (!id) { reject(new Error(`No task ID: ${data.substring(0, 200)}`)); return; }
          resolve(id);
        } catch(e) { reject(e); }
      });
    });
    req.on('error', reject);
    req.write(payload);
    req.end();
  });

  console.log(`   ⏳ Polling (task ${taskId.substring(0, 8)}...)...`);

  // Poll for result
  for (let poll = 1; poll <= 60; poll++) {
    await new Promise(r => setTimeout(r, 3000));
    const result = await new Promise((resolve, reject) => {
      https.get({
        hostname: 'api.wavespeed.ai',
        path: `/api/v2/predictions/${taskId}/result`,
        headers: { 'Authorization': `Bearer ${WAVESPEED_KEY}` }
      }, res => {
        let data = '';
        res.on('data', c => data += c);
        res.on('end', () => {
          try { resolve(JSON.parse(data)); }
          catch(e) { reject(e); }
        });
      }).on('error', reject);
    });

    const status = result?.data?.status;
    const outputs = result?.data?.outputs;

    if (status === 'completed' && outputs?.length) {
      console.log(`   ✅ Prêt (poll ${poll})`);
      return outputs[0];
    }
    if (status === 'failed') throw new Error(`WaveSpeed failed: ${JSON.stringify(result?.data?.error)}`);
    if (poll % 5 === 0) console.log(`   ↻ Poll ${poll}/30 — ${status}...`);
  }
  throw new Error('WaveSpeed timeout after 30 polls');
}

async function downloadToFile(url, dest) {
  return new Promise((resolve, reject) => {
    const proto = url.startsWith('https') ? https : http;
    const file = fs.createWriteStream(dest);
    proto.get(url, res => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        file.close(); fs.unlinkSync(dest);
        return downloadToFile(res.headers.location, dest).then(resolve).catch(reject);
      }
      res.pipe(file);
      file.on('finish', () => file.close(resolve));
    }).on('error', err => { try { fs.unlinkSync(dest); } catch{} reject(err); });
  });
}

async function downloadOrPlaceholder(url, dest, w, h) {
  if (!url) {
    // DRY RUN placeholder
    await sharp({ create: { width: w, height: h, channels: 3, background: { r: 30, g: 30, b: 50 } } })
      .png().toFile(dest);
    return;
  }
  await downloadToFile(url, dest);
}

// ─── Composite: Jesus top + 2-cell bottom (left | right) ────────────────────
async function buildSlide(jesusPath, gridPaths, outputPath) {
  // Resize Jesus image to exact top dimensions
  const jesusResized = await sharp(jesusPath)
    .resize(W, TOP_H, { fit: 'cover', position: 'top' })
    .png().toBuffer();

  // Resize each bottom cell (left and right)
  const cells = await Promise.all(gridPaths.map(p =>
    sharp(p).resize(CELL_W, CELL_H, { fit: 'cover' }).png().toBuffer()
  ));

  // Build bottom row: 2 cells side by side
  const gridBuf = await sharp({
    create: { width: W, height: BOT_H, channels: 3, background: { r: 0, g: 0, b: 0 } }
  }).composite([
    { input: cells[0], top: 0, left: 0      },  // Left
    { input: cells[1], top: 0, left: CELL_W },  // Right
  ]).png().toBuffer();

  // Stack: Jesus (top) + 2 cells (bottom)
  await sharp({
    create: { width: W, height: H, channels: 3, background: { r: 0, g: 0, b: 0 } }
  }).composite([
    { input: jesusResized, top: 0,     left: 0 },
    { input: gridBuf,      top: TOP_H, left: 0 },
  ]).png().toFile(outputPath);
}

// ─── DA Rules (from @purifiee_ analysis) ────────────────────────────────────
// Palette: Or + blanc lumineux + rayons pour Jésus/divin
// Style: 4 VARIATIONS du même sujet (même scène, angles différents)
// Qualité: Photoréaliste cinématique, Midjourney style
// ─────────────────────────────────────────────────────────────────────────────

// ─── Post content definition ──────────────────────────────────────────────────
const POST = {
  caption: "He didn't come to make everyone comfortable. Matt. 10:34 🔥",
  hashtags: "#jesus #bible #christian #faith #christianitytiktok #bibleverses #jesusisking #godsword",
  title: "Jesus said He came to bring division, not peace.",

  jesusPrompt: "Dramatic digital painting, cinematic sacred biblical art, Jesus Christ from behind standing on a rocky hill, white flowing robe, arms slightly open, massive golden divine light rays bursting from behind him splitting dark storm clouds, golden heavenly glow, dramatic chiaroscuro, painterly render, epic divine composition, no text, no logos",

  slides: [
    {
      text: "Jesus said He came to bring division, not peace.",
      leftPrompt:  "Dramatic digital painting, cinematic sacred biblical art, Caravaggio chiaroscuro, pitch black background, single warm torch light, an old father in ancient draped robe gripping his adult son by the collar with fury, son's face breaking in tears reaching back toward his family, raw emotional confrontation, 1st century Palestine, painterly render, no text, no logos",
      rightPrompt: "Dramatic digital painting, cinematic sacred biblical art, Caravaggio chiaroscuro, ancient stone doorway glowing golden from within, a young man in simple ancient tunic standing alone outside the door at night, one hand on the stone wall, head bowed in grief, shut out by his own family, single golden light from the door crack, dark night, painterly render, no text, no logos"
    },
    {
      text: "Not peace. His exact words. Matt. 10:34",
      leftPrompt:  "Dramatic digital painting, cinematic sacred biblical art, Caravaggio chiaroscuro, pitch black background, two adult brothers in ancient draped robes standing back to back arms crossed refusing to look at each other, dramatic single torch light from the side revealing pain and anger on their faces, 1st century Palestine, raw family division, painterly render, no text, no logos",
      rightPrompt: "Dramatic digital painting, cinematic sacred biblical art, Caravaggio chiaroscuro, dark background, a weeping mother in ancient robes being pulled in two directions by her two sons each grabbing one of her arms, her face twisted in absolute agony, three figures dramatically lit by single torch light, extreme pain and division, 1st century Palestine, painterly render, no text, no logos"
    },
    {
      text: "He came to make you choose. (Amen)",
      leftPrompt:  "Dramatic digital painting, cinematic sacred biblical art, Caravaggio chiaroscuro, a man in ancient tunic standing at a fork in the road at dusk, one arm reaching back toward his family standing in deep shadow, the other arm reaching forward toward a blinding golden divine light, face torn between the two worlds, 1st century Palestine landscape, painterly render, no text, no logos",
      rightPrompt: "Dramatic digital painting, cinematic sacred biblical art, Caravaggio chiaroscuro, a lone man in ancient tunic on his knees on a rocky hill, both arms outstretched wide toward heaven, head thrown back with tears streaming, completely surrendering to God, blazing golden divine light pouring from above onto him, dark sky behind, extreme emotion, painterly render, no text, no logos"
    }
  ]
};

// ─── Main ─────────────────────────────────────────────────────────────────────
(async () => {
  console.log('\n🚀 Faith Lock — Format SPLIT (Jesus top + Grid 2x2 bottom)');
  console.log(`   Post   : ${POST.title}`);
  console.log(`   Output : ${outDir}`);
  console.log(`   Slides : 3 + 1 amen = 4 total\n`);

  // 1. Generate Jesus image (shared across all slides)
  const jesusUrl  = await generateWaveSpeed(POST.jesusPrompt, W, TOP_H, 'Jésus (top)');
  const jesusPath = path.join(outDir, 'raw', 'jesus.png');
  await downloadOrPlaceholder(jesusUrl, jesusPath, W, TOP_H);
  console.log(`   ✅ jesus.png saved`);

  // 2. Generate + composite each slide
  const slidePaths = [];

  for (let si = 0; si < POST.slides.length; si++) {
    const slide    = POST.slides[si];
    const slideNum = si + 1;
    console.log(`\n── Slide ${slideNum}/3 ──`);

    // Generate 2 images — Left (leftPrompt) and Right (rightPrompt)
    const gridUrls = [];
    const panels = [
      { key: 'leftPrompt',  label: 'Left'  },
      { key: 'rightPrompt', label: 'Right' },
    ];
    for (const panel of panels) {
      const prompt = slide[panel.key];
      const url    = await generateWaveSpeed(prompt, CELL_W, CELL_H, `Grid ${slideNum}-${panel.label}`);
      const p      = path.join(outDir, 'raw', `slide${slideNum}_grid_${panel.label.toLowerCase()}.png`);
      await downloadOrPlaceholder(url, p, CELL_W, CELL_H);
      gridUrls.push(p);
    }

    // Composite Jesus + grid
    const slidePath = path.join(outDir, `slide${slideNum}.png`);
    await buildSlide(jesusPath, gridUrls, slidePath);
    console.log(`   ✅ slide${slideNum}.png composited`);

    // Add text overlay on dividing line
    if (!DRY_RUN) {
      await addTextOverlay(slidePath, slide.text, {
        position:      'custom-top',
        customY:       TOP_H - 60,  // text starts just above the grid
        fontSizeRatio: 0.048,
        strokeWidth:   4,
        shadow:        true,
        fontWeight:    'bold',
      });
      console.log(`   ✍️  "${slide.text.substring(0, 60)}"`);
    }

    slidePaths.push(slidePath);
  }

  // 3. Amen slide — copy slide3 background (raw), add amen text
  const amenPath = path.join(outDir, 'slide4.png');
  fs.copyFileSync(slidePaths[slidePaths.length - 1], amenPath);

  if (!DRY_RUN) {
    const { addTextOverlay: atOverlay } = require('./add-text-overlay');
    await atOverlay(amenPath, "Still alive today.\nDon't scroll without saying Amen", {
      position: 'custom-top',
      customY: Math.round(H * 0.08),
      strokeWidth: 4,
      fontSizeRatio: 0.052,
      shadow: true,
    });

    // App Store card — skip gracefully if not found
    const cardSrc = path.join(path.dirname(configPath), 'assets', 'faithlock-icon.jpg');
    if (fs.existsSync(cardSrc)) {
      const meta  = await sharp(cardSrc).metadata();
      const cardW = Math.round(W * 0.46);
      const cardH = Math.round(cardW * meta.height / meta.width);
      const cardTop = Math.round(H * 0.60);

      const cardBuf = await sharp(cardSrc).resize(cardW, cardH).png().toBuffer();
      const tmp     = amenPath + '.tmp.png';
      await sharp(amenPath).composite([{ input: cardBuf, top: cardTop, left: Math.round((W - cardW) / 2) }]).png().toFile(tmp);
      fs.renameSync(tmp, amenPath);

      const ctaY = cardTop + cardH + Math.round(H * 0.045);
      await atOverlay(amenPath, 'blocks your apps until you pray', {
        position: 'custom-top', customY: ctaY,
        strokeWidth: 1, fontSizeRatio: 0.026, shadow: true, fontWeight: '400',
      });
      console.log('\n   🖼️  App Store card overlaid');
    } else {
      console.log('\n   ⚠️  faithlock-icon.jpg not found — amen slide without card');
    }
  }

  slidePaths.push(amenPath);
  console.log(`\n   ✅ slide4.png (amen)`);

  // Save metadata
  fs.writeFileSync(path.join(outDir, 'meta.json'), JSON.stringify({
    title: POST.title,
    caption: POST.caption,
    hashtags: POST.hashtags,
    slides: slidePaths.map(p => path.basename(p)),
    generatedAt: new Date().toISOString()
  }, null, 2));

  console.log(`\n✅ 4 slides générées dans : ${outDir}`);
  console.log(`\n📋 Prochaine étape :`);
  console.log(`   node post-to-tiktok.js --config "${configPath}" --dir "${outDir}" --caption "${POST.caption}" --title "${POST.title}" --account marina-faith`);
})();
