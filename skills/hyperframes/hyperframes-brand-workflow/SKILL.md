---
name: hyperframes-brand-workflow
description: Extract real brand identity before writing HyperFrames HTML. Screenshot, pixel analysis, font inspection, DESIGN.md, then code. Avoids inventing brand elements.
category: hyperframes
---

# HyperFrames Brand Extraction Workflow

Every time you build a HyperFrames video for a real product, extract the real brand first. Never write HTML before establishing the real palette.

## The Problem

Writing composition HTML without reading the real brand produces generic colors, mismatched fonts, and wrong content. The user will say "不要自己瞎编". The hyperframes HARD-GATE exists because of this exact problem.

## Step 1 — Screenshot + Pixel Analysis

Navigate browser to the brand website, take a screenshot, then analyze pixels:

```python
python3 -c "
from PIL import Image
img = Image.open('screenshot.png')
w, h = img.size
# Brand accent appears in nav, CTA buttons, emphasis text
for y in range(200, 800, 10):
    for x in range(100, w-100, 20):
        r,g,b = img.getpixel((x,y))
        # warm terracotta range
        if r > 150 and r < 230 and g > 60 and g < 160 and b > 20 and b < 130:
            print(f'Accent at ({x},{y}): #{r:02x}{g:02x}{b:02x}')
"
```

Typical brand accent: warm terracotta/orange on white. Primary text: near-black `#1A1A1A`.

## Step 2 — Inspect Real Fonts

Open browser DevTools console:

```js
(function() {
  var fonts = [];
  document.fonts.forEach(function(f) { fonts.push(f.family); });
  return [...new Set(fonts)];
})()
```

Use ONLY these fonts. Check the hyperframes typography skill for banned fonts (Inter, Roboto, Outfit, Playfair Display, etc. are often wrong choices).

## Step 3 — Write DESIGN.md First

```
# Brand Video Design Spec

## Colors (extracted from website screenshot)
| Role      | Hex       |
|-----------|-----------|
| Accent    | #C4704B  |
| Primary   | #1A1A1A  |
| Secondary | #6A6A6A |
| Muted     | #AAAAAA |
| BG        | #FFFFFF |

## Fonts (from document.fonts)
- Display: Playfair Display
- Chinese: Noto Serif SC
- UI/Body: Inter

## What NOT to Do
- No invented colors outside this palette
- No banned fonts from hyperframes typography skill
- No exit animations before transitions
```

## Step 4 — Animation Timing from Frame Analysis

For video/texture animations, extract dense frame sequence (every 40–80ms) and use file size as content proxy:

```
t=0.40 → 10KB  blank
t=0.42 → 16KB  content appearing
t=0.46 → 19KB  growing
t=0.50 → 22KB  stabilizing
```

This tells you exactly when to start animations and how long transitions take.

**Animation type:** Do NOT assume blur-to-sharp. Nano Banana Pro text reveal is pure opacity + scale fade, NOT filter blur. Verify with frame analysis before writing GSAP.

## Step 5 — CSS Transition + GSAP Conflict (Critical)

**Wrong:** CSS `transition: opacity` on `.scene` + GSAP `set()` for opacity tweens. CSS transitions do NOT fire during GSAP seek/scrub.

**Right:** Pure GSAP for all opacity animation. No CSS `transition` on `.scene` at all.

```css
/* .scene — GSAP owns opacity, no CSS transition */
.scene {
  opacity: 0;
  /* NO transition property */
}
```

```js
// Scene fade in/out — pure GSAP tweens only
tl.fromTo('#scene1', { opacity: 0 }, { opacity: 1, duration: 0.7, ease: 'power2.inOut' }, 0.3)
  .to('#scene1', { opacity: 0, duration: 0.7, ease: 'power2.in' }, 4.6)
  .set('#scene1', { visibility: 'hidden' }, 5.3)  // hard kill after fade
```

## Step 6 — WCAG Contrast Iteration

Small text on white background needs multiple darkening passes:

| Starting color | Problem | Fix |
|----------------|---------|-----|
| `#AAAAAA` | 1.9:1 — fails WCAG | `#666666` → 4.5:1 |
| `#888888` | 3.0:1 — fails large text | `#555555` for 14px |

Run `hyperframes validate` after each color fix. Iterate until all elements pass.

## Step 7 — Verification

```bash
hyperframes lint                  # 0 errors, 0 warnings
hyperframes validate --no-contrast # No console errors
hyperframes validate              # WCAG AA pass count
```
