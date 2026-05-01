# 硬核复古封面 Gem System 2.0

## 使用方式

用户提供文章主题 → 我提取关键词 + 写英文场景描述 → 套进以下 prompt

## 配色池（随机选一对）

| Pair | Background | Floor |
|------|-----------|-------|
| 1 | Grainy Copper-Bronze | Cobalt Blue |
| 2 | Grainy Vivid Orange | Neon Teal |
| 3 | Grainy Moss Green | Magenta |
| 4 | Grainy Mustard Yellow | Deep Purple |

## Prompt 模板

```
In the style of image_0.png, using a high-density, hard-edged polka dot halftone screen texture. The dots must be solid black and sharp, with zero transparency or gradient, creating a raw, coarse Riso print effect. Featuring a vivid, grainy [BACKGROUND_COLOR] textured background wall and a contrasting [FLOOR_COLOR] floor.

[SCENE_DESCRIPTION]

Rendered with heavy, hand-drawn black ink outlines (with subtle variations in weight, evoking vintage American comics). Minimalist, clean yet high-contrast aesthetic. It evokes a 1960s educational manual print feel, with complex hard dot-work shadows, and no soft gradients or vector smoothing. Wide angle view.
```

## 示例

文章：《如何用AI在5分钟内产出十万加爆款》
场景：A sleek white humanoid robot typing intensely on a massive keytar-keyboard, generating a storm of viral content (floating speech bubbles with '10W+' and '$' and lightbulbs)

生成命令：
```bash
MINIMAX_API_KEY=... MINIMAX_BASE_URL=https://api.minimaxi.com/v1 \
bun ~/.hermes/skills/baoyu-skills/skills/baoyu-imagine/scripts/main.ts \
  --prompt "[上述prompt]" \
  --image ~/Desktop/封面_[关键词].png \
  --ar 16:9
```
