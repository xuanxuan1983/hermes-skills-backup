---
name: video-timing-reverse-engineer
description: Reverse-engineer reference video animation timings using frame extraction + filesize analysis. For replicating animation curves, transitions, and scene timings when visual observation alone is insufficient.
---

# Video Timing Reverse-Engineering Skill

## When to Use
When asked to replicate a reference video's animation/animation timing and direct observation is difficult (e.g. the video plays in a browser vs a player with frame-by-frame controls).

## Core Technique: Filesize Sampling
Different frames of a compressed video have measurably different file sizes when extracted as PNGs. More complex/larger-area frames compress to larger files. By extracting frames at fine-grained timestamps and tracking file size, you can identify:
- Which frames are visually identical (same filesize = same content)
- When content first appears (small but nonzero size)
- Peak complexity frames (maximum filesize)
- When content clears (returns to base filesize)

## Step-by-Step Process

### 1. Extract dense frame sequence
```bash
cd /output/dir
for t in 0.00 0.04 0.08 0.10 0.12 ...; do
  ffmpeg -i "/path/to/video.mp4" -vf "scale=480:270" \
    -ss "$t" -frames:v 1 -update 1 "frame_t${t}.png" 2>/dev/null
done
```

Use `scale=480:270` to reduce file size while keeping visual content recognizable.

### 2. Read filesizes
```bash
ls -la frame_t*.png | awk '{print $9, $5}'  # $5 = size in bytes
```
Look for:
- **0 bytes or tiny size** → blank/black frame
- **Small but nonzero** → content just starting to appear
- **Peak size** → full/complex content
- **Sudden drop** → content cleared

### 3. Identify transition zones
In the Nano Banana case:
- 9KB at t=0.40 → still blank
- 10KB at t=0.42 → content appearing (diff = 1KB = real change)
- 22KB+ at t=0.52 → content fully arrived
- 9KB again at t=2.80 → content cleared

This told us:
- Content appears at ~0.42s
- Full content by ~0.52s
- Content clears at ~2.80s

### 4. Zoom in on transition zones
Once rough boundaries are found, extract at 0.02s intervals in the transition zone to pinpoint exact timing.

### 5. Open key frames visually for final confirmation
```bash
open frame_t0.42.png  # content-appearing frame
open frame_t0.52.png  # full-content frame
```
Use `sleep` to sequence multiple opens.

## GSAP Timeline Reconstruction
After identifying timestamps, build GSAP timeline using the exact time markers:
```javascript
var tl = gsap.timeline({ paused: true });
// Example: Nano Banana opening
// t=0.40s: still black
// t=0.42s: text starts appearing
// t=0.52s: full content visible
// t=2.80s: content clears

tl.to('#element', { opacity: 0 }, 0.40)      // start state
  .to('#text', { opacity: 1 }, 0.42)         // appear
  .to('#text', { opacity: 0 }, 2.80)         // clear
```

## Key Insight
File size analysis is faster than visual frame-by-frame because you don't need to open every frame — you can identify the 3-4 critical transition points from the size data alone, then verify visually.

## Pitfalls
- Use fixed output dimensions (`scale=`) so filesize comparisons are meaningful across frames
- Short intervals (0.02-0.04s) in transition zones for precision
- PNG not JPEG — PNG preserves visual content at small scales better
