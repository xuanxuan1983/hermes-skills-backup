#!/usr/bin/env python3
"""
PDF 提取工具
功能：将学术论文 PDF 转换为 Markdown（保留结构），并提取内嵌图像
"""

import sys
import os
import argparse
import pathlib
import shutil
import urllib.request
from datetime import datetime

try:
    import pymupdf4llm
except ImportError:
    print("错误: 未安装 pymupdf4llm 库")
    print("请运行: pip install pymupdf4llm")
    sys.exit(1)


# 固定输出目录：/Users/xuan/Documents/项目/好用的skills/paper_output/
PAPER_OUTPUT_BASE = pathlib.Path("/Users/xuan/Documents/项目/好用的skills/paper_output")


def download_pdf(url, output_path):
    """下载 PDF 文件"""
    print(f"⬇️  正在下载: {url}")
    try:
        urllib.request.urlretrieve(url, output_path)
        print(f"✅ 下载完成: {output_path}")
        return True
    except Exception as e:
        print(f"❌ 下载失败: {e}")
        return False


def extract_content(pdf_path):
    """提取 PDF 内容为 Markdown 并保存图片"""

    # 1. 路径处理和智能定位
    # 判断是否是 URL
    if pdf_path.startswith('http://') or pdf_path.startswith('https://'):
        # 是 URL，下载到固定位置
        PAPER_OUTPUT_BASE.mkdir(parents=True, exist_ok=True)

        # 从 URL 提取文件名
        filename = pdf_path.split('/')[-1] or 'paper.pdf'
        if not filename.endswith('.pdf'):
            filename += '.pdf'

        source_path = PAPER_OUTPUT_BASE / filename

        # 下载 PDF
        if not download_pdf(url, source_path):
            sys.exit(1)
    else:
        # 是本地路径，不动它
        source_path = pathlib.Path(pdf_path).resolve()
        if not source_path.exists():
            print(f"❌ 文件不存在: {source_path}")
            sys.exit(1)

        if not source_path.suffix.lower() == '.pdf':
            print(f"⚠️  警告: 文件可能不是 PDF 格式")

    # 2. 确定输出目录（固定为 /Users/xuan/Documents/项目/好用的skills/paper_output/论文名/）
    PAPER_OUTPUT_BASE.mkdir(parents=True, exist_ok=True)
    # 用PDF文件名（不含扩展名）作为子文件夹名
    base_out = PAPER_OUTPUT_BASE / source_path.stem

    images_out = base_out / "images"
    os.makedirs(images_out, exist_ok=True)

    print(f"\n📄 正在处理: {source_path.name}")
    print(f"📁 输出目录: {base_out}")
    print(f"🖼️  图片目录: {images_out}\n")

    try:
        # 3. 执行提取
        print("⏳ 正在提取内容...")
        md_text = pymupdf4llm.to_markdown(
            doc=str(source_path),
            write_images=True,
            image_path=str(images_out),
            image_format="png",
            show_progress=False
        )

        # 4. 修正图片路径为绝对路径
        # pymupdf4llm生成的可能包含绝对路径，我们需要确保使用一致的绝对路径
        # 这样Markdown文档无论放在哪里都能正确显示图片
        import re
        # 匹配图片路径的正则表达式，确保使用绝对路径
        # 替换为: ![](/绝对路径/images/xxx.png)
        md_text_fixed = re.sub(
            r'!\[\]\(([^)]+images/[^)]+)\)',
            lambda m: f'![]({str(images_out / pathlib.Path(m.group(1)).name)})',
            md_text
        )

        # 5. 保存 Markdown
        output_md_file = base_out / f"{source_path.stem}_content.md"
        output_md_file.write_bytes(md_text_fixed.encode('utf-8'))

        # 6. 统计信息
        image_count = len(list(images_out.glob("*.png")))
        word_count = len(md_text.split())

        # 7. 输出结果（使用特殊标记便于 Claude 识别）
        print("\n" + "="*50)
        print("✅ 提取成功！")
        print("="*50)
        print(f"📝 Markdown 文件: {output_md_file}")
        print(f"🖼️  提取图片数量: {image_count}")
        print(f"📊 文本字数: {word_count:,}")
        print(f"📂 图片目录: {images_out}")
        print("\n" + "="*50)
        print(f"RESULT_MD_PATH::{output_md_file}")
        print(f"RESULT_IMAGES_DIR::{images_out}")
        print("="*50 + "\n")

        return {
            "markdown_file": str(output_md_file),
            "images_dir": str(images_out),
            "image_count": image_count,
            "word_count": word_count
        }

    except Exception as e:
        print(f"\n❌ 处理失败: {e}")
        sys.exit(1)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="PDF 论文内容提取工具（支持图片提取）",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  %(prog)s paper.pdf
  %(prog)s ~/Downloads/nature_paper.pdf
注意: 输出固定保存在 /Users/xuan/Documents/项目/好用的skills/paper_output/论文名/
        """
    )

    parser.add_argument(
        "pdf_path",
        help="PDF 文件路径或 URL"
    )

    # 固定输出目录，不再接受 --out 参数
    args = parser.parse_args()
    extract_content(args.pdf_path)
