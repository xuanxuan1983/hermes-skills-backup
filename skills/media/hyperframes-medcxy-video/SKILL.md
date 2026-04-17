---
name: hyperframes-medcxy-video
description: Build a brand-intro video composition for Medcxy using Hyperframes HTML — multi-scene calm blur crossfade transitions, real brand assets, character IP images, and strict skill compliance.
category: media
---

# Hyperframes Medcxy Video — Build & Ship

## Context

Medcxy™ (medagent.filldmy.com) is an AI companion workbench for medical aesthetics. Brand assets live in `/Users/xuan/Documents/项目/Medcxy/` and `/Users/xuan/Desktop/medcxy-video/`. Output: `index.html` in the project folder.

## Brand Identity (from website)

| Role | Hex | Use |
|------|-----|-----|
| Accent | `#C4704B` | Dividers, CTA, avatar circles |
| Primary | `#1A1A1A` | Headlines, names |
| Secondary | `#6A6A6A` | Body text, descriptions |
| Muted | `#AAAAAA` → `#666666` | Labels, captions (must pass 4.5:1 WCAG AA) |
| Background | `#FFFFFF` | All scenes |

| Font | Use |
|------|-----|
| Playfair Display | English display titles |
| Noto Serif SC | Chinese text, companion names |
| Inter | English UI labels, body |

## IP Character Images

Source: `/Users/xuan/Documents/项目/Medcxy/`
- Base portraits: `ip_douzai_base_v2.png`, `ip_douding_base.png`, `ip_douya_base_v2.png` (2048×2048 RGB)
- Expressive variants: `ip_douzai_v5_happy.png`, `ip_douding_v4_shy.png`, `ip_douya_v2_writing.png`

Copy to project: `char_douzai.png`, `char_douding.png`, `char_douya.png`, `char_douzai_exp.png`, `char_douding_exp.png`, `char_douya_exp.png`

## Brand Logo

User-provided file: `/Users/xuan/Downloads/showcase_void_tm.png` (2752×1536 RGBA, ~8MB).
**ALWAYS compress before use** — run:

```python
from PIL import Image
img = Image.open('brand-logo.png').convert('RGB')
img.save('brand-logo.webp', 'WEBP', quality=88)  # ~90KB vs 8MB PNG
# optionally resize
w, h = img.size
ratio = min(800/w, 1.0)
img = img.resize((int(w*ratio), int(h*ratio)), Image.LANCZOS)
img.save('brand-logo.webp', 'WEBP', quality=88)
```

Never use the original PNG in `<img src>` — it won't load in-browser.

## Non-Negotiable Skill Rules (Hyperframes)

These are not suggestions — violations break rendering:

1. **Scene 1 visible by default** — `#scene1` has NO `opacity:0`. Only scenes 2+ get `opacity:0`.
2. **No exit animations before transitions** — Non-final scenes must NOT use `gsap.to(..., {opacity:0})` before the transition. The transition IS the exit. Exit tweens are BANNED except on the final scene.
3. **Hard kill after opacity exit** — After every `opacity:0` tween on a scene container, add:
   ```js
   .set('#sceneN', { visibility: 'hidden' }, exitEndTime)
   ```
   This prevents scrubbing/seek conflicts where the scene lingers.
4. **Calm blur crossfade formula** (wellness/medical brand):
   ```js
   // T = transition start time
   tl.to(old, { filter: 'blur(25px)', scale: 1.05, duration: 0.6, ease: 'power1.in' }, T)
     .to(old, { opacity: 0, duration: 0.4, ease: 'power1.in' }, T + 0.4)
     .fromTo(new, { filter: 'blur(25px)', scale: 0.95, opacity: 0 },
       { filter: 'blur(25px)', scale: 0.95, opacity: 1, duration: 0.3, ease: 'power1.inOut' }, T + 0.5)
     .to(new, { filter: 'blur(0px)', scale: 1, duration: 0.6, ease: 'power1.out' }, T + 0.8)
     .set(old, { visibility: 'hidden' }, T + 0.85);
   ```
5. **Final scene only** — exit animations (opacity fade, y slide) allowed ONLY on Scene 8.
6. **Register timelines** — `window.__timelines['main'] = tl` (always).
7. **No repeat: -1** — use finite repeats for ambient animations. Calculate: `Math.ceil(duration / cycleDuration) - 1`.
8. **First animation offset** — start at t=0.3s, not t=0, for smooth rendering.

