---
name: hyperframes-video-production
description: Hyperframes (heygen-com/hyperframes) video production — viewport fitting, GSAP CDN, playback controls, video reference analysis, and common fixes
---
# Hyperframes Video Production Skill

## Context
Hyperframes (heygen-com/hyperframes) is a framework for AI-driven video composition — plain HTML + GSAP timelines, rendered via CLI. This skill covers production workflows not fully documented in the official docs.

## Hyperframes Quick Reference

### Key Rules (from docs)
1. Register all timelines on `window.__timelines` — renderer can't seek unregistered timelines
2. Video elements must be `muted` — audio in separate `<audio>` elements
3. No `Math.random()` — breaks determinism on render
4. Synchronous timeline construction — no async/await during GSAP setup
5. **Only use `class="clip"` for short in-scene timed elements (badges, lower-thirds). For multi-scene standalone compositions, use opacity-based scene switching — see Scene Architecture below.**
6. Every scene needs entrance animations
7. Every scene needs transitions

### CLI Commands
```bash
npx hyperframes lint        # structural validation (always run first)
npx hyperframes validate    # runtime check in headless Chrome
npx hyperframes preview     # browser preview
npx hyperframes render      # export video
```
Always run both `lint` and `validate` — they catch different classes of issues.

### GSAP CDN (verified working)
```
https://cdn.jsdelivr.net/npm/gsap@3.14.2/dist/gsap.min.js
```
Not: cdnjs or unpkg (URLs may differ). Version 3.14.2 confirmed working; 3.12.5 also works.

---

## Scene Architecture: Two Patterns

HyperFrames has **two distinct animation patterns** — mixing them causes broken renders. The `class="clip"` mechanism is NOT for full-scene switching.

### Pattern A: Timed Clips (class="clip")
For short elements that appear/disappear within a scene at specific times.
```html
<div class="scene">
  <span class="clip" data-start="2" data-duration="3" data-track-index="0">Badge</span>
</div>
```
- Element is hidden by default, revealed at `data-start` for `data-duration` seconds
- `data-track-index` prevents overlap conflicts
- Does NOT need `opacity: 0` on container
- **NOT for full-scene switching**

### Pattern B: Opacity Crossfade (multi-scene standalone)
For compositions with multiple full-page scenes that switch sequentially. This is the correct pattern for brand films, explainers, presentations.

```html
<!DOCTYPE html>
<html lang="zh">
<head>
  <meta charset="UTF-8">
  <script src="https://cdn.jsdelivr.net/npm/gsap@3.14.2/dist/gsap.min.js"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { background: #0b0b10; font-family: 'Noto Serif SC', serif; overflow: hidden; }

    .scene {
      position: absolute;
      inset: 0;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .scene-inner {
      width: 100%;
      height: 100%;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 80px;
      gap: 28px;
    }

    /* Scene 1: VISIBLE by default */
    #s-cover { z-index: 1; background: radial-gradient(ellipse at 50% 60%, #1a1520 0%, #0b0b10 70%); }

    /* Scenes 2+: HIDDEN via CSS opacity */
    #s-flywheel { z-index: 2; opacity: 0; }
    #s-scene3   { z-index: 3; opacity: 0; }
  </style>
</head>
<body>
<div
  id="root"
  data-composition-id="main"
  data-width="1920"
  data-height="1080"
  data-start="0"
  data-duration="47"
>
  <div id="s-cover" class="scene">
    <div class="scene-inner">
      <!-- content -->
    </div>
  </div>

  <div id="s-flywheel" class="scene">
    <div class="scene-inner">
      <!-- content -->
    </div>
  </div>

  <div id="s-scene3" class="scene">
    <div class="scene-inner">
      <!-- content -->
    </div>
  </div>
</div>

<script>
window.__timelines = window.__timelines || {};
var tl = gsap.timeline({ paused: true });

/* SCENE 1 ENTRANCE (at t=0) */
tl.from('#s-cover .scene-inner > *', { opacity: 0, y: 30, stagger: 0.15, duration: 0.7, ease: 'power2.out' }, 0.3);

/* SCENE 2: crossfade at t=6s */
tl.to('#s-cover',    { opacity: 0, duration: 0.5, ease: 'power2.inOut' }, 6.0);
tl.to('#s-flywheel', { opacity: 1, duration: 0.5, ease: 'power2.inOut' }, 6.0);
tl.from('#s-flywheel .scene-inner > *', { opacity: 0, y: 24, stagger: 0.12, duration: 0.65, ease: 'power3.out' }, 6.3);

/* SCENE 3: crossfade at t=13s */
tl.to('#s-flywheel', { opacity: 0, duration: 0.5, ease: 'power2.inOut' }, 13.0);
tl.to('#s-scene3',   { opacity: 1, duration: 0.5, ease: 'power2.inOut' }, 13.0);

/* Final fade to black */
tl.to('#s-scene3 .scene-inner', { opacity: 0, duration: 1.0, ease: 'power2.inOut' }, 44.5);

window.__timelines['main'] = tl;
</script>
</body>
</html>
```

**Key rules for Pattern B:**
- Scene 1 has NO `opacity: 0` — starts visible
- Scenes 2+ have `opacity: 0` set via CSS (not GSAP)
- GSAP crossfades: `tl.to('#s-outgoing', { opacity: 0 })` + `tl.to('#s-incoming', { opacity: 1 })` at same timestamp
- No `data-track-index` on scene divs
- No `class="clip"` on scene divs — only on in-scene timed elements
- Root div holds timing: `data-start="0"`, `data-duration="47"`
- Entrance animations target `.scene-inner > *` children, NOT the `.scene` container

