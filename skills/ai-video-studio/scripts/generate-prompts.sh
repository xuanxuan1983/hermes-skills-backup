#!/bin/bash
#
# AI Video Studio - 提示词生成脚本
# 根据剧本生成画面提示词（英文）和运镜提示词（中文）
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 颜色
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# 使用说明
usage() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --script FILE     剧本文件 (默认 ./assets/script.json)"
    echo "  --output DIR      输出目录 (默认 ./assets/prompts/)"
    echo ""
    echo "示例:"
    echo "  $0 --script ./assets/script.json --output ./assets/prompts/"
}

# 生成提示词模板
generate_prompt_template() {
    cat << 'EOF'
# 提示词生成指南

根据以下剧本，为每个镜头生成两组提示词：

## 格式要求

每个镜头需要：
1. **画面提示词**（英文，给生图 AI）
2. **运镜提示词**（中文，给即梦 API）

## 提示词公式

画面提示词 = [场景] + [产品细节] + [光线] + [色调hex] + [技术参数] + [品牌锚点]

## 示例

### 镜头 1: 公式浮现

**画面提示词（英文）:**
```
A mathematical equation crystallizing into a spiral form, golden particles converging, dark background, muted grey-white tones with gold accents, cinematic lighting, shot on ARRI Alexa, Aesop-inspired minimalism, 16:9
```

**运镜提示词（中文）:**
```
镜头缓缓推近，金色粒子环绕飘散，画面从模糊到清晰
```

## 运镜词汇参考

- 镜头缓缓推近 / 慢慢拉远
- 镜头从左向右平移
- 镜头缓慢上升 / 下降
- 镜头环绕主体旋转
- 镜头跟随产品移动
- 镜头固定，主体入画
- 镜头微微晃动（手持感）

## 技术参数

- 拍摄设备: ARRI Alexa / Sony Venice / Red Komodo
- 画幅: 16:9
- 光线: cinematic lighting, soft side light, backlit silhouette

## 品牌锚点

- Aesop: 极简、实验室感、植物元素
- Byredo: 北欧、性冷淡、高级感
- Le Labo: 工业风、手工感

请根据以上格式，为剧本中的每个镜头生成提示词。
EOF
}

# 主函数
main() {
    SCRIPT="${SCRIPT:-./assets/script.json}"
    OUTPUT="${OUTPUT:-./assets/prompts}"
    
    # 解析参数
    while [ $# -gt 0 ]; do
        case "$1" in
            --script)
                SCRIPT="$2"
                shift 2
                ;;
            --output)
                OUTPUT="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                echo "未知参数: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # 检查剧本文件
    if [ ! -f "$SCRIPT" ]; then
        echo "❌ 剧本文件不存在: $SCRIPT"
        echo "请先运行 generate-script.sh 生成剧本"
        exit 1
    fi
    
    print_info "读取剧本: $SCRIPT"
    
    # 创建输出目录
    mkdir -p "$OUTPUT"
    
    # 读取剧本信息
    BRAND=$(cat "$SCRIPT" | grep -o '"brand": "[^"]*"' | head -1 | cut -d'"' -f4)
    PRODUCT=$(cat "$SCRIPT" | grep -o '"product": "[^"]*"' | head -1 | cut -d'"' -f4)
    STYLE=$(cat "$SCRIPT" | grep -o '"style": "[^"]*"' | head -1 | cut -d'"' -f4)
    
    print_info "品牌: ${BRAND:-未知}"
    print_info "产品: ${PRODUCT:-未知}"
    print_info "风格: ${STYLE:-Aesop}"
    
    # 生成提示词生成指南
    GUIDE_FILE="$OUTPUT/generate-guide.md"
    generate_prompt_template > "$GUIDE_FILE"
    
    # 生成提示词生成请求
    PROMPT_FILE="$OUTPUT/prompt-request.txt"
    cat > "$PROMPT_FILE" << EOF
请根据以下剧本，为每个镜头生成画面提示词和运镜提示词。

剧本文件: $SCRIPT

$(cat "$SCRIPT")

---

请按以下格式输出每个镜头的提示词：

## 镜头 X: [镜头描述]

**画面提示词（英文）:**
[英文提示词，包含场景、光线、色调、技术参数、品牌锚点]

**运镜提示词（中文）:**
[中文运镜描述，简洁明了，一个主要动作]

**参考色调:**
- 主色: #[hex]
- 辅色: #[hex]
- 点缀: #[hex]

---

提示词公式:
画面提示词 = [场景] + [产品细节] + [光线] + [色调hex] + [技术参数] + [品牌锚点]

品牌锚点参考: ${STYLE:-Aesop} 风格
EOF
    
    print_success "提示词生成指南已保存到: $GUIDE_FILE"
    print_success "提示词请求已保存到: $PROMPT_FILE"
    
    echo
    echo -e "${CYAN}操作步骤:${NC}"
    echo "1. 查看生成指南: cat $GUIDE_FILE"
    echo "2. 复制提示词请求: pbcopy < $PROMPT_FILE"
    echo "3. 粘贴到 Claude 生成详细提示词"
    echo "4. 将生成的提示词保存到: $OUTPUT/shot-X.md"
    echo
    
    # 创建示例提示词文件
    cat > "$OUTPUT/example-shot-1.md" << 'EOF'
# 镜头 1: 公式浮现

**画面提示词（英文）:**
```
A mathematical equation crystallizing into a spiral form, golden particles converging from edges to center, dark charcoal background #1a1a1a, muted grey-white tones #f5f5f5 with gold accents #d4af37, cinematic side lighting creating depth, shot on ARRI Alexa with anamorphic lenses, Aesop-inspired minimalism, shallow depth of field, 16:9 aspect ratio
```

**运镜提示词（中文）:**
```
镜头缓缓推近，金色粒子从画面边缘向中心汇聚，方程式从模糊逐渐凝结清晰
```

**色调参考:**
- 主色: #1a1a1a (深炭灰)
- 辅色: #f5f5f5 (米白)
- 点缀: #d4af37 (金)

**技术参数:**
- 设备: ARRI Alexa
- 镜头: Anamorphic
- 光线: Side lighting
- 景深: Shallow
EOF
    
    print_success "示例提示词已保存到: $OUTPUT/example-shot-1.md"
}

main "$@"
