---
name: hyperframes-zoom-fix
description: Fix Hyperframes video viewport overflow using zoom instead of transform scale
tags: [hyperframes, video, gsap, css, browser]
category: creative
---

# Hyperframes `zoom` Fix for Overflow Issues

## Context
When building video presentations with Hyperframes (hyperframes-cli) on macOS/浏览器, the 1920x1080 composition overflows the browser viewport on smaller screens.

## Problem
`transform: scale()` on `#root` causes overflow for scenes later in the timeline (scene 3+). Elements appear to extend beyond the viewport despite the scale being correct.

**Root cause:** `transform` creates a new containing block for absolutely positioned descendants. Elements with `position: absolute` inside `.scene` containers reflow relative to the transformed root, but the browser miscalculates dimensions during the animation, causing later scenes to bleed outside viewport boundaries.

## Solution
Use `zoom` instead of `transform: scale()` for the viewport-fit scaling:

```javascript
// In <script> at body end — NOT in <head>
function fitComposition() {
  var scaleX = window.innerWidth / 1920;
  var scaleY = window.innerHeight / 1080;
  var s = Math.min(scaleX, scaleY, 1);
  document.getElementById('root').style.zoom = s;
}
fitComposition();
window.addEventListener('resize', fitComposition);
```

```css
html, body {
  width: 100%;
  height: 100%;
  overflow: hidden;
  background: #FFFFFF;
}

body {
  display: flex;
  align-items: center;
  justify-content: center;
}

#root {
  width: 1920px;
  height: 1080px;
  flex: none;
  position: relative;
}
```

## Key Lessons
- **Don't use `transform: scale()`** for fitting video compositions to window — use `zoom`
- Scale script must run **after** `#root` exists (place at body end, not head)
- Always add `window.addEventListener('resize', fitComposition)` for responsive behavior
- `zoom` is supported in all modern browsers and does NOT create a new containing block

## Verification
```javascript
// In browser console:
document.getElementById('root').style.zoom  // e.g. "0.666667"
document.getElementById('root').getBoundingClientRect()  // should match window size
```
