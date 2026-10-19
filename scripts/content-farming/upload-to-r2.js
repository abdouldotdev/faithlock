#!/usr/bin/env node
/**
 * upload-to-r2.js
 *
 * Converts slide images (PNG/any format) → JPEG (max 1080x1920)
 * then uploads to Cloudflare R2 and returns public URLs.
 *
 * Config expected:
 * {
 *   "r2": {
 *     "accountId": "...",
 *     "accessKeyId": "...",
 *     "secretAccessKey": "...",
 *     "bucket": "autoviral",
 *     "publicUrl": "https://cdn.auto-viral.com"
 *   }
 * }
 */

'use strict';

const fs   = require('fs');
const path = require('path');
const sharp = require('sharp');
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');

const MAX_WIDTH  = 1080;
const MAX_HEIGHT = 1920;
const JPEG_QUALITY = 92;

// ─── Init R2 client ───────────────────────────────────────────────────────────
function getR2Client(config) {
  const r2 = config.r2;
  if (!r2?.accountId || !r2?.accessKeyId || !r2?.secretAccessKey) {
    throw new Error('Missing r2.accountId / r2.accessKeyId / r2.secretAccessKey in config');
  }
  return new S3Client({
    region: 'auto',
    endpoint: `https://${r2.accountId}.r2.cloudflarestorage.com`,
    credentials: {
      accessKeyId:     r2.accessKeyId,
      secretAccessKey: r2.secretAccessKey,
    },
  });
}

// ─── Convert + resize one image → JPEG buffer ────────────────────────────────
async function toJpeg(filePath) {
  const img = sharp(filePath);
  const meta = await img.metadata();

  // Resize only if exceeds max dimensions
  const needsResize = meta.width > MAX_WIDTH || meta.height > MAX_HEIGHT;
  const pipeline = needsResize
    ? img.resize(MAX_WIDTH, MAX_HEIGHT, { fit: 'inside', withoutEnlargement: true })
    : img;

  return pipeline.jpeg({ quality: JPEG_QUALITY }).toBuffer();
}

// ─── Upload one buffer to R2 ──────────────────────────────────────────────────
async function uploadToR2(client, bucket, key, buffer) {
  await client.send(new PutObjectCommand({
    Bucket:      bucket,
    Key:         key,
    Body:        buffer,
    ContentType: 'image/jpeg',
    CacheControl: 'public, max-age=86400',
  }));
}

// ─── Main export: upload all slides from a dir, return public URLs ────────────
async function uploadSlides(slidesDir, config) {
  const r2     = config.r2;
  const bucket = r2?.bucket;
  const baseUrl = (r2?.publicUrl || '').replace(/\/$/, '');

  if (!bucket)  throw new Error('Missing r2.bucket in config');
  if (!baseUrl) throw new Error('Missing r2.publicUrl in config');

  const client = getR2Client(config);
  const urls   = [];
  const runId  = path.basename(slidesDir);

  for (let i = 1; i <= 10; i++) {
    // Accept .png or .jpg/.jpeg
    const candidates = [
      path.join(slidesDir, `slide${i}.png`),
      path.join(slidesDir, `slide${i}.jpg`),
      path.join(slidesDir, `slide${i}.jpeg`),
    ];
    const filePath = candidates.find(p => fs.existsSync(p));
    if (!filePath) {
      if (i < 3) throw new Error(`slide${i} manquant (minimum 2 requis)`);
      break;
    }

    console.log(`   🔄 slide${i} — conversion JPEG + upload R2...`);
    const jpegBuffer = await toJpeg(filePath);
    const key        = `slides/${runId}/slide${i}.jpg`;

    await uploadToR2(client, bucket, key, jpegBuffer);

    const url = `${baseUrl}/${key}`;
    urls.push(url);
    console.log(`   ✅ slide${i} → ${url}`);
  }

  return urls;
}

module.exports = { uploadSlides };
