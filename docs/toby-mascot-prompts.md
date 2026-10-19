# Toby Mascot — Image-Generation Prompts (animated garden helper)

Toby is the app's lion-cub companion: a humble little **helper** who tends the garden
alongside the user. He is **never** a deity — no halo, no glow, no robe. (Theology note:
the "Lion of Judah" is a title of Christ; Toby is only a created friend who waters the
plant with you.)

These prompts produce **three on-model stills** that are then **animated** (subtle looping
motion). They drive the garden's emotional feedback:

| State | When it shows | File |
|---|---|---|
| Idle — standing with Bible + watering can | default / garden at rest | `toby_idle.(png\|gif\|webp)` |
| Watering & smiling | user prayed / tended today, plant growing | `toby_watering.(png\|gif\|webp)` |
| Sad | plant neglected, health dropping / streak broken | `toby_sad.(png\|gif\|webp)` |

---

## 0. Character Lock  ⚠️ prepend to EVERY Toby prompt

Keeps all three frames the SAME character (matches `assets/mascot/new/` reference).

```
Toby — a cute chubby baby lion cub mascot, soft 3D Pixar / storybook render, plush fuzzy
fur, smooth rounded chunky friendly forms. Warm golden-amber fur (#F2B705) with a slightly
lighter cream muzzle, belly and inner ears; a small soft rounded mane tuft on top of the
head; little rounded ears with peach inner; big glossy dark-brown friendly eyes with soft
highlights; rosy pink cheek blush; tiny black nose; gentle warm closed-or-open smile; small
peach paw pads; a slim tail with a tuft. Wears ONE small gold heart-shaped locket pendant on
a thin chain. Wholesome, gentle, huggable, innocent. IDENTICAL proportions, fur color, eyes
and pendant in every image. Humble little helper — NOT a deity, no halo, no glow, no robe.
```

## 0.1 Global style + framing (append to every prompt)

```
Cozy storybook mood, warm cohesive palette: terracotta #D68A4E, sage green #8FA67A,
cream #FBF3E2, soft warm-brown #3D2B1F. Soft even studio lighting, soft contact shadow only,
full body, single centered character, facing the viewer, clean transparent background (PNG
alpha), high resolution, square 1:1 framing, feet on a consistent baseline so frames swap
cleanly. Children's-book illustration quality.
```

## 0.1b Background — pick ONE (use the SAME for all 3 states)

**Option A — no background (cutout → PNG alpha):**
```
isolated single subject, plain flat pure-white background for easy cutout, no scenery,
no floor, no cast shadow, nothing behind the character.
```
Then remove the background (remove.bg / chroma-key) for a transparent PNG.

