---
name: hyperframes-debug-red-border
description: Debug red border/rectangle overlays appearing on Chinese text in HyperFrames HTML on macOS Chrome — caused by images with baked-in borders, not CSS.
category: hyperframes
---

# HyperFrames 红色边框排查指南

## 典型症状
Chrome 上播放 HyperFrames HTML 页面时，中文文字周围出现红色/橙色矩形边框。

## 排查步骤

### Step 1 — 用 Python 像素分析定位
```python
from PIL import Image
import numpy as np

img = Image.open('screenshot.png')
arr = np.array(img)
# 找红色像素（R高 G低 B低）
red_mask = (arr[:,:,0] > 150) & (arr[:,:,1] < 120) & (arr[:,:,2] < 120)
red_pts = np.where(red_mask)
if len(red_pts[0]) > 0:
    print(f"Red pixels: {len(red_pts[0])}")
    ys, xs = red_pts
    # 按y坐标分组（水平条带）
    bands = {}
    for y, x in zip(ys, xs):
        band = y // 10
        bands.setdefault(band, []).append(x)
    for band in sorted(bands):
        xs = bands[band]
        print(f"  y≈{band*10}: x={min(xs)}-{max(xs)}, count={len(xs)}")
```

### Step 2 — 检查背景图是否自带边框
红色像素的坐标如果对应某个背景图的位置，说明那张图本身就带了红色边框，而不是 CSS 问题。

**解法：** 换掉那张图，或用 `filter: saturate(0)` 检查是哪张图。

### Step 3 — 不要盲目调 CSS
- `outline: none !important` 对浏览器渲染层的装饰框无效
- `border: none !important` 只对 CSS border 有效
- `ime-mode: disabled` 是 IE 旧属性，macOS Chrome 不支持

**真正有效的方法：**
- 换掉带边框的图片素材（最常见根因）
- `filter: saturate(0)` 临时验证是哪张图在显示

### Step 4 — blur filter 导致的问题
`filter: blur()` 在 Chrome 上对中文文字做动画时，可能触发浏览器的渲染异常（红色边框浮现）。**解法：** 去掉 blur filter，改用纯 `opacity + transform` 做入场动画：

```css
/* ❌ blur filter — 可能触发 Chrome 渲染异常 */
.headline .word {
  filter: blur(12px);
  opacity: 0;
  transform: translateY(30px) scale(0.88);
}

/* ✅ 纯 opacity + transform — 稳定 */
.headline .word {
  opacity: 0;
  transform: translateY(30px) scale(0.88);
  filter: none;
}
```

## 关键经验
- 遇到视觉异常，先怀疑**素材本身**，再怀疑 CSS
- 用像素分析定位比肉眼更可靠
- macOS Chrome 的中文字渲染 bug 通常和 `filter: blur` 配合使用时触发
