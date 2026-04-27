#!/bin/bash
# Humanizer CLI for Kimi
# Usage: bash ~/.agents/skills/humanizer/humanize.sh <file.md>

set -e

if [ $# -eq 0 ]; then
    echo "Usage: humanize.sh <file>"
    echo "Example: humanize.sh article.md"
    exit 1
fi

INPUT_FILE="$1"
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File not found: $INPUT_FILE"
    exit 1
fi

OUTPUT_FILE="${INPUT_FILE%.*}.humanized.md"

cat > "$OUTPUT_FILE" << 'PROMPT_HEADER'
# Humanizer Prompt

请对以下文本进行 humanize 处理，去除 AI 写作痕迹，让它读起来更像真人写的。

要求：
1. 扫描并清除 AI 写作模式（过度升华、-ing 伪深度分析、模糊归因、AI 高频词汇、被动语态、填充短语、三段式罗列等）
2. 保留核心意思不变
3. 注入人格和观点——用第一人称、加入具体感受、承认复杂性
4. 变化句式节奏，长短句混合
5. 去掉「值得注意的是」「综上所述」「让我们深入探讨」这类 AI 腔
6. 最后自检：这段文字还有什么明显的 AI 痕迹？再改一遍

---

PROMPT_HEADER

echo "原始文本：" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
cat "$INPUT_FILE" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "---" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "请输出：1) 初稿改写 2) 自检发现的 AI 痕迹 3) 最终版本 4) 修改摘要" >> "$OUTPUT_FILE"

echo "✅ Humanizer prompt 已生成: $OUTPUT_FILE"
echo "📋 你可以直接把这个文件的内容复制给 Kimi / Claude 使用"
