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
5. Timed elements need `class="clip"` + `data-start`, `data-duration`, `data-track-index`
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
https://cdn.jsdelivr.net/npm/gsap@3.12.5/dist/gsap.min.js
```
Not: cdnjs or unpkg (URLs may differ)

### Viewport Fitting (Critical)
For 1920x1080 compositions on smaller windows, use `zoom` NOT `transform: scale()`:

```js
// In <script> at body end — NOT in <head>
function fitComposition() {
  var s = Math.min(window.innerWidth / 1920, window.innerHeight / 1080, 1);
  document.getElementById('root').style.zoom = s;
}
fitComposition();
window.addEventListener('resize', fitComposition);
```

Why: `transform: scale()` creates a new containing block that breaks absolute positioning and overflow clipping. `zoom` scales visually without creating a new block formatting context.

### Animation End Problem
If animation auto-plays and fades to blank (all scenes opacity:0), add playback controls:
```js
document.addEventListener('keydown', function(e) {
  if (e.code === 'Space') { e.preventDefault(); tl.paused() ? tl.play() : tl.pause(); }
  if (e.code === 'ArrowLeft') { tl.time(Math.max(0, tl.time() - 5)); }
  if (e.code === 'ArrowRight') { tl.time(Math.min(tl.duration(), tl.time() + 5)); }
  if (e.code === 'Home') { tl.time(0).play(); }
});
document.addEventListener('click', function() { tl.paused() ? tl.play() : tl.pause(); });
```

### WCAG Contrast Fix
Tool-tags and small text on light backgrounds often fail 4.5:1. Use darker text colors:
- Light backgrounds: text should be #1A1A1A minimum (not pure black, softer)
- Avoid light grays (#888, #999) on white backgrounds
- Icon circles need darker fill or contrasting stroke

## Video Reference Analysis Workflow

When user provides a reference video and wants style matching:

### Step 1: Extract frames with ffmpeg
```bash
# Opening sequence: extract dense around text appearance (~0.4s)
for t in 0.38 0.40 0.42 0.44 0.46 0.48 0.50 0.60 0.72 1.00 1.40 1.60 1.80; do
  ffmpeg -i "video.mp4" -vf "scale=480:270" -ss "$t" -frames:v 1 -update 1 "nb_t${t}.png"
done
# File size = proxy: small=blank/black, large=full content (Nano Banana ~16KB blank, ~26KB full)
ls -la nb_t*.png | awk '{print $9, $5}'
```

### Step 2: Show frames to user for visual approval
```bash
open nb_t0.40.png && sleep 1 && open nb_t0.52.png && sleep 1 && open nb_t0.72.png
```
**Rule: Show frames directly to user — do NOT spend time on quantitative PIL/numpy analysis.** Users prefer visual inspection and will tell you immediately if timing is wrong. Quantitative luminance analysis was tried and rejected — too slow, wrong signal.

### Step 3: Create visual reference page (optional)
Only if user wants to compare multiple reference variants. Create a simple HTML grid showing extracted frames with timestamps for review.

## Common Issues & Fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| Elements overflow viewport | transform:scale() creates containing block | Use `zoom` instead |
| Animation ends blank | Auto-play fades all scenes to 0 | Add keyboard controls, loop, or end freeze |
| GSAP not loading | Wrong CDN URL | Use jsdelivr: `https://cdn.jsdelivr.net/npm/gsap@3.12.5/dist/gsap.min.js` |
| Lint passes but blank page | `data-*` attributes on wrong element | Ensure `data-composition-id`, `data-width`, `data-height` on `#root` |
| Text hard to read | Low contrast on colored backgrounds | Darken text to #1A1A1A minimum |
