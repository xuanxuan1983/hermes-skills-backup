---
name: ai-video-studio
description: 一键直出国际范大牌广告片 - 4个Skills串联，6步出片，从静态图到30秒成片
metadata:
  version: "2.0"
  author: "Claude Code Skill System"
  tags: ["video", "ai", "advertising", "remotion", "elevenlabs", "jimeng"]
---

# AI Video Studio

核心价值：**4个 Skills 串联，6步出片**，从静态图到 30 秒成片。

## 为什么需要这个 Skill

AI 做视频的人都知道痛点：
- 图片一致性难控制
- 画面视频提示词难写
- 剪辑手动卡点繁琐
- 一个 30 秒的广告片要搞几天

**解决方案**：用 Skill 系统把 4 个独立工具串成一条自动化流水线。

## 工具链

| 工具 | 用途 |
|------|------|
| **Claude** | 剧本 + 提示词 + 编排 |
| **即梦** | 图生视频 |
| **ElevenLabs** | AI 配音 + 音效 |
| **Remotion** | React 声明式合成 |

## 6 步出片流程

```
① 剧本      → Claude 生成镜头脚本
② 提示词    → 每镜头的画面描述 + 运镜指令
③ 静态帧    → AI 生图 (Midjourney/即梦/SD)
④ 图生视频  → 即梦 API (5秒/镜头)
⑤ 配音+音效 → ElevenLabs TTS + Sound Effects
⑥ 合成      → Remotion 声明式编排 → 渲染输出
```

## 快速开始

### 1. 初始化项目

```bash
bash skills/ai-video-studio/scripts/init.sh my-ad-project
```

### 2. 生成剧本

```bash
# 提供品牌信息，Claude 输出镜头脚本
bash skills/ai-video-studio/modules/script-writing/generate.sh \
  --brand "Equation" \
  --product "香薰蜡烛" \
  --style "Aesop-inspired minimalism"
```

### 3. 生成提示词

```bash
bash skills/ai-video-studio/modules/prompt-engineering/generate.sh \
  --script ./scripts/script.json \
  --output ./prompts/
```

### 4. 图生视频

```bash
bash skills/ai-video-studio/modules/image-to-video/generate.sh \
  --images ./images/ \
  --prompts ./prompts/ \
  --output ./videos/
```

### 5. 生成配音和音效

```bash
bash skills/ai-video-studio/modules/voiceover/generate.sh \
  --script ./scripts/script.json \
  --output ./audio/

bash skills/ai-video-studio/modules/sound-effects/generate.sh \
  --script ./scripts/script.json \
  --output ./audio/sfx/
```

### 6. Remotion 合成

```bash
cd remotion/
npm install

# 预览
npx remotion studio

# 渲染
npx remotion render EquationAd out/equation-ad.mp4
```

## 核心原则

### 品牌锚点 > 形容词

写「Aesop 风格」比写「克制、极简、优雅」有效 10 倍。

### 多生少选 > 精雕一张

生 8 张选 5 张比反复修改一张快得多。

### 英文配音 > 中文配音

对于高端品牌广告来说，英文更有「大牌感」。

### 30 秒 = 5-6 镜头

这是黄金比例。

## Provider 配置

工具可替换，改一行配置就能换工具：

```yaml
# config/providers.yaml
voiceover:
  default: elevenlabs
  providers:
    elevenlabs: { strengths: [英文优秀, 音效API] }
    minimax:    { strengths: [全球第一, 中文极佳, 6秒克隆] }

image_to_video:
  default: jimeng
  providers:
    jimeng:    { strengths: [运镜控制好, 国内访问] }
    runway:    { strengths: [质量高, Gen-3 Alpha] }
    seedance:  { strengths: [质量极高, 2.0版本], status: planned }
```

## 工作流类型

- `ad-commercial` - 品牌广告片
- `mv-music-video` - MV 剪辑
- `product-showcase` - 产品展示
- `social-short` - 社媒短视频

## 关键经验

### 剧本
- 不要每个镜头都有旁白，留白更高级
- 开头让画面先说话，结尾一句品牌名收住

### 提示词公式
```
[场景] + [产品细节] + [光线] + [色调hex] + [技术参数] + [品牌锚点]
```

### 运镜提示词用中文
即梦是字节跳动的产品，对中文运镜指令的理解更准确。

### 渲染规格
- 1920x1080 / H.264 + AAC
- 30 秒 / 约 45 MB

## 目录结构

```
ai-video-studio/
├── SKILL.md                    # 入口文件
├── config/
│   └── providers.yaml          # Provider 切换
├── workflows/                  # 5 种场景工作流
│   ├── ad-commercial.md
│   ├── mv-music-video.md
│   └── ...
├── modules/                    # 能力模块
│   ├── script-writing/
│   ├── prompt-engineering/
│   ├── image-to-video/
│   ├── voiceover/
│   ├── sound-effects/
│   └── composition/
├── templates/                  # 可运行的脚本模板
│   └── remotion/
└── knowledge/                  # 领域知识
    ├── motion-vocabulary.md
    └── troubleshooting.md
```

## 踩坑合集

| 问题 | 原因 | 解决方案 |
|------|------|---------|
| interpolate [0,0] 报错 | fadeIn=0 导致区间 [0,0] | 加判断：fadeIn > 0 ? interpolate(...) : 1 |
| 渲染时符号链接失败 | Remotion 不支持 symlink | 直接复制素材到 public/ |
| 音画不同步 | 配音时长 ≠ 镜头时长 | 先生成配音，根据实际时长调整 durationInFrames |
| 即梦运镜没效果 | 提示词太复杂 | 一个镜头一个主要动作 |
| 中文配音「土」 | 不是技术问题，是定位问题 | 高端品牌用英文 |

## 写在最后

这套系统的本质不是「AI 帮你做视频」，而是「AI 帮你搭建一条可复用的视频生产线」。

Skills 就该这么用——不是一个万能的大 Skill，而是多个小 Skill 的灵活组合。像乐高一样拼接，每次组合都可能产生新的玩法。

下一步：等 Seedance 2.0 API 开放后，替换掉即梦，画面质量会再上一个台阶。配置已经预留好了。
