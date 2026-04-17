---
name: hyperframes-video-opening-replication
description: Precise workflow for replicating a reference video's opening sequence — frame extraction, pixel analysis, timing measurement, and faithful CSS/GSAP recreation. Based on Nano Banana Pro → Medcxy work.
category: hyperframes
---

# HyperFrames Video Opening Replication Workflow

Extract the reference video frame-by-frame, measure exact timing of visual events, then rebuild the opening sequence in HTML/GSAP.

## Step 1 — Dense Frame Extraction

Extract frames at 8–16fps or finer (every 40–80ms) during the opening sequence:

```bash
for t in 0.00 0.04 0.08 0.12 0.16 0.20 0.24 0.28 0.32 0.36 0.40 0.44 0.48 0.52 0.56 0.60 0.68 0.76 0.84 0.92 1.00 1.20 1.50 1.80; do
  ffmpeg -i "reference.mp4" -vf "scale=480:270" -ss "$t" -frames:v 1 -update 1 "ref_t${t}.png" 2>/dev/null
done
```

## Step 2 — File Size = Content Proxy

File size of each PNG is a reliable proxy for how much visual content is on screen. More content = larger file. Plot the sizes:

```
t=0.40 → 10KB  (blank)
t=0.42 → 16KB  (content starting)
t=0.46 → 19KB  (growing)
t=0.50 → 22KB  (more)
t=0.54 → 24KB  (stabilizing)
t=0.60 → 24KB  (stable)
```

This tells you WHEN things appear and WHEN transitions happen — without needing vision analysis.

## Step 3 — Identify Animation Type

CRITICAL DISCOVERY from Nano Banana analysis:
- Text reveal is NOT `filter: blur(12px) → 0` — this was WRONG
- Text appears via **pure opacity fade** + slight scale
- The "blur" impression is actually the video background FADING IN from black
- Blank frame at t=0.40s, then content fades in starting t=0.42s

Correct Nano Banana text reveal:
```css
.hero-title {
  opacity: 0;
  filter: blur(0px);  /* NO blur */
  transform: scale(0.96);
  /* GSAP: opacity 0→1, scale 0.96→1, no filter blur */
}
```

## Step 4 — Match Background Video to Reference Style

If reference = dark background with video content fading in:
1. Start video at opacity=0 on a pure black (#000) background
2. Fade video in starting around t=0.40s (not immediately)
3. The text should appear ON TOP of the already-visible (or fading-in) background

If your source video starts with content immediately (like Medcxy's 展示视频), you need to either:
- Find a start frame that matches the reference's blank-at-start style, OR
- Accept that the video's natural start is different from the reference

## Step 5 — Replicate in HTML

```html
<!-- Dark background first, video fades in -->
<div id="scene1" style="background:#000">
  <video id="hero-video" style="opacity:0" src="..." muted loop playsinline></video>
  <div class="hero-center">
    <div class="hero-title" id="hero-title">Medcxy <span style="color:#C4704B">AI</span></div>
    <div class="hero-subtitle" id="hero-subtitle">AI Companion Workbench</div>
  </div>
</div>
```

```js
var tl = gsap.timeline({ paused: true });

// t=0.40s: Video background fades in from black
tl.to('#hero-video', { opacity: 1, duration: 1.2, ease: 'power2.out' }, 0.40);

// t=0.50s: Title fades in (pure opacity, no blur)
tl.to('#hero-title', {
  opacity: 1,
  scale: 1,
  duration: 0.9,
  ease: 'power2.out'
}, 0.50);

// t=1.10s: Subtitle fades in
tl.to('#hero-subtitle', {
  opacity: 1,
  duration: 0.7,
  ease: 'power2.out'
}, 1.10);

tl.play();
```

## Key Pitfalls (Lessons Learned)

1. **Do NOT assume blur animation** — always verify via frame extraction. Nano Banana text reveal is opacity-only, not blur-to-sharp.
2. **File size jumping tells the timing story** — 10KB→16KB jump at t=0.42s = content appearing, not t=0
3. **Dark background video ≠ starts dark** — 展示视频.mp4 has content at frame 0 (48KB), while Nano Banana is blank until t=0.42s
4. **Use `open` command to view frames sequentially** — faster than trying to analyze programmatically
5. **Chrome IME red border** — setting `ime-mode: disabled` and `spellcheck="false"` on Chinese text elements prevents browser annotation boxes
