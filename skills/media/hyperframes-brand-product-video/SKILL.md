---
name: hyperframes-brand-product-video
description: Build brand/product videos in Hyperframes using real brand assets — colors, fonts, logos, and character IP images extracted from actual brand sources.
---

# Hyperframes Brand Product Video — From Real Assets

## When to use
Build a brand/product video using Hyperframes that must reflect real brand identity (colors, fonts, logos, character IP).

## Workflow

### Step 1 — Extract Real Brand Identity
Do NOT guess. Navigate to the actual brand website and extract:
- Primary/accent colors from screenshots
- Official fonts from site CSS (`curl | grep fonts.googleapis.com`)
- Any logo/product screenshots available

```bash
# Get brand logo + product screenshots
curl -s -o brand-logo.png "https://brand.site/logo.png"
curl -s -o screenshot.webp "https://brand.site/screenshot.webp"
```

### Step 2 — Find Character IP Assets
Check project folders for character images:
```bash
find "/path/to/project" -type f \( -iname "*.png" -o -iname "*.jpg" \) 2>/dev/null | grep -i "char\|avatar\|ip"
```
Copy to video project directory with short logical names:
```bash
cp "/source/char_base.png" "/video-project/char_name.png"
```

### Step 3 — Build CSS with Real Brand Tokens
```css
:root {
  --accent:  #C4704B;  /* real brand color */
  --primary: #1A1A1A;
  --muted:   #666666;  /* WCAG-compliant, NOT #AAAAAA */
}
```

### Step 4 — CSS Keyframes for Perpetual Motion
Use CSS `@keyframes` for infinite animations (float, breathe, glow) — NOT GSAP:
```css
@keyframes float-breath {
  0%   { transform: translateY(0px)   scale(1.00); }
  50%  { transform: translateY(-10px) scale(1.02); }
  100% { transform: translateY(0px)   scale(1.00); }
}
.char-float { animation: float-breath 4s ease-in-out infinite; }
```
GSAP for entrances only. CSS for anything that runs forever.

### Step 5 — WCAG Contrast Fix
`#AAAAAA` on white = ~2.9:1 ratio (fails WCAG AA). Fix systematically:
- Small caps/labels: `#555555` or `#666666`
- Run `hyperframes validate` → verify "73 text elements pass WCAG AA"

### Step 6 — Character Image CSS Setup
```css
/* Scene 2: small circular avatar in crew overview */
.crew-card .c-avatar {
  width: 80px; height: 80px;
  border-radius: 50%;
  object-fit: cover;
  object-position: center top;
  filter: drop-shadow(0 4px 12px rgba(0,0,0,0.12));
}

/* Scenes 3-5: large floating portrait */
.companion-layout .comp-img {
  width: 240px; height: 240px;
  border-radius: 50%;
  object-fit: cover;
  object-position: center top;
  filter: drop-shadow(0 8px 24px rgba(0,0,0,0.14));
}
.char-float { animation: float-breath 4s ease-in-out infinite; }
```

### Step 7 — GSAP Entrance Animation
```js
// Entrance: elastic pop-in (scale from 0.7, not 0, avoids distortion)
tl.from('#scene3 .comp-img', {
  scale: 0.7, opacity: 0, duration: 0.7, ease: 'back.out(1.4)'
}, 12.5)
// CSS .char-float handles perpetual float after entrance finishes
```

### Step 8 — Verification
```bash
hyperframes lint 2>&1        # 0 errors, 0 warnings
hyperframes validate 2>&1   # "73 text elements pass WCAG AA"
```

## Key Insight: Two Animation Systems
| System | Use for | Never use for |
|--------|---------|---------------|
| GSAP timeline | Entrance (one-shot, scene-scoped) | Perpetual motion |
| CSS @keyframes | Float, breathe, glow, pulse (runs forever) | Scene transitions |

## Trial-and-Error Learnings
- **Avatar vs real image**: Start with placeholder initials in brand-color circles if no image available, then swap in real IP image files once located
- **Scale not 0**: When animating character portraits, use `scale: 0.7` not `scale: 0` for the start — prevents face distortion on round-masked images
- **Stagger offset**: When adding new elements to an existing GSAP chain, push subsequent stagger times by ~0.6s so elements don't overlap
- **Duplicate media warning**: Two identical `<img>` sources with same start/duration triggers `duplicate_media_discovery_risk` — use distinct filenames or `class` variations if different expressions of same character are needed
