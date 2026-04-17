#!/bin/bash
#
# AI Video Studio - 完整工作流脚本
# 串联 6 步，一键出片
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════╗"
    echo "║     🎬 AI Video Studio - 完整工作流          ║"
    echo "╚════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "${BLUE}▶ $1${NC}"
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

# 使用说明
usage() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --step STEP       执行步骤: all | script | prompts | images | videos | audio | composition"
    echo "  --project DIR     项目目录 (默认当前目录)"
    echo "  --check           检查项目状态和依赖"
    echo "  --status          显示项目进度"
    echo ""
    echo "示例:"
    echo "  $0 --step all                    # 执行完整工作流"
    echo "  $0 --step script                 # 只生成剧本"
    echo "  $0 --step composition            # 只执行合成"
    echo "  $0 --check                       # 检查项目状态"
    echo "  $0 --status                      # 显示进度"
}

# 检查项目状态
check_status() {
    local project_dir="$1"
    
    echo -e "${CYAN}项目状态检查${NC}"
    echo "=========================================="
    
    # 检查必要文件
    local checks=(
        "project.json:项目配置"
        "assets/script.json:剧本"
        "assets/prompts:提示词目录"
        "assets/images:图片目录"
        "assets/videos:视频目录"
        "assets/audio:音频目录"
        "remotion/src/Composition.tsx:Remotion合成"
    )
    
    for check in "${checks[@]}"; do
        local file="${check%%:*}"
        local name="${check##*:}"
        
        if [ -e "$project_dir/$file" ]; then
            print_success "$name: 已存在"
        else
            print_warning "$name: 未找到"
        fi
    done
    
    echo
    echo -e "${CYAN}资源统计${NC}"
    echo "=========================================="
    
    # 统计资源
    local img_count=$(find "$project_dir/assets/images" -type f \( -name "*.jpg" -o -name "*.png" \) 2>/dev/null | wc -l)
    local video_count=$(find "$project_dir/assets/videos" -type f -name "*.mp4" 2>/dev/null | wc -l)
    local audio_count=$(find "$project_dir/assets/audio" -type f \( -name "*.mp3" -o -name "*.wav" \) 2>/dev/null | wc -l)
    
    echo "图片: $img_count 张"
    echo "视频: $video_count 个"
    echo "音频: $audio_count 个"
    
    echo
}

# 步骤 1: 生成剧本
step_script() {
    print_step "步骤 1/6: 生成剧本"
    
    if [ -f "./scripts/generate-script.sh" ]; then
        bash ./scripts/generate-script.sh "$@"
    else
        print_error "generate-script.sh 未找到"
        return 1
    fi
}

# 步骤 2: 生成提示词
step_prompts() {
    print_step "步骤 2/6: 生成提示词"
    
    if [ -f "./scripts/generate-prompts.sh" ]; then
        bash ./scripts/generate-prompts.sh "$@"
    else
        print_error "generate-prompts.sh 未找到"
        return 1
    fi
}

# 步骤 3: 检查静态帧
step_images() {
    print_step "步骤 3/6: 检查静态帧"
    
    local img_count=$(find ./assets/images -type f \( -name "*.jpg" -o -name "*.png" \) 2>/dev/null | wc -l)
    
    if [ "$img_count" -eq 0 ]; then
        print_warning "未找到静态帧图片"
        echo
        echo "请使用 Midjourney/即梦 生成图片，保存到 ./assets/images/"
        echo "建议生成 8-10 张，然后筛选最好的 5-6 张"
        echo
        echo "命名规范:"
        echo "  01_equations.png    (公式浮现)"
        echo "  02_particles.png    (粒子汇聚)"
        echo "  03_product.png      (产品展示)"
        echo "  ..."
        return 1
    else
        print_success "找到 $img_count 张图片"
        ls -1 ./assets/images/
    fi
}

# 步骤 4: 检查视频片段
step_videos() {
    print_step "步骤 4/6: 检查视频片段"
    
    local video_count=$(find ./assets/videos -type f -name "*.mp4" 2>/dev/null | wc -l)
    
    if [ "$video_count" -eq 0 ]; then
        print_warning "未找到视频片段"
        echo
        echo "请使用即梦 API 生成视频，保存到 ./assets/videos/"
        echo
        echo "命名规范:"
        echo "  01_equations.mp4    (公式浮现)"
        echo "  02_particles.mp4    (粒子汇聚)"
        echo "  03_product.mp4      (产品展示)"
        echo "  ..."
        echo
        echo "提示: 每个静态帧生成 5 秒视频片段"
        return 1
    else
        print_success "找到 $video_count 个视频片段"
        ls -1 ./assets/videos/
    fi
}

