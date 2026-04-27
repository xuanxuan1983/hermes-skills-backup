#!/bin/bash
#
# md2wechat - Interactive Mode
# 交互式引导脚本，简化使用流程
#

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_SH="${SCRIPT_DIR}/run.sh"
CONFIG_FILE="${HOME}/.config/md2wechat/config.yaml"

# =============================================================================
# 工具函数
# =============================================================================

print_header() {
    echo ""
    echo -e "${CYAN}📝 Markdown to WeChat${NC}"
    echo -e "${CYAN}─────────────────────${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# 读取用户输入（带默认值）
read_input() {
    local prompt="$1"
    local default="$2"
    local result
    
    if [ -n "$default" ]; then
        echo -ne "${prompt} [${default}]: "
    else
        echo -ne "${prompt}: "
    fi
    
    read result
    echo "${result:-$default}"
}

# 选择菜单
select_option() {
    local prompt="$1"
    shift
    local options=("$@")
    local count=${#options[@]}
    
    echo -e "${BLUE}${prompt}${NC}"
    for i in "${!options[@]}"; do
        echo "  $((i+1))) ${options[$i]}"
    done
    
    while true; do
        local choice=$(read_input "> " "")
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ]; then
            echo "$choice"
            return
        fi
        print_error "请输入 1-${count} 之间的数字"
    done
}

# =============================================================================
# 配置检测
# =============================================================================

check_wechat_config() {
    local has_appid=false
    local has_secret=false
    
    if [ -n "$WECHAT_APPID" ]; then
        has_appid=true
    elif [ -f "$CONFIG_FILE" ] && grep -q "appid:" "$CONFIG_FILE" 2>/dev/null; then
        has_appid=true
    fi
    
    if [ -n "$WECHAT_SECRET" ]; then
        has_secret=true
    elif [ -f "$CONFIG_FILE" ] && grep -q "secret:" "$CONFIG_FILE" 2>/dev/null; then
        has_secret=true
    fi
    
    if [ "$has_appid" = true ] && [ "$has_secret" = true ]; then
        return 0
    else
        return 1
    fi
}

show_config_help() {
    echo ""
    print_warning "未检测到微信公众号配置"
    echo ""
    echo "上传草稿箱需要配置以下环境变量："
    echo "  export WECHAT_APPID=\"your-appid\""
    echo "  export WECHAT_SECRET=\"your-secret\""
    echo ""
    echo "或在配置文件中设置："
    echo "  ~/.config/md2wechat/config.yaml"
    echo ""
    echo "获取方式："
    echo "  1. 访问 https://developers.weixin.qq.com/platform"
    echo "  2. 登录并选择你的公众号"
    echo "  3. 设置与开发 → 基本配置 → 开发者ID"
    echo ""
}

# =============================================================================
# 文件发现
# =============================================================================

find_recent_md_files() {
    local max_results=5
    local files=()
    
    # 在当前目录和常见文档目录查找
    local search_dirs=(. ./docs ./articles ./content ./posts)
    
    for dir in "${search_dirs[@]}"; do
        if [ -d "$dir" ]; then
            while IFS= read -r file; do
                files+=("$file")
            done < <(find "$dir" -maxdepth 2 -name "*.md" -type f -mtime -7 2>/dev/null | head -$max_results)
        fi
    done
    
    # 去重并返回
    printf '%s\n' "${files[@]}" | sort -u | head -$max_results
}

# =============================================================================
# 主流程
# =============================================================================

main() {
    print_header
    
    # 检查 run.sh 是否存在
    if [ ! -f "$RUN_SH" ]; then
        print_error "找不到 run.sh 脚本: $RUN_SH"
        exit 1
    fi
    
    # ========== 步骤 1: 选择文件 ==========
    echo -e "${BLUE}📄 选择 Markdown 文件:${NC}"
    
    local files=()
    while IFS= read -r file; do
        files+=("$file")
    done < <(find_recent_md_files)
    
    local file_options=()
    local file_paths=()
    
    for i in "${!files[@]}"; do
        file_options+=("$(basename "${files[$i]}")")
        file_paths+=("${files[$i]}")
    done
    
    file_options+=("输入其他路径...")
    
    local file_choice=$(select_option "" "${file_options[@]}")
    local selected_file
    
    if [ "$file_choice" -le "${#files[@]}" ]; then
        selected_file="${file_paths[$((file_choice-1))]}"
        print_info "已选择: $selected_file"
    else
        echo ""
        selected_file=$(read_input "请输入文件路径")
        if [ ! -f "$selected_file" ]; then
            print_error "文件不存在: $selected_file"
            exit 1
        fi
    fi
    
    echo ""
    
    # ========== 步骤 2: 选择模式 ==========
    echo -e "${BLUE}⚡ 选择处理模式:${NC}"
    local modes=(
        "API 模式 (快速，标准排版)"
        "AI 模式 (智能，精美主题)"
    )
    local mode_choice=$(select_option "" "${modes[@]}")
    local mode_arg=""
    [ "$mode_choice" = "2" ] && mode_arg="--mode ai"
    
    echo ""
    
    # ========== 步骤 3: 选择主题（AI 模式） ==========
    local theme_arg=""
    if [ "$mode_choice" = "2" ]; then
        echo -e "${BLUE}🎨 选择主题风格:${NC}"
        local themes=(
            "autumn-warm (暖橙色调，情感文学)"
            "spring-fresh (清新绿色，自然活力)"
            "ocean-calm (冷静蓝色，专业理性)"
        )
        local theme_choice=$(select_option "" "${themes[@]}")
        case "$theme_choice" in
            1) theme_arg="--theme autumn-warm" ;;
            2) theme_arg="--theme spring-fresh" ;;
            3) theme_arg="--theme ocean-calm" ;;
        esac
    else
        echo -e "${BLUE}🎨 选择主题风格:${NC}"
        local themes=(
            "default (默认，简洁专业)"
            "bytedance (字节风格，科技新闻)"
            "apple (苹果风格，极简主义)"
            "chinese (中式风格，传统文化)"
        )
        local theme_choice=$(select_option "" "${themes[@]}")
        case "$theme_choice" in
            1) theme_arg="--theme default" ;;
            2) theme_arg="--theme bytedance" ;;
            3) theme_arg="--theme apple" ;;
            4) theme_arg="--theme chinese" ;;
        esac
    fi
    
    echo ""
    
    # ========== 步骤 4: 选择输出方式 ==========
    echo -e "${BLUE}📤 选择输出方式:${NC}"
    local outputs=(
        "预览 HTML (本地查看)"
        "上传到微信公众号草稿箱"
    )
    local output_choice=$(select_option "" "${outputs[@]}")
    
    local draft_arg=""
    local cover_arg=""
    
    if [ "$output_choice" = "2" ]; then
        # 检查配置
        if ! check_wechat_config; then
            show_config_help
            local continue_anyway=$(read_input "是否继续生成 HTML 预览? (y/n)" "y")
            if [ "$continue_anyway" != "y" ]; then
                exit 0
            fi
            output_choice=1
        else
            draft_arg="--draft"
            
            # 询问封面图
            echo ""
            echo -e "${BLUE}🖼️  封面图片:${NC}"
            local cover_options=(
                "使用文章中的第一张图片"
                "指定封面图片路径"
                "不设置封面"
            )
            local cover_choice=$(select_option "" "${cover_options[@]}")
            
            case "$cover_choice" in
                2)
                    local cover_path=$(read_input "请输入封面图片路径")
                    if [ -f "$cover_path" ]; then
                        cover_arg="--cover $cover_path"
                    else
                        print_warning "封面图片不存在，将使用文章中的图片"
                    fi
                    ;;
            esac
        fi
    fi
    
    echo ""
    
    # ========== 步骤 5: 确认执行 ==========
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}📋 执行预览:${NC}"
    echo "  文件: $selected_file"
    echo "  模式: ${modes[$((mode_choice-1))]}"
    [ -n "$theme_arg" ] && echo "  主题: $theme_arg"
    if [ "$output_choice" = "2" ]; then
        echo "  输出: 上传到草稿箱"
    else
        echo "  输出: 本地预览"
    fi
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    local confirm=$(read_input "确认执行? (Y/n)" "Y")
    if [ "$confirm" != "Y" ] && [ "$confirm" != "y" ]; then
        print_info "已取消"
        exit 0
    fi
    
    # ========== 执行命令 ==========
    echo ""
    print_info "正在处理..."
    echo ""
    
    local cmd="\"$RUN_SH\" convert \"$selected_file\" $mode_arg $theme_arg $draft_arg $cover_arg"
    echo -e "${CYAN}执行命令:${NC}"
    echo "  $cmd"
    echo ""
    
    eval "$cmd"
    
    echo ""
    print_success "处理完成!"
}

# 运行主程序
main "$@"
