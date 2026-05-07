---
name: baoyu-editorial-line-image
description: 用 MiniMax image-01 生成黑白线稿人物 + 杂志编辑风格的图片（editorial line system）。适用于小红书封面、微博配图、微信小绿书配图。触发：用户说"editorial"、"黑白线稿"、"做成这种插画风格"、"用editorial风格"。
---

# baoyu-editorial-line-image

用 MiniMax API 生成 editorial line system 风格的图片——黑白线稿人物 + 杂志编辑排版 + 少量柔和色块。

## 风格 DNA（来自 huxiang1126/editorial-line-system）

- 黑白线稿人物，极简几何比例，简化面部
- 都市生活场景：通勤、看手机、阅读、购物、行走、休息
- 杂志编辑语言：大留白、强排版层级、大标题
- 少量柔和色块点缀（奶油白、淡黄、暖橙、淡粉）
- 人物主体保持黑白，彩色仅用于背景色块
- 扁平矢量感，无3D、无光泽渲染

## Prompt 模板（英文）

```
A modern editorial illustration for [SUBJECT], featuring minimalist black-and-white line art characters in a clean flat geometric style. [SCENE DESCRIPTION with character action and emotion]. Editorial magazine typography reads '[HEADLINE TEXT]'. Pastel accent blocks in [ACCENT_COLORS: soft yellow, warm cream, muted orange] fill background geometric shapes. Large negative space, asymmetrical layout, strong hierarchy. Urban lifestyle aesthetic, vector-like smooth lines, flat design, no realistic lighting, no 3D render. Vertical poster format 1080x1920.

Negative prompt: 3D, realistic shading, glossy gradients, stock-photo look, childish cartoon, clutter, illegible text, excessive colors, anime style.
```

## 适用场景

| 场景 | 比例 | 用途 |
|------|------|------|
| 小红书封面 | 1080x1920 | 竖版配图 |
| 微博配图 | 1280x720 | 横向 |
| 微信小绿书 | 1080x1920 | 竖版 |
| 知乎回答配图 | 1024x1024 | 方版 |

## 生成命令

```bash
source ~/.baoyu-skills/baoyu-imagine/.env 2>/dev/null

PROMPT="A modern editorial illustration for [完整prompt]..."

IMG_URL=$(curl -s -X POST "https://api.minimaxi.com/v1/image_generation" \
  -H "Authorization: Bearer $MINIMAX_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"image-01\",\"prompt\":$(echo "$PROMPT" | jq -Rs .),\"image_size\":\"1080x1920\",\"return_url\":true}" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['data']['image_urls'][0].replace('%2F','/').replace('%25','%'))")

curl -s "$IMG_URL" -o /tmp/output.jpg --max-time 60
echo "Done: /tmp/output.jpg"
```

## 已知坑

1. 返回的 URL 含 `%2F` 等编码，必须替换后再 curl 下载
2. prompt 含中文需用 `jq -Rs .` 处理（raw string）
3. 返回可能是 JPEG 但扩展名为 PNG，不影响使用
4. MiniMax image-01 对写实人脸支持有限，editorial 风格（简化人物）效果更好