# 步骤 5: 检查音频
step_audio() {
    print_step "步骤 5/6: 检查音频"
    
    local audio_count=$(find ./assets/audio -type f \( -name "*.mp3" -o -name "*.wav" \) 2>/dev/null | wc -l)
    
    if [ "$audio_count" -eq 0 ]; then
        print_warning "未找到音频文件"
        echo
        echo "请使用 ElevenLabs 生成配音和音效，保存到 ./assets/audio/"
        echo
        echo "文件结构:"
        echo "  ./assets/audio/"
        echo "    ├── voiceover_01.mp3    (配音)"
        echo "    ├── voiceover_02.mp3"
        echo "    ├── sfx_01.mp3          (音效)"
        echo "    └── bgm.mp3             (背景音乐)"
        return 1
    else
        print_success "找到 $audio_count 个音频文件"
        ls -1 ./assets/audio/
    fi
}

# 步骤 6: Remotion 合成
step_composition() {
    print_step "步骤 6/6: Remotion 合成"
    
    if [ ! -d "./remotion" ]; then
        print_error "Remotion 目录不存在"
        return 1
    fi
    
    cd ./remotion
    
    # 检查 node_modules
    if [ ! -d "./node_modules" ]; then
        print_info "安装依赖..."
        npm install
    fi
    
    # 复制资源到 public 目录
    print_info "复制资源..."
    mkdir -p public/videos public/audio
    
    if [ -d "../assets/videos" ]; then
        cp ../assets/videos/* public/videos/ 2>/dev/null || true
    fi
    
    if [ -d "../assets/audio" ]; then
        cp ../assets/audio/* public/audio/ 2>/dev/null || true
    fi
    
    print_success "资源复制完成"
    echo
    
    # 预览或渲染
    echo -e "${CYAN}选择操作:${NC}"
    echo "1) 预览 (npx remotion studio)"
    echo "2) 渲染 (npx remotion render Composition out/video.mp4)"
    echo "3) 跳过"
    
    read -p "> " choice
    
    case "$choice" in
        1)
            print_info "启动预览服务器..."
            npx remotion studio
            ;;
        2)
            print_info "开始渲染..."
            npx remotion render Composition out/video.mp4
            print_success "渲染完成: out/video.mp4"
            ;;
        *)
            print_info "跳过合成"
            ;;
    esac
    
    cd ..
}

# 主函数
main() {
    STEP=""
    PROJECT_DIR="."
    
    # 解析参数
    while [ $# -gt 0 ]; do
        case "$1" in
            --step)
                STEP="$2"
                shift 2
                ;;
            --project)
                PROJECT_DIR="$2"
                shift 2
                ;;
            --check)
                check_status "$PROJECT_DIR"
                exit 0
                ;;
            --status)
                check_status "$PROJECT_DIR"
                exit 0
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
    
    # 切换到项目目录
    cd "$PROJECT_DIR"
    
    # 检查项目目录
    if [ ! -f "./project.json" ]; then
        print_error "这不是一个 AI Video Studio 项目"
        echo "请先运行: bash skills/ai-video-studio/scripts/init.sh <项目名>"
        exit 1
    fi
    
    print_header
    
    # 读取项目信息
    PROJECT_NAME=$(cat ./project.json | grep -o '"name": "[^"]*"' | head -1 | cut -d'"' -f4)
    echo -e "${CYAN}项目: $PROJECT_NAME${NC}"
    echo
    
    # 执行步骤
    case "$STEP" in
        all)
            step_script
            step_prompts
            step_images
            step_videos
            step_audio
            step_composition
            ;;
        script)
            step_script
            ;;
        prompts)
            step_prompts
            ;;
        images)
            step_images
            ;;
        videos)
            step_videos
            ;;
        audio)
            step_audio
            ;;
        composition)
            step_composition
            ;;
        "")
            check_status "$PROJECT_DIR"
            echo
            usage
            exit 0
            ;;
        *)
            print_error "未知步骤: $STEP"
            usage
            exit 1
            ;;
    esac
    
    echo
    print_success "工作流执行完成!"
}

main "$@"
