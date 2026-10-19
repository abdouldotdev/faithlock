/**
 * add-text-overlay.js
 * Overlays bold white text (black stroke) on an image — @purifiee_ style.
 * Usage: addTextOverlay(imagePath, text, options) → overwrites imagePath
 */

'use strict';

const sharp  = require('sharp');
const path   = require('path');
const fs     = require('fs');

// ─── Text wrapper ──────────────────────────────────────────────────────────────
function wrapText(text, maxWidth, fontSize, charWidthRatio = 0.58) {
  const maxCharsPerLine = Math.floor(maxWidth / (fontSize * charWidthRatio));
  const lines = [];

  // Support explicit \n line breaks
  const paragraphs = text.split('\n');
  for (const para of paragraphs) {
    const words = para.split(' ');
    let current = '';
    for (const word of words) {
      const test = current ? `${current} ${word}` : word;
      if (test.length <= maxCharsPerLine) {
        current = test;
      } else {
        if (current) lines.push(current);
        current = word;
      }
    }
    if (current) lines.push(current);
  }
  return lines;
}

function escapeXml(str) {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

// ─── SVG builder ──────────────────────────────────────────────────────────────
function buildSvgOverlay(lines, imgWidth, imgHeight, opts = {}) {
  const {
    fontSize    = 80,
    lineSpacing = 1.25,
    position    = 'center',
    customY     = null,
    color       = 'white',
    strokeColor = 'black',
    strokeWidth = 5,
    shadow      = true,
    fontWeight  = 'bold',
  } = opts;

  const lineHeight = fontSize * lineSpacing;
  const totalTextH = lines.length * lineHeight;

  let startY;
  if (position === 'top') {
    startY = fontSize * 2;
  } else if (position === 'bottom') {
    startY = imgHeight - totalTextH - fontSize;
  } else if (position === 'lower-center') {
    startY = imgHeight * 0.65 - totalTextH / 2;
  } else if (position === 'custom-top') {
    startY = customY !== null ? customY + fontSize : fontSize * 2;
  } else {
    // center
    startY = (imgHeight - totalTextH) / 2 + fontSize;
  }

  const cx = imgWidth / 2;

  const textEls = lines.map((line, i) => {
    const y = startY + i * lineHeight;
    return `
    <text
      x="${cx}" y="${y}"
      text-anchor="middle"
      font-family="Impact, Arial Black, 'Helvetica Neue', sans-serif"
      font-size="${fontSize}"
      font-weight="${fontWeight}"
      letter-spacing="1"
      fill="${color}"
      stroke="${strokeColor}"
      stroke-width="${strokeWidth}"
      stroke-linejoin="round"
      paint-order="stroke fill"
    >${escapeXml(line)}</text>`;
  }).join('\n');

  const filterDef = shadow ? `
  <defs>
    <filter id="sh" x="-5%" y="-5%" width="110%" height="110%">
      <feDropShadow dx="0" dy="3" stdDeviation="4" flood-color="rgba(0,0,0,0.7)"/>
    </filter>
  </defs>` : '';

  const groupFilter = shadow ? 'filter="url(#sh)"' : '';

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${imgWidth}" height="${imgHeight}">
  ${filterDef}
  <g ${groupFilter}>
    ${textEls}
  </g>
</svg>`;
}

// ─── Main export ──────────────────────────────────────────────────────────────
async function addTextOverlay(imagePath, text, opts = {}) {
  if (!text || !text.trim()) return;

  const meta   = await sharp(imagePath).metadata();
  const width  = meta.width;
  const height = meta.height;

  const fontSizeRatio = opts.fontSizeRatio || 0.075;
  const fontSize = opts.fontSize || Math.round(Math.min(width, height) * fontSizeRatio);

  const lines = wrapText(text, width * 0.85, fontSize);
  const svg   = buildSvgOverlay(lines, width, height, { fontSize, ...opts });

  const tmp = imagePath + '.tmp.png';

  await sharp(imagePath)
    .composite([{ input: Buffer.from(svg), top: 0, left: 0 }])
    .png()
    .toFile(tmp);

  fs.renameSync(tmp, imagePath);
}

module.exports = { addTextOverlay, wrapText, buildSvgOverlay };