---

## Font Sizing for 1920x1080 Video

1920x1080 is a large canvas. Small text that looks OK on a monitor is illegible on video. Use this scale:

| Element | Size (1920×1080) |
|---|---|
| Hero title | `clamp(54px, 7vw, 128px)` |
| Section title | `clamp(36px, 5vw, 76px)` |
| Card/section label (eyebrow) | 13–14px, Courier New, letter-spacing 0.4–0.45em |
| Body bold (card names, table headers) | 18–24px |
| Body text (descriptions, list items) | 16–20px |
| Small accent (badges, percentages) | 13–15px |
| Subtle text (sub-descriptions) | 15–18px, color #c0b8b0 or lighter |

**Dark background text color for 1920x1080:**
- On dark backgrounds (#0b0b10, #1a1520): use `#f0ece4` for primary white, `#c9a84c` for gold accents
- Gray text: NEVER use `#9a9080` or `#7a7060` — too dark. Use `#c0b8b0` (light warm gray) minimum
- Gold accent: `#c9a84c` — verified visible on dark backgrounds
- Background gradient gives depth: `radial-gradient(ellipse at 50% 60%, #1a1520 0%, #0b0b10 70%)`

**Rule:** In a 47-second brand film, every word must be readable at arm's length on a phone screen. When in doubt, go bigger.

---

## Root Composition: Exact Required Attributes

The root `#root` div MUST have all five:

```html
<div id="root"
  data-composition-id="main"
  data-width="1920"
  data-height="1080"
  data-start="0"
  data-duration="47">
```

And the JS registration MUST use the same string:

```js
window.__timelines = { "main": tl };
//                ↑ must match data-composition-id exactly
```

**`lint` vs `validate`:** `lint` checks contract statically (missing attributes, bad IDs); `validate` runs in real headless Chrome and catches runtime issues (JS errors, 404s). Always run both.

---

## Viewport Fitting

For 1920x1080 compositions on smaller windows, use `zoom` NOT `transform: scale()`:

```js
function fitComposition() {
  var s = Math.min(window.innerWidth / 1920, window.innerHeight / 1080, 1);
  document.getElementById('root').style.zoom = s;
}
fitComposition();
window.addEventListener('resize', fitComposition);
```

`zoom` scales visually without creating a new block formatting context. `transform: scale()` creates a containing block that breaks absolute positioning.

---

## Animation End Problem

If animation auto-plays and fades to blank (all scenes opacity:0), add playback controls:

```js
document.addEventListener('keydown', function(e) {
  if (e.code === 'Space') { e.preventDefault(); tl.paused() ? tl.play() : tl.pause(); }
  if (e.code === 'ArrowLeft') { tl.time(Math.max(0, tl.time() - 5)); }
  if (e.code === 'ArrowRight') { tl.time(Math.min(tl.duration(), tl.time() + 5)); }
});
document.addEventListener('click', function() { tl.paused() ? tl.play() : tl.pause(); });
```

---

## Video Reference Analysis Workflow

When user provides a reference video and wants style matching:

### Step 1: Extract frames with ffmpeg
```bash
for t in 0.38 0.40 0.42 0.44 0.46 0.48 0.50 0.60 0.72 1.00 1.40 1.60 1.80; do
  ffmpeg -i "video.mp4" -vf "scale=480:270" -ss "$t" -frames:v 1 -update 1 "ref_t${t}.png"
done
ls -la ref_t*.png | awk '{print $9, $5}'
```

### Step 2: Show frames to user for visual approval
```bash
open ref_t0.40.png && sleep 1 && open ref_t0.52.png
```
**Rule: Show frames directly to user.** Do NOT spend time on quantitative PIL/numpy analysis. Users spot timing issues immediately; quantitative analysis is slow and noisy.

---

## Common Issues & Fixes

| Issue | Cause | Fix |
|---|---|---|
| Elements overflow viewport | transform:scale() creates containing block | Use `zoom` instead |
| Animation ends blank | Auto-play fades all scenes to 0 | Add keyboard controls; final scene fade-out at end |
| GSAP not loading | Wrong CDN URL | Use `https://cdn.jsdelivr.net/npm/gsap@3.14.2/dist/gsap.min.js` |
| `missing_timeline_registry` in lint | Root missing attributes or key mismatch | Root `#root` needs all five `data-*`; `window.__timelines` key must match `data-composition-id` exactly |
| Render silently fails | Font not mapped or 404 resource | Check compiler output for `No deterministic font mapping for:`; use `inter`, `montserrat`, or `noto-sans-jp` |
| Text hard to read on video | Text too small for 1920x1080 | See Font Sizing table above; body text minimum 16px |
| Gray text invisible on dark bg | #9a9080 too dark on #0b0b10 | Use #c0b8b0 minimum; never go darker than #b0a898 on dark backgrounds |
| Scenes all blank | Using `class="clip"` for full-scene switching | Use Pattern B opacity crossfade, not timed clips, for multi-scene |

---

## Font Mapping

The HyperFrames compiler maps common font names automatically. Known working:
- `SF Pro Display` → NOT mapped → use `inter`, `montserrat`, or `noto-sans-jp`
- `Arial Black` → `montserrat`
- `Helvetica Neue` → `inter`

Check compiler output for `No deterministic font mapping for:` and switch to a mapped alternative.
