#!/usr/bin/env node
'use strict';

const fs    = require('fs');
const path  = require('path');
const https = require('https');
const http  = require('http');
const sharp = require('sharp');
const { addTextOverlay } = require('./add-text-overlay');

const args = process.argv.slice(2);
function getArg(n) { const i = args.indexOf(`--${n}`); return i !== -1 ? args[i + 1] : null; }
const DRY_RUN = args.includes('--dry-run');

const configPath = getArg('config');
const outDir     = getArg('out') || './split-post-p2';

if (!configPath) { console.error('Usage: node generate-split-post-p2.js --config <config.json> --out <dir>'); process.exit(1); }

const config        = JSON.parse(fs.readFileSync(configPath, 'utf-8'));
const WAVESPEED_KEY = config.wavespeed?.apiKey;
if (!WAVESPEED_KEY && !DRY_RUN) { console.error('❌ Missing wavespeed.apiKey in config'); process.exit(1); }

fs.mkdirSync(outDir, { recursive: true });
fs.mkdirSync(path.join(outDir, 'raw'), { recursive: true });

const W      = 1024;
const H      = 1792;
const TOP_H  = 896;        // 50% top
const BOT_H  = H - TOP_H; // 896 bottom
const CELL_W = W / 2;     // 512 left/right
const CELL_H = BOT_H;     // 896 full-height cells (2 side by side)

async function generateWaveSpeed(prompt, width, height, label) {
  console.log(`\n🎨 ${label} (${width}x${height})...`);
  if (DRY_RUN) { console.log('   [DRY RUN]'); return null; }

  const payload = JSON.stringify({
    prompt, width, height,
    num_inference_steps: 28, guidance_scale: 3.5,
    seed: Math.floor(Math.random() * 1e9),
    enable_safety_checker: true
  });

  const taskId = await new Promise((resolve, reject) => {
    const req = https.request({
      hostname: 'api.wavespeed.ai',
      path: '/api/v3/wavespeed-ai/flux-dev-ultra-fast',
      method: 'POST',
      headers: { 'Authorization': `Bearer ${WAVESPEED_KEY}`, 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(payload) }
    }, res => {
      let data = '';
      res.on('data', c => data += c);
      res.on('end', () => {
        const parsed = JSON.parse(data);
        const id = parsed?.data?.id;
        if (!id) { reject(new Error(`No task ID: ${data.substring(0,200)}`)); return; }
        resolve(id);
      });
    });
    req.on('error', reject);
    req.write(payload);
    req.end();
  });

  console.log(`   ⏳ Polling (${taskId.substring(0,8)}...)...`);
  for (let poll = 1; poll <= 60; poll++) {
    await new Promise(r => setTimeout(r, 3000));
    const result = await new Promise((resolve, reject) => {
      https.get({ hostname: 'api.wavespeed.ai', path: `/api/v2/predictions/${taskId}/result`, headers: { 'Authorization': `Bearer ${WAVESPEED_KEY}` } }, res => {
        let data = '';
        res.on('data', c => data += c);
        res.on('end', () => resolve(JSON.parse(data)));
      }).on('error', reject);
    });
    const status = result?.data?.status;
    const outputs = result?.data?.outputs;
    if (status === 'completed' && outputs?.length) { console.log(`   ✅ Prêt (poll ${poll})`); return outputs[0]; }
    if (status === 'failed') throw new Error(`WaveSpeed failed`);
    if (poll % 5 === 0) console.log(`   ↻ Poll ${poll}/60 — ${status}...`);
  }
  throw new Error('WaveSpeed timeout');
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
    await sharp({ create: { width: w, height: h, channels: 3, background: { r: 30, g: 30, b: 50 } } }).png().toFile(dest);
    return;
  }
  await downloadToFile(url, dest);
}

async function buildSlide(jesusPath, gridPaths, outputPath) {
  const jesusResized = await sharp(jesusPath).resize(W, TOP_H, { fit: 'cover', position: 'top' }).png().toBuffer();
  const cells = await Promise.all(gridPaths.map(p => sharp(p).resize(CELL_W, CELL_H, { fit: 'cover' }).png().toBuffer()));
  // 2 cells side by side (left | right)
  const gridBuf = await sharp({ create: { width: W, height: BOT_H, channels: 3, background: { r: 0, g: 0, b: 0 } } })
    .composite([
      { input: cells[0], top: 0, left: 0      },  // Left
      { input: cells[1], top: 0, left: CELL_W },  // Right
    ]).png().toBuffer();
  await sharp({ create: { width: W, height: H, channels: 3, background: { r: 0, g: 0, b: 0 } } })
    .composite([{ input: jesusResized, top: 0, left: 0 }, { input: gridBuf, top: TOP_H, left: 0 }])
    .png().toFile(outputPath);
}

