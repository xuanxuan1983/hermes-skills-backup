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

---

# HyperFrames Standalone HTML 场景可见性架构（核心规则）

## 症状：render 出来所有场景同时叠加在一起

当 HTML 文件中所有 scene 一起堆叠显示，而不是按时间顺序单独出现，说明违反了以下架构规则。

## 核心规则（Standalone Composition）

### 1. 永远不要在 scene div 上使用 `class="clip"`

```html
<!-- ❌ 错误 — class="clip" 在 standalone 中会破坏可见性控制 -->
<div id="scene1" class="scene clip">
<div id="scene2" class="scene clip">

<!-- ✅ 正确 — 纯 opacity 控制，不用 clip -->
<div id="scene1" class="scene">
<div id="scene2" class="scene">
```

### 2. 不要在 scene div 上使用 `data-track-index`

`data-track-index` 是**编译时**元数据，用于编译器生成的 JS 文件，不用于 standalone HTML 中的 scene div。scene div 上只需要 `id`。

### 3. Scene 1 默认可见，Scene 2+ 必须 CSS 写死 `opacity: 0`

```css
/* Scene 1 可见 */
#s-scene1 { z-index: 1; background: #0b0b10; }

/* Scene 2-7 默认隐藏 */
#s-scene2, #s-scene3, #s-scene4,
#s-scene5, #s-scene6, #s-scene7 {
  z-index: 2; /* 堆叠顺序 */
  opacity: 0; /* 必须显式写 0，不是 display:none */
}
```

**为什么用 `opacity: 0` 而不是 `display:none`？**
因为 `display:none` 会导致 GSAP 无法捕获元素做动画。只能用 `opacity: 0` 让元素存在于渲染树中但不可见。

### 4. 所有时序逻辑在 root div 的 GSAP timeline 上

```html
<!-- root div 承载 timing -->
<div
  id="root"
  data-composition-id="my-comp"
  data-width="1920"
  data-height="1080"
  data-start="0"
  data-duration="47"
>
  <div id="s1" class="scene">...</div>
  <div id="s2" class="scene" style="opacity:0">...</div>
</div>

<script>
var tl = gsap.timeline({ paused: true });

// Scene 2 入场：先 fade in Scene 2
tl.to('#s2', { opacity: 1, duration: 0.5, ease: 'power2.inOut' }, 6.0);
// Scene 1 退场：同时 fade out Scene 1
tl.to('#s1', { opacity: 0, duration: 0.5, ease: 'power2.inOut' }, 6.0);
// Scene 2 内部元素入场动画
tl.from('#s2 .headline', { opacity:0, y:30, duration:0.7 }, 6.3);
```

### 5. 没有"exit animation"——transition 本身就是 exit

除了**最后一个 scene**，其他 scene 的内容不能有 exit 动画。transition 的 fade out 就是内容消失的方式。

```javascript
// ✅ 正确：scene 切换时用 opacity fade，不做 element-level exit
tl.to('#s1', { opacity: 0, duration: 0.5 }, 6.0); // transition
tl.to('#s2', { opacity: 1, duration: 0.5 }, 6.0);

// ❌ 错误：在 scene 内部对元素做 exit 动画（除了最后一个 scene）
tl.to('#s1 .headline', { opacity: 0, y: -20 }, 5.8); // 不要这样做
```

### 6. 每个 scene 的 `.scene-inner` 撑满全屏

```css
.scene-inner {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 80px;
  box-sizing: border-box;
}
```

## 错误排查 Checklist

| 问题 | 原因 | 解决 |
|------|------|------|
| 所有 scene 同时叠加显示 | Scene 2+ 没有 `opacity:0` | CSS 加上 |
| 切换时元素没有消失 | 对元素单独做了 exit 动画 | 删掉，transition 负责消失 |
| 某 scene 全黑 | `background-color` 没写在 `.scene` 上 | 显式写 bg color |
| Lint 通过但 render 黑屏 | 忘了 `bgColor` 和 CSS bg 要一致 | 两者必须匹配 |
| 字体在 render 时大小不对 | Google Fonts 没加载完就开始捕获 | 用 `@font-face` 内联字体 |
