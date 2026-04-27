#!/bin/bash
#
# AI Video Studio - 剧本生成脚本
# 调用 Claude 生成镜头脚本
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 颜色
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# 使用说明
usage() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --brand BRAND       品牌名称"
    echo "  --product PRODUCT   产品名称"
    echo "  --style STYLE       视觉风格 (Aesop/Byredo/LeLabo)"
    echo "  --duration SECONDS  视频时长 (默认 30)"
    echo "  --shots NUMBER      镜头数量 (默认 5-6)"
    echo "  --output FILE       输出文件 (默认 ./assets/script.json)"
    echo ""
    echo "示例:"
    echo "  $0 --brand Equation --product 香薰蜡烛 --style Aesop"
}

# 生成剧本提示词
generate_prompt() {
    local brand="$1"
    local product="$2"
    local style="$3"
    local duration="$4"
    local shots="$5"
    
    cat << EOF
你是一个专业的广告创意导演。请为以下品牌创作一个 ${duration} 秒的品牌广告片剧本。

品牌信息：
- 品牌名: ${brand}
- 产品: ${product}
- 视觉风格: ${style} (参考 ${style} 的极简、高级感)

要求：
1. 共 ${shots} 个镜头，每个镜头 5-6 秒
2. 开头让画面先说话（前 5 秒无旁白）
3. 结尾一句品牌名收住
4. 不要每个镜头都有旁白，留白更高级
5. 英文配音更有大牌感

请输出 JSON 格式的镜头脚本：

{
  "title": "广告片标题",
  "brand": "${brand}",
  "product": "${product}",
  "style": "${style}",
  "duration": ${duration},
  "shots": [
    {
      "id": 1,
      "time": "0-5s",
      "description": "画面描述",
      "voiceover": "旁白（可为空）",
      "sound": "音效描述",
      "notes": "拍摄/制作注意事项"
    }
  ],
  "music": {
    "style": "音乐风格",
    "tempo": "节奏",
    "reference": "参考曲目"
  },
  "color_palette": {
    "primary": "主色调",
    "secondary": "辅色调",
    "accent": "点缀色"
  }
}

关键提示：
- 画面要有电影感，参考 ARRI Alexa 拍摄质感
- 色调统一，使用 ${style} 的品牌色彩语言
- 运镜简洁，一个镜头一个主要动作
EOF
}

# 主函数
main() {
    # 尝试从 project.json 读取配置
    if [ -f "$PROJECT_DIR/project.json" ]; then
        BRAND=$(cat "$PROJECT_DIR/project.json" | grep -o '"brand": "[^"]*"' | cut -d'"' -f4)
        PRODUCT=$(cat "$PROJECT_DIR/project.json" | grep -o '"product": "[^"]*"' | cut -d'"' -f4)
        STYLE=$(cat "$PROJECT_DIR/project.json" | grep -o '"style": "[^"]*"' | cut -d'"' -f4)
    fi
    
    # 默认值
    BRAND="${BRAND:-}"
    PRODUCT="${PRODUCT:-}"
    STYLE="${STYLE:-Aesop}"
    DURATION=30
    SHOTS=5
    OUTPUT="./assets/script.json"
    
    # 解析参数
    while [ $# -gt 0 ]; do
        case "$1" in
            --brand)
                BRAND="$2"
                shift 2
                ;;
            --product)
                PRODUCT="$2"
                shift 2
                ;;
            --style)
                STYLE="$2"
                shift 2
                ;;
            --duration)
                DURATION="$2"
                shift 2
                ;;
            --shots)
                SHOTS="$2"
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
    
    # 检查必要参数
    if [ -z "$BRAND" ] || [ -z "$PRODUCT" ]; then
        echo "请提供品牌和产品信息"
        usage
        exit 1
    fi
    
    print_info "生成剧本..."
    print_info "品牌: $BRAND"
    print_info "产品: $PRODUCT"
    print_info "风格: $STYLE"
    
    # 确保输出目录存在
    mkdir -p "$(dirname "$OUTPUT")"
    
    # 生成提示词
    PROMPT=$(generate_prompt "$BRAND" "$PRODUCT" "$STYLE" "$DURATION" "$SHOTS")
    
    # 输出提示词，让用户复制到 Claude
    echo
    echo "=========================================="
    echo "请复制以下提示词到 Claude:"
    echo "=========================================="
    echo
    echo "$PROMPT"
    echo
    echo "=========================================="
    echo
    
    # 保存提示词到临时文件
    echo "$PROMPT" > "$(dirname "$OUTPUT")/script-prompt.txt"
    print_success "提示词已保存到: $(dirname "$OUTPUT")/script-prompt.txt"
    
    echo
    print_info "操作步骤:"
    echo "1. 复制上面的提示词"
    echo "2. 粘贴到 Claude 对话"
    echo "3. 将生成的 JSON 保存到: $OUTPUT"
    echo
    print_info "或者运行: pbcopy < $(dirname "$OUTPUT")/script-prompt.txt"
}

main "$@"
