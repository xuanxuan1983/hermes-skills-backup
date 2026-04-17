---
name: hyperframes-video-frame-analysis
description: Extract frames from a reference video at precise timestamps to analyze opening animation timing and visual style before building a HyperFrames composition.
category: hyperframes
---

# 视频首帧风格分析流程

## 目标
在开始写 HyperFrames HTML 之前，先用 ffmpeg 提取参考视频的关键帧，理解其：
- 开场风格（纯黑屏？渐显？直接显示？）
- 文字入场时机和动画类型
- 背景/配色方案
- 场景切换节奏

## 工具
- `ffmpeg` — 提取帧
- `python3 + PIL` — 像素分析（文件大小、颜色采样）
- 浏览器打开截图 + 肉眼确认

## Step 1 — 批量提取首帧序列

```bash
cd /path/to/project

# Nano Banana 类：0-3s 每 0.1s 提取一次（10fps）
for t in 0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.2 1.5 1.8 2.0 2.5 3.0; do
  ffmpeg -i "reference_video.mp4" -vf "scale=960:540" -ss $t -frames:v 1 -update 1 "nb_t${t}.png" 2>/dev/null
done

# 稍长间隔用于后续场景（3-10s）
for t in 3.0 4.0 5.0 6.0 7.0 8.0; do
  ffmpeg -i "reference_video.mp4" -vf "scale=960:540" -ss $t -frames:v 1 -update 1 "nb_scene1_t${t}.png" 2>/dev/null
done
```

## Step 2 — 文件大小快速对比

文件大小直接反映画面复杂度（内容越多越大，纯黑屏最小）：

```bash
ls -la *.png | awk '{print $5, $9}' | sort -n
```

- ~2-3KB：纯黑/近黑帧
- ~30-80KB：文字/图形开始出现
- ~100KB+：完整内容帧
- ~30-50KB：场景切换时的空白/过渡帧

## Step 3 — 打开截图肉眼确认

用 `open` 命令在 Preview 中查看，和视频时间轴对应：

```bash
open nb_t0.0.png nb_t0.3.png nb_t0.6.png nb_t1.0.png
```

## Step 4 — 像素颜色分析（可选）

```python
from PIL import Image
import numpy as np

img = Image.open('nb_t0.5.png')
arr = np.array(img)
w, h = img.size
# 采样四角和中心
for label, y, x in [('tl', 10, 10), ('ctr', h//2, w//2), ('br', h-10, w-10)]:
    r, g, b = arr[y, x, :3]
    print(f"{label}: #{r:02x}{g:02x}{b:02x}")
```

## Step 5 — 总结动画时间轴

根据文件大小变化曲线，总结出：
1. 0.0s：纯黑（~2KB）
2. 0.3s：内容开始出现（~30KB）
3. 0.5s：文字渐显（~70KB）
4. 1.0s：完整显示（~80KB）
5. 2.0s：开始过渡（~45KB）

→ 用于确定 GSAP timeline 的关键时间点

## 常见 Nano Banana 开场模式
- **0.0s**：纯黑屏（opacity: 0）
- **0.3s**：背景/视频开始淡入
- **0.5-0.7s**：主标题 blur(14px)→0 + opacity:0→1 + translateY
- **1.2s**：副标题淡入
- **1.8s**：tagline 淡入
- **3.0s+**：场景过渡淡出

## 注意事项
- `scale=960:540` 用于分析，输出到 HTML 时用原始分辨率 `scale=1920:1080`
- `-update 1` 覆盖同一文件，不用每次改输出名
- 提取后立刻用 `open` 在 Preview 查看，不要只靠像素数据