// ─── POST 2: Jesus made a whip and drove people out of the temple ─────────────
// DA Rules: photorealistic cinematic, golden palette, 4 variations of same scene
const POST = {
  caption: "He didn't just flip tables. He made a weapon first. John 2:15 🔥",
  hashtags: "#jesus #bible #christian #faith #christianitytiktok #bibleverses #jesusisking #godsword",
  title: "Jesus made a whip and drove people out of the temple.",

  jesusPrompt: "Baroque oil painting with visible brushstrokes of Jesus Christ standing inside an ancient golden Jerusalem temple, holding a handmade rope whip raised in his right hand, white linen robe flowing, holy fury on his face, smoke and dust in the air, divine golden fire light behind him, 1st century Palestine setting, Caravaggio dramatic chiaroscuro, impasto texture, rich warm palette, sacred masterpiece. No text, no logos.",

  slides: [
    {
      text: "Jesus made a whip and drove people out of the temple.",
      leftPrompt:  "Baroque oil painting with visible brushstrokes, 1st century Jerusalem temple interior, corrupt merchants at ancient stone tables counting gold coins, dove sellers in cages, animal traders arguing, greed and chaos desecrating the sacred space, dramatic Caravaggio torchlight, dark shadows, impasto texture, rich warm palette. No text, no logos.",
      rightPrompt: "Baroque oil painting with visible brushstrokes, 1st century Palestine, Jesus in white linen robe crouching on the temple floor, hands twisting and braiding a rope whip with intense holy fury, jaw clenched, divine golden light illuminating his face from above, dark dramatic Caravaggio chiaroscuro, impasto texture, sacred masterpiece. No text, no logos."
    },
    {
      text: "He didn't ask them to leave. He made a whip. John 2:15",
      leftPrompt:  "Baroque oil painting with visible brushstrokes, Jesus swinging a rope whip inside the Jerusalem temple, tables violently overturning, gold coins exploding into the air, white doves bursting from broken cages in a storm of feathers, extreme holy chaos, divine golden fire light, Caravaggio dramatic chiaroscuro, impasto texture, masterpiece. No text, no logos.",
      rightPrompt: "Baroque oil painting with visible brushstrokes, 1st century merchants and money changers running in absolute terror from the temple, stumbling over each other, gold coins scattering, robes flying, faces twisted in fear, golden divine light flooding the space behind them, Caravaggio chiaroscuro, impasto texture, dramatic masterpiece. No text, no logos."
    },
    {
      text: "Gentle Jesus made a weapon. Read your Bible. (Amen)",
      leftPrompt:  "Baroque oil painting with visible brushstrokes, an ancient handmade rope whip lying coiled on the stone temple floor, golden coins scattered around it, overturned tables in the background, the evidence of divine judgment, dramatic Caravaggio torchlight, dark shadows, impasto texture, sacred and powerful. No text, no logos.",
      rightPrompt: "Baroque oil painting with visible brushstrokes, the empty purified Jerusalem temple after Jesus drove everyone out, overturned stone tables, scattered coins on marble floor, a single white dove soaring freely in golden divine light streaming through tall stone windows, peaceful and holy, Caravaggio chiaroscuro, impasto texture. No text, no logos."
    }
  ]
};

(async () => {
  console.log('\n🚀 Faith Lock — Post 2 — Jesus & the whip');
  console.log(`   Output : ${outDir}\n`);

  const jesusUrl  = await generateWaveSpeed(POST.jesusPrompt, W, TOP_H, 'Jésus (top)');
  const jesusPath = path.join(outDir, 'raw', 'jesus.png');
  await downloadOrPlaceholder(jesusUrl, jesusPath, W, TOP_H);
  console.log(`   ✅ jesus.png`);

  const slidePaths = [];

  for (let si = 0; si < POST.slides.length; si++) {
    const slide    = POST.slides[si];
    const slideNum = si + 1;
    console.log(`\n── Slide ${slideNum}/3 ──`);

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

    const slidePath = path.join(outDir, `slide${slideNum}.png`);
    await buildSlide(jesusPath, gridUrls, slidePath);
    console.log(`   ✅ slide${slideNum}.png`);

    if (!DRY_RUN) {
      await addTextOverlay(slidePath, slide.text, {
        position: 'custom-top', customY: TOP_H - 60,
        fontSizeRatio: 0.048, strokeWidth: 4, shadow: true, fontWeight: 'bold',
      });
      console.log(`   ✍️  "${slide.text.substring(0, 60)}"`);
    }
    slidePaths.push(slidePath);
  }

  // Amen slide
  const amenPath = path.join(outDir, 'slide4.png');
  fs.copyFileSync(slidePaths[2], amenPath);
  if (!DRY_RUN) {
    await addTextOverlay(amenPath, "Still alive today.\nDon't scroll without saying Amen", {
      position: 'custom-top', customY: Math.round(H * 0.08),
      strokeWidth: 4, fontSizeRatio: 0.052, shadow: true,
    });
    const cardSrc = path.join(path.dirname(configPath), 'assets', 'faithlock-icon.jpg');
    if (fs.existsSync(cardSrc)) {
      const meta  = await sharp(cardSrc).metadata();
      const cardW = Math.round(W * 0.46);
      const cardH = Math.round(cardW * meta.height / meta.width);
      const cardTop = Math.round(H * 0.60);
      const cardBuf = await sharp(cardSrc).resize(cardW, cardH).png().toBuffer();
      const tmp = amenPath + '.tmp.png';
      await sharp(amenPath).composite([{ input: cardBuf, top: cardTop, left: Math.round((W - cardW) / 2) }]).png().toFile(tmp);
      fs.renameSync(tmp, amenPath);
      await addTextOverlay(amenPath, 'blocks your apps until you pray', {
        position: 'custom-top', customY: cardTop + cardH + Math.round(H * 0.045),
        strokeWidth: 1, fontSizeRatio: 0.026, shadow: true, fontWeight: '400',
      });
    }
  }
  slidePaths.push(amenPath);

  fs.writeFileSync(path.join(outDir, 'meta.json'), JSON.stringify({
    title: POST.title, caption: POST.caption, hashtags: POST.hashtags,
    slides: slidePaths.map(p => path.basename(p)),
    generatedAt: new Date().toISOString()
  }, null, 2));

  console.log(`\n✅ 4 slides → ${outDir}`);
})();
