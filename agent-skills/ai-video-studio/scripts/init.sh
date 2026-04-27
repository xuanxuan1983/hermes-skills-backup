#!/bin/bash
#
# AI Video Studio - 项目初始化脚本
# 一键创建项目结构和配置文件
#

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# 打印函数
print_header() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════╗"
    echo "║     🎬 AI Video Studio - 项目初始化          ║"
    echo "╚════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 使用说明
usage() {
    echo "用法: $0 <项目名称> [选项]"
    echo ""
    echo "选项:"
    echo "  --type TYPE       项目类型: ad-commercial(默认) | mv-music-video | product-showcase | social-short"
    echo "  --brand BRAND     品牌名称"
    echo "  --product PRODUCT 产品名称"
    echo "  --style STYLE     视觉风格: Aesop | Byredo | LeLabo | custom"
    echo ""
    echo "示例:"
    echo "  $0 equation-candle --brand Equation --product 香薰蜡烛 --style Aesop"
    echo "  $0 my-mv --type mv-music-video --brand MyBrand"
}

# 创建项目结构
create_project_structure() {
    local project_dir="$1"
    
    print_info "创建项目目录结构..."
    
    mkdir -p "$project_dir"/{scripts,assets/{images,videos,audio,fonts},output,docs}
    mkdir -p "$project_dir"/remotion/src
    mkdir -p "$project_dir"/remotion/public/{videos,audio}
    
    print_success "目录结构创建完成"
}

# 复制模板文件
copy_templates() {
    local project_dir="$1"
    local project_type="$2"
    
    print_info "复制模板文件..."
    
    # 复制 Remotion 模板
    cp "$SKILL_DIR/templates/remotion/VideoClip.tsx" "$project_dir/remotion/src/"
    cp "$SKILL_DIR/templates/remotion/Root.tsx" "$project_dir/remotion/src/"
    
    # 根据类型复制对应的广告模板
    case "$project_type" in
        ad-commercial)
            cp "$SKILL_DIR/templates/remotion/EquationAd.tsx" "$project_dir/remotion/src/Composition.tsx"
            ;;
        mv-music-video)
            # TODO: 创建 MV 模板
            cp "$SKILL_DIR/templates/remotion/EquationAd.tsx" "$project_dir/remotion/src/Composition.tsx"
            ;;
        *)
            cp "$SKILL_DIR/templates/remotion/EquationAd.tsx" "$project_dir/remotion/src/Composition.tsx"
            ;;
    esac
    
    # 复制 Provider 配置
    cp "$SKILL_DIR/config/providers.yaml" "$project_dir/config.yaml"
    
    print_success "模板文件复制完成"
}

# 创建 package.json
create_package_json() {
    local project_dir="$1"
    local project_name="$2"
    
    print_info "创建 package.json..."
    
    cat > "$project_dir/remotion/package.json" << 'EOF'
{
  "name": "ai-video-project",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "remotion studio",
    "build": "remotion render Composition out/video.mp4",
    "preview": "remotion preview Composition"
  },
  "dependencies": {
    "react": "^18.0.0",
    "react-dom": "^18.0.0",
    "remotion": "^4.0.0",
    "@remotion/cli": "^4.0.0"
  },
  "devDependencies": {
    "@types/react": "^18.0.0",
    "@types/node": "^20.0.0",
    "typescript": "^5.0.0"
  }
}
EOF
    
    print_success "package.json 创建完成"
}

# 创建项目配置文件
create_project_config() {
    local project_dir="$1"
    local brand="$2"
    local product="$3"
    local style="$4"
    local project_type="$5"
    
    print_info "创建项目配置..."
    
    cat > "$project_dir/project.json" << EOF
{
  "name": "$(basename "$project_dir")",
  "type": "$project_type",
  "brand": "$brand",
  "product": "$product",
  "style": "$style",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "steps": {
    "script": { "status": "pending", "output": "./assets/script.json" },
    "prompts": { "status": "pending", "output": "./assets/prompts/" },
    "images": { "status": "pending", "output": "./assets/images/" },
    "videos": { "status": "pending", "output": "./assets/videos/" },
    "audio": { "status": "pending", "output": "./assets/audio/" },
    "composition": { "status": "pending", "output": "./output/final.mp4" }
  }
}
EOF
    
    print_success "项目配置创建完成"
}