## Character Image Treatment

- **Scene 2 (crew grid):** 80×80px circle, `object-fit: cover`, `object-position: center top`, drop-shadow
- **Scenes 3-5 (companion detail):** 240×240px circle, larger drop-shadow, `char-float` class
- **Ambient float animation:**
  ```css
  @keyframes float-breath {
    0%   { transform: translateY(0px)   scale(1.00); }
    50%  { transform: translateY(-10px) scale(1.02); }
    100% { transform: translateY(0px)   scale(1.00); }
  }
  .char-float { animation: float-breath 4s ease-in-out 3; }
  ```
  (finite repeats only — not `-1`)

## WCAG Contrast Fix

Small muted text on white often fails 4.5:1. Fix by darkening within the palette:
- `#AAAAAA` → `#666666` (label text)
- `#AAAAAA` → `#555555` (role captions)

Verify: `hyperframes validate` must show `73 text elements pass WCAG AA` (or similar clean count).

## Build & Verify Workflow

```bash
cd /Users/xuan/Desktop/medcxy-video
# lint
hyperframes lint
# validate (skip contrast during rapid iteration)
hyperframes validate --no-contrast
# full validate including contrast
hyperframes validate
# open to preview
open index.html
```

## Recommended 6-Scene Structure (Nano Banana style)

This structure matches the reference style — white background, smooth blur-scale transitions, embedded demo video:

| Scene | Content | Timing |
|-------|---------|--------|
| 1 | Brand logo + tagline | 0 – 5s |
| 2 | Product demo video (browser window mockup) | 5 – 18s |
| 3 | 6 AI companions crew grid | 18 – 28s |
| 4 | 小豆豆 detail | 28 – 34s |
| 5 | 豆丁 detail | 34 – 40s |
| 6 | CTA + website | 40 – 47s |

## Embedding Product Demo Video

Use a browser mockup window to show the actual product demo (absolute path required for local files):

```html
<div class="browser-window" style="width:100%;max-width:900px">
  <div class="browser-bar">
    <div class="browser-dot red"></div>
    <div class="browser-dot yellow"></div>
    <div class="browser-dot green"></div>
    <div class="browser-url">medagent.filldmy.com</div>
  </div>
  <div class="browser-content">
    <video id="demo-video" muted playsinline
           src="/Users/xuan/Desktop/展示视频.mp4"
           style="width:100%;height:100%;object-fit:cover"></video>
  </div>
</div>
```

```css
.browser-window {
  background: #F5F5F7;
  border-radius: 12px;
  box-shadow: 0 20px 60px rgba(0,0,0,0.12), 0 0 0 1px rgba(0,0,0,0.06);
}
.browser-bar { height: 40px; background: #E8E8ED; display:flex; align-items:center; padding:0 16px; gap:8px; }
.browser-dot { width:12px; height:12px; border-radius:50%; }
.browser-dot.red { background:#FF5F57; }
.browser-dot.yellow { background:#FFBD2E; }
.browser-dot.green { background:#28CA41; }
.browser-url { flex:1; height:24px; background:#fff; border-radius:5px; margin-left:8px;
  font-size:11px; color:#86868B; display:flex; align-items:center; padding:0 10px; }
.browser-content { background:#fff; width:100%; height:calc(100% - 40px); position:relative; }
.browser-content video { width:100%; height:100%; object-fit:cover; }
```

Start video playback when Scene 2 begins:
```js
tl.add(function() {
  var v = document.getElementById('demo-video');
  if (v) { v.currentTime = 0; v.play().catch(function(){}); }
}, 5.3); // slightly after scene starts
```

## Nano Banana Style Reference — Exact Frame Timing

Reference video: `/Users/xuan/Downloads/Nano Banana Pro in Google Slides.mp4` (38.7s, 1280×720)
Extracted key frames: `/Users/xuan/Desktop/medcxy-video/nb_frame_*.png`
Key frame grid: `/Users/xuan/Desktop/medcxy-video/nanobanana_grid.png`
Extracted audio: `/Users/xuan/Desktop/medcxy-video/nanobanana_audio.mp3`

**Opening sequence — precise frame timing (verified):**
- `0.00s` — Pure black (no background yet)
- `0.04–0.40s` — Background fades in (from ~16KB to full content)
- `0.42s` — Text begins appearing
- `0.52s` — Content accumulating (22KB+ file)
- `0.56–1.60s` — Full content visible (25–30KB file)
- `1.75–1.80s+` — Content clears