**Option B — cozy cream background `#FBF3E2` (recommended for animation):**
```
solid flat warm cream background, exact color #FBF3E2 (cozy app canvas), perfectly uniform,
no gradient, no scenery, no props, no shadows on the ground, single centered character.
```
Matches the app canvas exactly, so the animated GIF/WebP looks transparent in-app with NO
alpha needed (image-to-video tools can't output alpha). Keep the same cream for all 3 states.

## 0.2 Global negative prompt

```
halo, glowing aura, divine, god, jesus, angel, robe, crown of light, scary, gritty, dark,
horror, realistic photo, human, multiple characters, extra limbs, deformed paws, text, logo,
watermark, UI, busy background, scenery, room, landscape, sky, floor, ground, grass, wall,
furniture, props, ground plane, cast shadow, harsh shadows, gradient backdrop, vignette,
border, frame, clutter, low quality, blurry, duplicate pendant, weapon
```

---

## 1. Toby — Idle (standing with his Bible and watering can)

```
[Character Lock] Toby standing upright and calm on two feet, content and welcoming. He gently
holds a small chunky storybook Bible — warm brown leather cover with a simple understated gold
cross — tucked in one arm against his chest, and a small cozy watering can in the other paw
(terracotta #D68A4E body with a sage-green #8FA67A handle and spout). Soft gentle smile,
relaxed, looking warmly at the viewer, ready to help in the garden.
[Global style + framing]
Negative: [Global negative prompt]
```

**Animate (loop ~2.5s, seamless):** slow breathing bob up/down (~3px), occasional eye blink,
soft tail sway, ears twitch once. Calm, alive-but-still.

---

## 2. Toby — Watering & smiling (plant is thriving)

```
[Character Lock] Toby happily tilting his small watering can (terracotta #D68A4E body, sage
#8FA67A handle and spout) to pour a soft gentle arc of blue-teal water droplets onto a small
potted green sprout in a terracotta pot beside him. Bright joyful open smile, eyes warm and
delighted, one ear perked, leaning forward eagerly, tail up. His little Bible rests closed on
the ground/soil next to the pot. Cheerful, caring, wholesome.
[Global style + framing]
Negative: [Global negative prompt]
```

**Animate (loop ~2.5s, seamless):** watering can tips and the droplet arc falls in a repeating
stream; tiny splash ring + leaf wiggle on the sprout; happy bounce on the cub; tail wag; sparkle
or two rising. Joyful, energetic.

---

## 3. Toby — Sad (plant neglected)

```
[Character Lock] Toby looking sad and worried, ears drooped down, big eyes downcast and a
little watery with one small tear, mouth in a soft frown, shoulders slumped. He holds the
empty watering can low at his side (tipped, nothing coming out) and looks toward a small
wilted, drooping, browning plant in a terracotta pot beside him. His little Bible is held
loosely or rests closed nearby. Gentle, tender, pleading-but-hopeful — sad, never scary.
[Global style + framing]
Negative: [Global negative prompt]
```

**Animate (loop ~3s, slow, seamless):** slow heavy sway, ears droop a touch more then settle,
one slow blink, a single tear slides and fades, the wilted plant droops slightly. Quiet, downcast.

---

## 3bis. Animation prompts (image → video / loop)

Feed these as the **motion** prompt on top of the still from §1–§3. Appearance comes
from the input image — describe only movement. Tools: **Kling AI** (best character
consistency), **Runway Gen-4** (Motion Brush to animate just the can), **Pika** / **Hailuo**.
For true transparency use **Rive**; otherwise render on a flat removable background
(white/green) → chroma-key → export looping WebP/GIF (~512px).

**Idle (watering can sways):**
```
Subtle idle loop. Toby sways gently as he breathes; he lightly swings the little watering
can back and forth in his paw; his tail sways slowly; he blinks once and his ears twitch.
Minimal motion, he stays in place, identical appearance, no morphing, no extra limbs.
Static camera, no zoom, no pan, background unchanged. Seamless ~3s loop, cozy and gentle.
```
> Alt idle: replace the can-swing line with "he lifts the watering can, glances at it and
> smiles, a small head nod" — or a small one-paw wave.

**Watering & smiling:**
```
Toby happily tips the watering can forward and a soft stream of blue-teal water droplets
pours out toward the plant; he does a little joyful bounce, tail wagging, ears perked, eyes
bright; a tiny sparkle rises. Same character, identical appearance, no morphing. Static
camera, no zoom or pan, background unchanged. Seamless ~2.5s loop, cheerful.
```

**Sad:**
```
Toby looks sad: his ears slowly droop, shoulders slump, he gives one slow blink and a single
small tear slides down and fades; he sways gently and the empty watering can hangs low; the
wilted plant droops a little. Same character, identical appearance, no morphing. Static
camera, no zoom or pan, background unchanged. Seamless ~3s loop, tender and quiet.
```

---

## 4. Production notes

- **Consistency first:** generate Prompt 1, lock the look, then feed that exact image as a
  style/character reference (img-to-img / reference image) for Prompts 2 and 3 so fur color,
  eyes and pendant stay identical. Keep the **same canvas size and feet baseline** for all three.
- **Tools:** stills → Midjourney / DALL·E / Firefly (with the reference image). Animation →
  image-to-video (Runway Gen-3, Kling, Pika) for the subtle loop, OR rig the still in **Rive**
  for crisp, tiny-file loops. Existing mascot assets are GIFs, so simplest path is
  image-to-video → export looping **GIF / WebP**; consider Rive/Lottie if you want smaller files.
- **Delivery:** transparent background, square, anchored at the feet; export at 2x
  (≈512–1024px) then downscale in-app. Suggested names:
  `assets/mascot/toby_idle.gif`, `toby_watering.gif`, `toby_sad.gif`
  (add to `pubspec.yaml` assets, same folder pattern as the current `judah_*.gif`).
- **In-app mapping:** idle = default; watering = `progress` rising / prayed today;
  sad = `health` low or streak broken. Same trigger logic the garden already tracks
  (`GardenController.progress` / `health`, streak from stats).
```