# 创建 README
create_readme() {
    local project_dir="$1"
    local brand="$2"
    local product="$3"
    
    cat > "$project_dir/README.md" << EOF
# $(basename "$project_dir")

品牌: ${brand:-未指定}
产品: ${product:-未指定}

## 项目结构

\`\`\`
.
├── assets/
│   ├── script.json       # 剧本
│   ├── prompts/          # 提示词
│   ├── images/           # 静态帧
│   ├── videos/           # 视频片段
│   └── audio/            # 配音和音效
├── remotion/
│   ├── src/
│   │   ├── VideoClip.tsx    # 视频组件
│   │   ├── Composition.tsx  # 主合成
│   │   └── Root.tsx         # 入口
│   └── package.json
├── output/               # 最终输出
├── docs/                 # 文档
├── config.yaml           # Provider 配置
└── project.json          # 项目状态
\`\`\`

## 快速开始

### 1. 生成剧本
\`\`\`bash
bash scripts/generate-script.sh
\`\`\`

### 2. 生成提示词
\`\`\`bash
bash scripts/generate-prompts.sh
\`\`\`

### 3. 完整工作流
\`\`\`bash
bash scripts/workflow.sh --step all
\`\`\`

## 手动步骤

### 生图
使用 Midjourney/即梦生成静态帧，保存到 \`assets/images/\`

### 图生视频
使用即梦 API 生成视频片段，保存到 \`assets/videos/\`

### 配音
使用 ElevenLabs 生成配音，保存到 \`assets/audio/\`

### 合成
\`\`\`bash
cd remotion
npm install
npx remotion studio        # 预览
npx remotion render Composition out/video.mp4  # 渲染
\`\`\`
EOF
}

# 主函数
main() {
    # 检查参数
    if [ $# -lt 1 ]; then
        usage
        exit 1
    fi
    
    PROJECT_NAME="$1"
    shift
    
    # 默认参数
    PROJECT_TYPE="ad-commercial"
    BRAND=""
    PRODUCT=""
    STYLE="Aesop"
    
    # 解析参数
    while [ $# -gt 0 ]; do
        case "$1" in
            --type)
                PROJECT_TYPE="$2"
                shift 2
                ;;
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
            -h|--help)
                usage
                exit 0
                ;;
            *)
                print_error "未知参数: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # 项目目录
    PROJECT_DIR="$(pwd)/$PROJECT_NAME"
    
    # 检查目录是否已存在
    if [ -d "$PROJECT_DIR" ]; then
        print_error "目录已存在: $PROJECT_DIR"
        read -p "是否覆盖? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
        rm -rf "$PROJECT_DIR"
    fi
    
    print_header
    print_info "项目名称: $PROJECT_NAME"
    print_info "项目类型: $PROJECT_TYPE"
    [ -n "$BRAND" ] && print_info "品牌: $BRAND"
    [ -n "$PRODUCT" ] && print_info "产品: $PRODUCT"
    print_info "视觉风格: $STYLE"
    echo
    
    # 创建项目
    create_project_structure "$PROJECT_DIR"
    copy_templates "$PROJECT_DIR" "$PROJECT_TYPE"
    create_package_json "$PROJECT_DIR" "$PROJECT_NAME"
    create_project_config "$PROJECT_DIR" "$BRAND" "$PRODUCT" "$STYLE" "$PROJECT_TYPE"
    create_readme "$PROJECT_DIR" "$BRAND" "$PRODUCT"
    
    # 创建脚本软链接
    ln -sf "$SKILL_DIR/scripts/generate-script.sh" "$PROJECT_DIR/scripts/"
    ln -sf "$SKILL_DIR/scripts/generate-prompts.sh" "$PROJECT_DIR/scripts/"
    ln -sf "$SKILL_DIR/scripts/workflow.sh" "$PROJECT_DIR/scripts/"
    
    print_success "项目创建成功: $PROJECT_DIR"
    echo
    echo -e "${CYAN}下一步:${NC}"
    echo "  cd $PROJECT_NAME"
    echo "  bash scripts/generate-script.sh"
    echo
}

main "$@"