**Nano Banana animation formula:**
```js
// Opening: pure black → bg fade → text blur-unblur
tl.to('#bg',     { opacity: 1, duration: 1.4, ease: 'power2.out' }, 0.3)
  .to('#title', { opacity: 1, filter: 'blur(0px)', y: 0, scale: 1,
                   duration: 1.0, ease: 'power2.out' }, 0.7)
  .to('#sub',   { opacity: 1, filter: 'blur(0px)', y: 0, scale: 1,
                   duration: 0.85, ease: 'power2.out' }, 1.4)
// Exit: opacity fade + slight blur
  .to('#title', { opacity: 0, filter: 'blur(8px)', y: -15,
                   duration: 0.4, ease: 'power1.in' }, 6.5)
```

**Key style elements:**
- Pure black (#000000) background for opening scene
- Dark text with warm terracotta accent (#C4704B)
- Blur-scale crossfade between scenes: blur 20px, scale 1.04 outgoing / 0.96 incoming
- Staggered text entrance animations (opacity + y translate + filter blur)
- Audio extracted via: `ffmpeg -i video.mp4 -vn -acodec copy audio.aac && ffmpeg -i audio.aac -ab 128k audio.mp3`

## Frame Extraction for Reference Analysis

```bash
# Quick sequence (1fps — for rough timing)
for t in 0.00 0.50 1.00 1.50 2.00; do
  ffmpeg -i "video.mp4" -vf "scale=480:270" -ss "$t" -frames:v 1 -update 1 "frame_t${t}.png"
done

# Precise timing around a moment (e.g. text appearance at ~0.42s)
for t in 0.38 0.40 0.42 0.44 0.46 0.48 0.50; do
  ffmpeg -i "video.mp4" -vf "scale=480:270" -ss "$t" -frames:v 1 -update 1 "fine_t${t}.png"
done

# File size = proxy for content density (small = black/blank, large = full content)
ls -la fine_t*.png
```

**Rule: Show frames directly to user via `open` for visual approval before writing code.** Quantitative luminance analysis (PIL/numpy) was too heavy — user preferred visual inspection.

## Scene 3 — Design Pitfall (Browser Mockup Looks Cheap)

**BAD** (what NOT to do):
- macOS-style browser window with traffic light dots (red/yellow/green)
- website screenshot as `<img>` background
- emoji or unicode symbol in circles for abstract agents
- Looks like a PPT slide

**GOOD** (Nano Banana aesthetic):
- Dark background (#0D0D0D)
- 2×3 card grid: real avatar images for character agents, SVG icons for abstract agents
- Gold SVG icons for non-character agents (shield, lightning, circle-cross)
- Bottom product video panel
- Dot indicator row at bottom

```html
<div class="crew-grid">
  <!-- Character agents: use real avatar images -->
  <div class="crew-card">
    <div class="crew-card-avatar"><img src="douzai_sunny.png" /></div>
    <div class="crew-card-name">小豆豆</div>
    <div class="crew-card-role">GTM Strategy</div>
  </div>
  <!-- Abstract agents: SVG icons in circles -->
  <div class="crew-card">
    <div class="crew-card-avatar" style="display:flex;align-items:center;justify-content:center">
      <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#C4704B" stroke-width="1.5">
        <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
      </svg>
    </div>
    <div class="crew-card-name">合规卫士</div>
    <div class="crew-card-role">Compliance</div>
  </div>
</div>
```

## Files

- `/Users/xuan/Desktop/medcxy-video/index_new.html` — current Nano Banana style composition ← **always edit this one**
- `/Users/xuan/Desktop/medcxy-video/brand-logo.webp` — compressed logo (90KB)
- `/Users/xuan/Desktop/medcxy-video/douzai_sunny.png`, `douding_sunny.png`, `douya_sunny.png` — sunny IP variants
- `/Users/xuan/Desktop/medcxy-video/nb_p2_t*.png` — Nano Banana reference frame sequence (opening)
- `/Users/xuan/Desktop/medcxy-video/nb_s3_t*.png` — Nano Banana reference frame sequence (scene 3)
- `/Users/xuan/Desktop/medcxy-video/展示视频.mp4` — product demo video (used in scenes 1, 2, 3)
- `/Users/xuan/Desktop/medcxy-video/nanobanana_audio.mp3` — extracted audio
