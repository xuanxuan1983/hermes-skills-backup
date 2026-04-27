#!/bin/bash
# 测试交互式脚本的各个功能

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== 测试交互式脚本功能 ==="
echo ""

# 测试1: 文件发现
echo "1. 测试文件发现:"
bash -c '
find_recent_md_files() {
    local files=()
    while IFS= read -r file; do
        files+=("$file")
    done < <(find . -maxdepth 1 -name "*.md" -type f -mtime -7 2>/dev/null | head -5)
    printf "  - %s\n" "${files[@]}"
}
find_recent_md_files
'
echo ""

# 测试2: 检查配置
echo "2. 检查 WeChat 配置:"
if [ -n "$WECHAT_APPID" ]; then
    echo "  ✓ WECHAT_APPID 已设置"
else
    echo "  ✗ WECHAT_APPID 未设置"
fi

if [ -n "$WECHAT_SECRET" ]; then
    echo "  ✓ WECHAT_SECRET 已设置"
else
    echo "  ✗ WECHAT_SECRET 未设置"
fi
echo ""

# 测试3: 检查 run.sh
echo "3. 检查 run.sh:"
if [ -f "$SCRIPT_DIR/run.sh" ]; then
    echo "  ✓ run.sh 存在"
    head -5 "$SCRIPT_DIR/run.sh" | sed 's/^/    /'
else
    echo "  ✗ run.sh 不存在"
fi
echo ""

echo "=== 测试完成 ==="
