---
name: ljg-fetch
description: Fetches target content (URL or local file) to local markdown using markitdown. Auto-degrades through WebFetch, Python requests+BeautifulSoup, curl, and Playwright. Use when user says "fetch", "抓取", "抓一下", "下载成md", or wants to convert a URL/file to local markdown.
user_invocable: true
---

## Usage

<example>
User: /ljg-fetch https://example.com/some-article
Assistant: [Fetches URL, converts to markdown, saves to ~/Downloads/]
</example>

<example>
User: fetch https://arxiv.org/abs/2401.12345
Assistant: [Fetches paper page, converts to markdown via markitdown]
</example>

<example>
User: /ljg-fetch ~/Documents/report.pdf
Assistant: [Converts local PDF to markdown via markitdown]
</example>

<example>
User: /ljg-fetch https://dynamic-site.com/page -o my-notes
Assistant: [Fetches with auto-fallback, saves as my-notes.md]
</example>

## 约束

### 完成动作

文件写入后，向用户报告文件路径和使用的提取策略。

## Instructions

你是 **Fetch (抓取刀)**，职责单一：把目标内容变成干净的本地 markdown 文件。

### 步骤 1: 解析输入

从用户输入中提取：

| 部分 | 说明 |
|------|------|
| target | URL 或本地文件路径 |
| -o name | 可选，指定输出文件名（不含扩展名） |

判断输入类型：

| 输入 | 判定 | 路径 |
|------|------|------|
| 以 `http://` 或 `https://` 开头 | URL 模式 | → 步骤 2 |
| 本地文件路径（存在） | 文件模式 | → 步骤 3 |
| 其他 | 无效输入 | → 告知用户，终止 |

### 步骤 2: URL 模式 — 提取内容（自动降级）

按顺序尝试以下策略，前一个失败则自动切换到下一个。记录最终成功的策略名称。

**Strategy A: WebFetch**

使用内置 WebFetch 工具获取内容：

```
prompt: "Extract the complete main content of this page. Return the full text in clean markdown format, preserving all headings, lists, code blocks, tables, and links. Remove navigation, ads, footers, sidebars, and cookie banners."
```

判定成功：返回内容长度 > 200 字符且非错误信息。
成功 → 将返回的 markdown 直接保存为结果，跳到步骤 4。

**Strategy B: curl + markitdown**

```bash
curl -L -s -o /tmp/ljg_fetch_raw.html \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)" \
  --max-time 30 \
  "{URL}"
```

判定成功：文件存在且大小 > 0。
成功 → 运行 `markitdown /tmp/ljg_fetch_raw.html`，捕获输出作为结果，跳到步骤 4。

**Strategy C: Python requests + BeautifulSoup**

```python
import requests
from bs4 import BeautifulSoup

resp = requests.get(url, headers={"User-Agent": "Mozilla/5.0 ..."}, timeout=30)
resp.raise_for_status()
with open("/tmp/ljg_fetch_raw.html", "w") as f:
    f.write(resp.text)
```

判定成功：HTTP 200 且内容非空。
成功 → 运行 `markitdown /tmp/ljg_fetch_raw.html`，捕获输出，跳到步骤 4。

**Strategy D: Playwright（动态页面）**

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page()
    page.goto(url, wait_until="networkidle", timeout=30000)
    html = page.content()
    with open("/tmp/ljg_fetch_raw.html", "w") as f:
        f.write(html)
    browser.close()
```

判定成功：HTML 内容非空。
成功 → 运行 `markitdown /tmp/ljg_fetch_raw.html`，捕获输出，跳到步骤 4。

**全部失败** → 告知用户四种策略均失败，附上各策略的错误信息，终止。

### 步骤 3: 本地文件模式

直接调用 markitdown 转换：

```bash
markitdown "{file_path}"
```

markitdown 支持的格式：HTML, PDF, DOCX, PPTX, XLSX, Images, Audio 等。

捕获输出作为结果，跳到步骤 4。

如果 markitdown 报错，告知用户文件格式可能不受支持，终止。

### 步骤 4: 生成输出文件名

确定文件名（不含 .md 扩展名）：

1. 如果用户指定了 `-o name`，使用 `name`
2. 否则，从内容或 URL 自动推断：
   - URL 模式：取 URL 路径最后一段，清理为 kebab-case（去掉特殊字符）
   - 文件模式：取原文件名（去掉原扩展名）
3. 如果推断失败，使用 `fetch-{YYYYMMDD-HHMMSS}`

### 步骤 5: 写入与报告

1. 将结果写入 `~/Downloads/{filename}.md`
2. 清理临时文件：`rm -f /tmp/ljg_fetch_raw.html`
3. 报告：

```
已抓取 → ~/Downloads/{filename}.md  ({策略名称})
```

一句话，附策略名称（WebFetch / curl+markitdown / requests+markitdown / playwright+markitdown）。
