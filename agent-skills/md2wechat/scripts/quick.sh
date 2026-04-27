#!/bin/bash
#
# md2wechat - Quick Mode
# 快速模式：使用默认参数，一行命令完成
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_SH="${SCRIPT_DIR}/run.sh"

# 颜色
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

# 用法
usage() {
    echo "用法: $0 <markdown文件> [选项]"
    echo ""
    echo "选项:"
    echo "  --ai          使用 AI 模式（默认 API 模式）"
    echo "  --theme NAME  指定主题（默认: default）"
    echo "  --draft       上传到草稿箱"
    echo "  --cover PATH  指定封面图片"
    echo ""
    echo "示例:"
    echo "  $0 article.md                    # API 模式预览"
    echo "  $0 article.md --ai               # AI 模式预览"
    echo "  $0 article.md --draft            # 上传到草稿箱"
    echo "  $0 article.md --ai --draft --cover cover.jpg"
}

# 检查参数
if [ $# -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
    exit 0
fi

FILE="$1"
shift

# 检查文件
if [ ! -f "$FILE" ]; then
    echo "❌ 文件不存在: $FILE"
    exit 1
fi

# 默认参数
MODE=""
THEME=""
DRAFT=""
COVER=""

# 解析参数
while [ $# -gt 0 ]; do
    case "$1" in
        --ai)
            MODE="--mode ai"
            shift
            ;;
        --theme)
            THEME="--theme $2"
            shift 2
            ;;
        --draft)
            DRAFT="--draft"
            shift
            ;;
        --cover)
            COVER="--cover $2"
            shift 2
            ;;
        *)
            echo "❌ 未知参数: $1"
            usage
            exit 1
            ;;
    esac
done

# 构建命令
CMD="\"$RUN_SH\" convert \"$FILE\" $MODE $THEME $DRAFT $COVER"

echo -e "${CYAN}📝 Markdown to WeChat${NC}"
echo ""
echo "文件: $FILE"
[ -n "$MODE" ] && echo "模式: AI" || echo "模式: API"
[ -n "$THEME" ] && echo "主题: $THEME"
[ -n "$DRAFT" ] && echo "输出: 上传草稿箱" || echo "输出: 本地预览"
[ -n "$COVER" ] && echo "封面: $COVER"
echo ""

# 执行
eval "$CMD"

echo ""
echo -e "${GREEN}✅ 完成!${NC}"
