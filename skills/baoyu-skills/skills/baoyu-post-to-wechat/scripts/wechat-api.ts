import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { loadWechatExtendConfig, resolveAccount, loadCredentials } from "./wechat-extend-config.ts";
import {
  type WechatUploadAsset,
  prepareWechatBodyImageUpload,
  needsWechatBodyImageProcessing,
  detectImageFormatFromBuffer,
} from "./wechat-image-processor.ts";

interface AccessTokenResponse {
  access_token?: string;
  errcode?: number;
  errmsg?: string;
}

interface UploadResponse {
  media_id: string;
  url: string;
  errcode?: number;
  errmsg?: string;
}

interface PublishResponse {
  media_id?: string;
  errcode?: number;
  errmsg?: string;
}

interface ImageInfo {
  placeholder: string;
  localPath: string;
  originalPath: string;
}

interface MarkdownRenderResult {
  title: string;
  author: string;
  summary: string;
  htmlPath: string;
  contentImages: ImageInfo[];
}

type ArticleType = "news" | "newspic";

interface ArticleOptions {
  title: string;
  author?: string;
  digest?: string;
  content: string;
  thumbMediaId: string;
  articleType: ArticleType;
  imageMediaIds?: string[];
  needOpenComment?: number;
  onlyFansCanComment?: number;
}

const TOKEN_URL = "https://api.weixin.qq.com/cgi-bin/token";
const UPLOAD_BODY_IMG_URL = "https://api.weixin.qq.com/cgi-bin/media/uploadimg";
const UPLOAD_MATERIAL_URL = "https://api.weixin.qq.com/cgi-bin/material/add_material";
const DRAFT_URL = "https://api.weixin.qq.com/cgi-bin/draft/add";

async function fetchAccessToken(appId: string, appSecret: string): Promise<string> {
  const url = `${TOKEN_URL}?grant_type=client_credential&appid=${appId}&secret=${appSecret}`;
  const res = await fetch(url);
  if (!res.ok) {
    throw new Error(`Failed to fetch access token: ${res.status}`);
  }
  const data = await res.json() as AccessTokenResponse;
  if (data.errcode) {
    throw new Error(`Access token error ${data.errcode}: ${data.errmsg}`);
  }
  if (!data.access_token) {
    throw new Error("No access_token in response");
  }
  return data.access_token;
}

function toHttpsUrl(url: string | undefined): string {
  if (!url) return "";
  return url.startsWith("http://") ? url.replace(/^http:\/\//i, "https://") : url;
}

async function loadUploadAsset(
  imagePath: string,
  baseDir?: string,
): Promise<WechatUploadAsset> {
  let fileBuffer: Buffer;
  let filename: string;
  let contentType: string;
  let fileSize = 0;
  let fileExt = "";

  if (imagePath.startsWith("http://") || imagePath.startsWith("https://")) {
    const response = await fetch(imagePath);
    if (!response.ok) {
      throw new Error(`Failed to download image: ${imagePath}`);
    }
    const buffer = await response.arrayBuffer();
    if (buffer.byteLength === 0) {
      throw new Error(`Remote image is empty: ${imagePath}`);
    }
    fileBuffer = Buffer.from(buffer);
    fileSize = buffer.byteLength;
    const urlPath = imagePath.split("?")[0];
    filename = path.basename(urlPath) || "image.jpg";
    fileExt = path.extname(filename).toLowerCase();
    contentType = response.headers.get("content-type") || "image/jpeg";
  } else {
    const resolvedPath = path.isAbsolute(imagePath)
      ? imagePath
      : path.resolve(baseDir || process.cwd(), imagePath);

    if (!fs.existsSync(resolvedPath)) {
      throw new Error(`Image not found: ${resolvedPath}`);
    }
    const stats = fs.statSync(resolvedPath);
    if (stats.size === 0) {
      throw new Error(`Local image is empty: ${resolvedPath}`);
    }
    fileSize = stats.size;
    fileBuffer = fs.readFileSync(resolvedPath);
    filename = path.basename(resolvedPath);
    fileExt = path.extname(filename).toLowerCase();
    const mimeTypes: Record<string, string> = {
      ".jpg": "image/jpeg",
      ".jpeg": "image/jpeg",
      ".png": "image/png",
      ".gif": "image/gif",
      ".webp": "image/webp",
      ".bmp": "image/bmp",
      ".tiff": "image/tiff",
      ".tif": "image/tiff",
      ".svg": "image/svg+xml",
      ".ico": "image/x-icon",
    };
    contentType = mimeTypes[fileExt] || "image/jpeg";
  }

  // Detect actual format from magic bytes to fix extension/content-type mismatches
  // (e.g. CDNs serving WebP for URLs with .png extension)
  const detected = detectImageFormatFromBuffer(fileBuffer);
  if (detected && detected.contentType !== contentType) {
    console.error(`[wechat-api] Format mismatch: ${filename} declared as ${contentType}, actual ${detected.contentType}`);
    contentType = detected.contentType;
    fileExt = detected.fileExt;
    filename = `${path.basename(filename, path.extname(filename))}${detected.fileExt}`;
  }

  return {
    buffer: fileBuffer,
    filename,
    contentType,
    fileExt,
    fileSize,
  };
}

async function uploadImage(
  imagePath: string,
  accessToken: string,
  baseDir?: string,
  uploadType: "body" | "material" = "body"
): Promise<UploadResponse> {
  const asset = await loadUploadAsset(imagePath, baseDir);
  let uploadAsset = asset;

  if (uploadType === "body" && needsWechatBodyImageProcessing(asset)) {
    const prepared = await prepareWechatBodyImageUpload(asset);
    uploadAsset = {
      ...asset,
      buffer: prepared.buffer,
      filename: prepared.filename,
      contentType: prepared.contentType,
      fileExt: path.extname(prepared.filename).toLowerCase(),
      fileSize: prepared.buffer.length,
    };
    const note = prepared.processingNotes.join(", ");
    console.error(`[wechat-api] Processed ${asset.filename} for body upload: ${note}`);
  }

  const result = await uploadToWechat(
    uploadAsset.buffer,
    uploadAsset.filename,
    uploadAsset.contentType,
    accessToken,
    uploadType,
  );

  // media/uploadimg 接口只返回 URL，material/add_material 返回 media_id
  if (uploadType === "body") {
    return {
      url: toHttpsUrl(result.url),
      media_id: "",
    } as UploadResponse;
  } else {
    result.url = toHttpsUrl(result.url);
    return result;
  }
}

// 实际的微信上传函数
async function uploadToWechat(
  fileBuffer: Buffer,
  filename: string,
  contentType: string,
  accessToken: string,
  uploadType: "body" | "material"
): Promise<UploadResponse> {
  const boundary = `----WebKitFormBoundary${Date.now().toString(16)}`;
  const header = [
    `--${boundary}`,
    `Content-Disposition: form-data; name="media"; filename="${filename}"`,
    `Content-Type: ${contentType}`,
    "",
    "",
  ].join("\r\n");
  const footer = `\r\n--${boundary}--\r\n`;

  const headerBuffer = Buffer.from(header, "utf-8");
  const footerBuffer = Buffer.from(footer, "utf-8");
  const body = Buffer.concat([headerBuffer, fileBuffer, footerBuffer]);

  const uploadUrl = uploadType === "body" ? UPLOAD_BODY_IMG_URL : UPLOAD_MATERIAL_URL;
  const url = `${uploadUrl}?type=image&access_token=${accessToken}`;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": `multipart/form-data; boundary=${boundary}`,
    },
    body,
  });

  const data = await res.json() as UploadResponse;
  if (data.errcode && data.errcode !== 0) {
    throw new Error(`Upload failed ${data.errcode}: ${data.errmsg}`);
  }

  return data;
}

async function uploadImagesInHtml(
  html: string,
  accessToken: string,
  baseDir: string,
  contentImages: ImageInfo[] = [],
  articleType: ArticleType = "news",
  collectNewsCoverFallback: boolean = false,
): Promise<{ html: string; firstCoverMediaId: string; imageMediaIds: string[] }> {
  const imgRegex = /<img[^>]*\ssrc=["']([^"']+)["'][^>]*>/gi;
  const matches = [...html.matchAll(imgRegex)];

  if (matches.length === 0 && contentImages.length === 0) {
    return { html, firstCoverMediaId: "", imageMediaIds: [] };
  }

  let firstCoverMediaId = "";
  let updatedHtml = html;
  const imageMediaIds: string[] = [];
  const uploadedBySource = new Map<string, UploadResponse>();

  for (const match of matches) {
    const [fullTag, src] = match;
    if (!src) continue;

    if (src.startsWith("https://mmbiz.qpic.cn")) {
      if (collectNewsCoverFallback && !firstCoverMediaId) {
        try {
          const coverResp = await uploadImage(src, accessToken, baseDir, "material");
          firstCoverMediaId = coverResp.media_id;
        } catch (err) {
          console.error(`[wechat-api] Failed to reuse existing WeChat image as cover: ${src}`, err);
        }
      }
      continue;
    }

    const localPathMatch = fullTag.match(/data-local-path=["']([^"']+)["']/);
    const imagePath = localPathMatch ? localPathMatch[1]! : src;

    console.error(`[wechat-api] Uploading body image: ${imagePath}`);
    try {
      let resp = uploadedBySource.get(imagePath);
      if (!resp) {
        // 正文图片使用 media/uploadimg 接口获取 URL
        resp = await uploadImage(imagePath, accessToken, baseDir, "body");
        uploadedBySource.set(imagePath, resp);
      }
      const newTag = fullTag
        .replace(/\ssrc=["'][^"']+["']/, ` src="${resp.url}"`)
        .replace(/\sdata-local-path=["'][^"']+["']/, "");
      updatedHtml = updatedHtml.replace(fullTag, newTag);
      const shouldUploadMaterial = articleType === "newspic" || (collectNewsCoverFallback && !firstCoverMediaId);
      if (shouldUploadMaterial) {
        let materialResp = uploadedBySource.get(`${imagePath}:material`);
        if (!materialResp) {
          materialResp = await uploadImage(imagePath, accessToken, baseDir, "material");
          uploadedBySource.set(`${imagePath}:material`, materialResp);
        }
        if (articleType === "newspic" && materialResp.media_id) {
          imageMediaIds.push(materialResp.media_id);
        }
        if (collectNewsCoverFallback && !firstCoverMediaId && materialResp.media_id) {
          firstCoverMediaId = materialResp.media_id;
        }
      }
    } catch (err) {
      console.error(`[wechat-api] Failed to upload ${imagePath}:`, err);
    }
  }

  for (const image of contentImages) {
    if (!updatedHtml.includes(image.placeholder)) continue;

    const imagePath = image.localPath || image.originalPath;
    console.error(`[wechat-api] Uploading body image: ${imagePath}`);

    try {
      let resp = uploadedBySource.get(imagePath);
      if (!resp) {
        // 正文图片使用 media/uploadimg 接口获取 URL
        resp = await uploadImage(imagePath, accessToken, baseDir, "body");
        uploadedBySource.set(imagePath, resp);
      }

      const replacementTag = `<img src="${resp.url}" style="display: block; width: 100%; margin: 1.5em auto;">`;
      updatedHtml = replaceAllPlaceholders(updatedHtml, image.placeholder, replacementTag);
      const shouldUploadMaterial = articleType === "newspic" || (collectNewsCoverFallback && !firstCoverMediaId);
      if (shouldUploadMaterial) {
        let materialResp = uploadedBySource.get(`${imagePath}:material`);
        if (!materialResp) {
          materialResp = await uploadImage(imagePath, accessToken, baseDir, "material");
          uploadedBySource.set(`${imagePath}:material`, materialResp);
        }
        if (articleType === "newspic" && materialResp.media_id) {
          imageMediaIds.push(materialResp.media_id);
        }
        if (collectNewsCoverFallback && !firstCoverMediaId && materialResp.media_id) {
          firstCoverMediaId = materialResp.media_id;
        }
      }
    } catch (err) {
      console.error(`[wechat-api] Failed to upload placeholder ${image.placeholder}:`, err);
    }
  }

  return { html: updatedHtml, firstCoverMediaId, imageMediaIds };
}

async function publishToDraft(
  options: ArticleOptions,
  accessToken: string
): Promise<PublishResponse> {
  const url = `${DRAFT_URL}?access_token=${accessToken}`;

  let article: Record<string, unknown>;

  const noc = options.needOpenComment ?? 1;
  const ofcc = options.onlyFansCanComment ?? 0;

  if (options.articleType === "newspic") {
    if (!options.imageMediaIds || options.imageMediaIds.length === 0) {
      throw new Error("newspic requires at least one image");
    }
    article = {
      article_type: "newspic",
      title: options.title,
      content: options.content,
      need_open_comment: noc,
      only_fans_can_comment: ofcc,
      image_info: {
        image_list: options.imageMediaIds.map(id => ({ image_media_id: id })),
      },
    };
    if (options.author) article.author = options.author;
  } else {
    article = {
      article_type: "news",
      title: options.title,
      content: options.content,
      thumb_media_id: options.thumbMediaId,
      need_open_comment: noc,
      only_fans_can_comment: ofcc,
    };
    if (options.author) article.author = options.author;
    if (options.digest) article.digest = options.digest;
  }

  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ articles: [article] }),
  });

  const data = await res.json() as PublishResponse;
  if (data.errcode && data.errcode !== 0) {
    throw new Error(`Publish failed ${data.errcode}: ${data.errmsg}`);
  }

  return data;
}

function parseFrontmatter(content: string): { frontmatter: Record<string, string>; body: string } {
  const match = content.match(/^\s*---\r?\n([\s\S]*?)\r?\n---\r?\n?([\s\S]*)$/);
  if (!match) return { frontmatter: {}, body: content };

  const frontmatter: Record<string, string> = {};
  const lines = match[1]!.split("\n");
  for (const line of lines) {
    const colonIdx = line.indexOf(":");
    if (colonIdx > 0) {
      const key = line.slice(0, colonIdx).trim();
      let value = line.slice(colonIdx + 1).trim();
      if ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))) {
        value = value.slice(1, -1);
      }
      frontmatter[key] = value;
    }
  }

  return { frontmatter, body: match[2]! };
}

function renderMarkdownWithPlaceholders(
  markdownPath: string,
  theme: string = "default",
  color?: string,
  citeStatus: boolean = true,
  title?: string,
): MarkdownRenderResult {
  const __filename = fileURLToPath(import.meta.url);
  const __dirname = path.dirname(__filename);
  const mdToWechatScript = path.join(__dirname, "md-to-wechat.ts");
  const baseDir = path.dirname(markdownPath);

  const args = ["-y", "bun", mdToWechatScript, markdownPath];
  if (title) args.push("--title", title);
  if (theme) args.push("--theme", theme);
  if (color) args.push("--color", color);
  if (!citeStatus) args.push("--no-cite");

  console.error(`[wechat-api] Rendering markdown with placeholders via md-to-wechat: ${theme}${color ? `, color: ${color}` : ""}, citeStatus: ${citeStatus}`);
  const result = spawnSync("npx", args, {
    stdio: ["inherit", "pipe", "pipe"],
    cwd: baseDir,
  });

  if (result.status !== 0) {
    const stderr = result.stderr?.toString() || "";
    throw new Error(`Markdown placeholder render failed: ${stderr}`);
  }

  const stdout = result.stdout?.toString() || "";
  return JSON.parse(stdout) as MarkdownRenderResult;
}

function replaceAllPlaceholders(html: string, placeholder: string, replacement: string): string {
  const escapedPlaceholder = placeholder.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  return html.replace(new RegExp(escapedPlaceholder + "(?!\\d)", "g"), replacement);
}

function extractHtmlContent(htmlPath: string): string {
  const html = fs.readFileSync(htmlPath, "utf-8");
  const match = html.match(/<div id="output">([\s\S]*?)<\/div>\s*<\/body>/);
  if (match) {
    return match[1]!.trim();
  }
  const bodyMatch = html.match(/<body[^>]*>([\s\S]*?)<\/body>/i);
  return bodyMatch ? bodyMatch[1]!.trim() : html;
}

function printUsage(): never {
  console.log(`Publish article to WeChat Official Account draft using API

Usage:
  npx -y bun wechat-api.ts <file> [options]

Arguments:
  file                Markdown (.md) or HTML (.html) file

Options:
  --type <type>       Article type: news (文章, default) or newspic (图文)
  --title <title>     Override title
  --author <name>     Author name (max 16 chars)
  --summary <text>    Article summary/digest (max 128 chars)
  --theme <name>      Theme name for markdown (default, grace, simple, modern). Default: default
  --color <name|hex>  Primary color (blue, green, vermilion, etc. or hex)
  --cover <path>      Cover image path (local or URL)
  --account <alias>   Select account by alias (for multi-account setups)
  --template <name>    Template: auto (default), v29 (01/02/03编号), ny (纽约客插画版)
                       auto = 根据内容自动匹配适合的模板
  --cite             Enable bottom citations for external links (default)
  --no-cite           Disable bottom citations for ordinary external links in markdown mode
  --dry-run           Parse and render only, don't publish
  --help              Show this help

Frontmatter Fields (markdown):
  title               Article title
  author              Author name
  digest/summary      Article summary
  coverImage/featureImage/cover/image   Cover image path

Comments:
  Comments are enabled by default, open to all users.

Environment Variables:
  WECHAT_APP_ID       WeChat App ID
  WECHAT_APP_SECRET   WeChat App Secret

Config File Locations (in priority order):
  1. Environment variables
  2. <cwd>/.baoyu-skills/.env
  3. ~/.baoyu-skills/.env

Example:
  npx -y bun wechat-api.ts article.md
  npx -y bun wechat-api.ts article.md --theme grace --cover cover.png
  npx -y bun wechat-api.ts article.md --author "Author Name" --summary "Brief intro"
  npx -y bun wechat-api.ts article.html --title "My Article"
  npx -y bun wechat-api.ts images/ --type newspic --title "Photo Album"
  npx -y bun wechat-api.ts article.md --dry-run
  npx -y bun wechat-api.ts article.md --no-cite
`);
  process.exit(0);
}

interface CliArgs {
  filePath: string;
  isHtml: boolean;
  articleType: ArticleType;
  title?: string;
  author?: string;
  summary?: string;
  theme: string;
  color?: string;
  cover?: string;
  account?: string;
  citeStatus: boolean;
  dryRun: boolean;
  template: string; // 'auto' | 'v29' | 'ny'
}

function parseArgs(argv: string[]): CliArgs {
  if (argv.length === 0 || argv.includes("--help") || argv.includes("-h")) {
    printUsage();
  }

  const args: CliArgs = {
    filePath: "",
    isHtml: false,
    articleType: "news",
    theme: "default",
    citeStatus: true,
    dryRun: false,
    template: "auto",
  };

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i]!;
    if (arg === "--type" && argv[i + 1]) {
      const t = argv[++i]!.toLowerCase();
      if (t === "news" || t === "newspic") {
        args.articleType = t;
      }
    } else if (arg === "--title" && argv[i + 1]) {
      args.title = argv[++i];
    } else if (arg === "--author" && argv[i + 1]) {
      args.author = argv[++i];
    } else if (arg === "--summary" && argv[i + 1]) {
      args.summary = argv[++i];
    } else if (arg === "--theme" && argv[i + 1]) {
      args.theme = argv[++i]!;
    } else if (arg === "--color" && argv[i + 1]) {
      args.color = argv[++i];
    } else if (arg === "--cover" && argv[i + 1]) {
      args.cover = argv[++i];
    } else if (arg === "--account" && argv[i + 1]) {
      args.account = argv[++i];
    } else if (arg === "--cite") {
      args.citeStatus = true;
    } else if (arg === "--no-cite") {
      args.citeStatus = false;
    } else if (arg === "--dry-run") {
      args.dryRun = true;
    } else if (arg === "--template" && argv[i + 1]) {
      const t = argv[++i]!.toLowerCase();
      if (t === "auto" || t === "v29" || t === "ny") {
        args.template = t;
      } else {
        console.error(`[wechat-api] Unknown template: ${t}. Use auto, v29, or ny.`);
      }
    } else if (arg.startsWith("--") && argv[i + 1] && !argv[i + 1]!.startsWith("-")) {
      i++;
    } else if (!arg.startsWith("-")) {
      args.filePath = arg;
    }
  }

  if (!args.filePath) {
    console.error("Error: File path required");
    process.exit(1);
  }

  args.isHtml = args.filePath.toLowerCase().endsWith(".html");

  return args;
}

function extractHtmlTitle(html: string): string {
  const titleMatch = html.match(/<title>([^<]+)<\/title>/i);
  if (titleMatch) return titleMatch[1]!;
  const h1Match = html.match(/<h1[^>]*>([^<]+)<\/h1>/i);
  if (h1Match) return h1Match[1]!.replace(/<[^>]+>/g, "").trim();
  return "";
}

/**
 * Auto-detect which template suits the content.
 * v29  → numbered steps/sections (方法论/教程/框架类)，适合3-5节短文
 * ny   → narrative/opinion (随笔/观察/观点类)，或5节以上的长文
 */
function detectTemplate(markdown: string): string {
  // Count TOP-LEVEL H2 sections (lines that start with ## and are not inside a list/block)
  // Strategy: find all ## lines, filter out ones that appear inside code blocks or list items
  const allH2Lines = markdown.match(/^##\s+\S.*$/gm) || [];
  // Filter: reject headings that are inside ``` code blocks or are clearly list-item subheadings
  const topLevelH2 = allH2Lines.filter(line => {
    // Skip if preceded by > (blockquote) or ``` (code block) in same line vicinity
    if (line.includes('```')) return false;
    // Skip if it's clearly a list item heading like "## 一、[xxx]" pattern (common in nested frameworks)
    if (/^##\s+[零一二三四五六七八九十百千\d]+[.、][^a-zA-Z]/.test(line)) {
      // This might be a list sub-heading, not a real section — only count if it looks like a real section title
      // Real section titles are longer than 10 chars
      return line.length > 15;
    }
    return true;
  });
  const h2Count = topLevelH2.length;
  const charCount = markdown.length;

  // v29 signals: numbered headings or step/phase/method keywords
  const v29Headings = /^##\s*[\d零一二三四五六七八九十百千]+[.、，、]/m.test(markdown);
  const v29Steps = /第[一二三四五六七八九十百千]+[节步阶段]/.test(markdown);
  const v29Keywords = /##\s*(步|阶段|法则|攻略|手册|框架|模型|公式|清单|目录)/.test(markdown);
  const v29ListNumbers = /^\d+[.、]\s+\S/m.test(markdown);
  const v29Score = [v29Headings, v29Steps, v29Keywords, v29ListNumbers].filter(Boolean).length;

  // ny signals: first-person narrative, essay style, or long-form
  const nyEssayTitle = /^#\s+[^(]*[（(][^)）]*[)）]/.test(markdown);
  const nyNoNumbers = !v29Headings && !v29Steps;

  // Decision: v29 only for short articles (2-5 sections) with step/framework structure
  // 5+ sections → ny (even if structured, it's too long for v29's 01/02/03 format)
  const isV29Fit = h2Count >= 2 && h2Count <= 5 && v29Score >= 1;
  if (isV29Fit) return "v29";
  return "ny"; // everything else → ny
}

/**
 * Wraps md-to-wechat HTML output into the v29 template.
 * Extracts the inner content from md-to-wechat output and injects into v29 CSS wrapper.
 */
function wrapV29Simple(template: string, fullHtml: string, articleTitle: string): string {
  // Extract the <section class="container"> inner HTML from md-to-wechat output
  // This is the actual article content (without the outer <section class="container"> wrapper)
  const containerMatch = fullHtml.match(/<section class="container"[^>]*>([\s\S]*?)<\/section>\s*<\/div>/);
  const articleBody = containerMatch ? containerMatch[1]! : fullHtml;

  // Strip the author block from article body (to avoid duplication)
  const lastHrIdx = articleBody.lastIndexOf("<hr");
  const cleanBody = (lastHrIdx > 0 && articleBody.substring(lastHrIdx).includes("萱宜"))
    ? articleBody.substring(0, lastHrIdx).trim()
    : articleBody;

  // Estimate word count
  const wordCount = Math.round(cleanBody.replace(/<[^>]+>/g, "").length / 2);

  // Extract first paragraph as opening
  let openingText = "";
  const paraMatch = cleanBody.match(/<p[^>]*>([^<]{20,100})<\/p>/);
  if (paraMatch) openingText = paraMatch[1].replace(/<[^>]+>/g, "");

  // Extract highlighted quote (longest paragraph with strong)
  let quoteText = "";
  let maxLen = 0;
  const allParas = cleanBody.matchAll(/<p[^>]*>([\s\S]*?)<\/p>/g);
  for (const m of allParas) {
    const para = m[1] || "";
    if (para.includes("<strong") && para.length > maxLen) {
      const clean = para.replace(/<[^>]+>/g, "").trim();
      if (clean.length > 30) { quoteText = clean; maxLen = para.length; }
    }
  }

  // Build result: template with extracted content
  let result = template;
  result = result.replace("{{TITLE}}", articleTitle);
  result = result.replace("{{WORD_COUNT}}", `共 ${wordCount} 字 · 阅读约 ${Math.max(1, Math.round(wordCount / 300))} 分钟`);
  result = result.replace("{{OPENING}}", openingText || "判断力、审美、系统——这三点，才是真正不可替代的竞争力。");
  result = result.replace("{{QUOTE}}", quoteText || "你的判断力、审美、系统——这三点，才是真正不可替代的竞争力。");

  // Inject the clean article body into {{CONTENT}} of the v29 template
  result = result.replace("{{CONTENT}}", cleanBody);

  // Remove all section placeholders (S01-S03, EXTRA, etc.) since we're using full body injection
  result = result
    .replace(/<!-- ==================== S01[\s\S]*?<!-- ==================== S03[\s\S]*?-->/g, "")
    .replace(/<section style="padding:34px 28px;position:relative;z-index:1;" id="s\d">[\s\S]*?<\/section>\s*(<!-- 分隔细线 -->)?/g, "")
    .replace(/<div id="extra-sections">[\s\S]*?<\/div>/g, "");

  return result;
}

async function main(): Promise<void> {
  const args = parseArgs(process.argv.slice(2));

  const filePath = path.resolve(args.filePath);
  if (!fs.existsSync(filePath)) {
    console.error(`Error: File not found: ${filePath}`);
    process.exit(1);
  }

  const baseDir = path.dirname(filePath);
  let title = args.title || "";
  let author = args.author || "";
  let digest = args.summary || "";
  let htmlPath: string;
  let htmlContent: string;
  let frontmatter: Record<string, string> = {};
  let contentImages: ImageInfo[] = [];

  if (args.isHtml) {
    htmlPath = filePath;
    htmlContent = extractHtmlContent(htmlPath);
    const mdPath = filePath.replace(/\.html$/i, ".md");
    if (fs.existsSync(mdPath)) {
      const mdContent = fs.readFileSync(mdPath, "utf-8");
      const parsed = parseFrontmatter(mdContent);
      frontmatter = parsed.frontmatter;
      if (!title && frontmatter.title) title = frontmatter.title;
      if (!author) author = frontmatter.author || "";
      if (!digest) digest = frontmatter.digest || frontmatter.summary || frontmatter.description || "";
    }
    if (!title) {
      title = extractHtmlTitle(fs.readFileSync(htmlPath, "utf-8"));
    }
    console.error(`[wechat-api] Using HTML file: ${htmlPath}`);
  } else {
    const content = fs.readFileSync(filePath, "utf-8");
    const parsed = parseFrontmatter(content);
    frontmatter = parsed.frontmatter;
    const body = parsed.body;

    title = title || frontmatter.title || "";
    if (!title) {
      const h1Match = body.match(/^#\s+(.+)$/m);
      if (h1Match) title = h1Match[1]!;
    }
    if (!author) author = frontmatter.author || "";
    if (!digest) digest = frontmatter.digest || frontmatter.summary || frontmatter.description || "";

    console.error(`[wechat-api] Theme: ${args.theme}${args.color ? `, color: ${args.color}` : ""}, citeStatus: ${args.citeStatus}`);
    const rendered = renderMarkdownWithPlaceholders(filePath, args.theme, args.color, args.citeStatus, args.title);
    htmlPath = rendered.htmlPath;
    contentImages = rendered.contentImages;
    if (!title) title = rendered.title;
    if (!author) author = rendered.author;
    if (!digest) digest = rendered.summary;
    console.error(`[wechat-api] HTML generated: ${htmlPath}`);
    console.error(`[wechat-api] Placeholder images: ${contentImages.length}`);
    htmlContent = extractHtmlContent(htmlPath);

    // Strip author/footer block from rendered HTML to avoid duplication with wrapper's author section.
    // The author block always starts with the last <hr> at the end of the article content.
    // Strategy: find the last <hr> in the content, remove it and everything after it.
    // This handles the common pattern: ...content<hr class="hr">...author block...</section></div></body></html>
    const lastHrIdx = htmlContent.lastIndexOf("<hr");
    if (lastHrIdx > 0) {
      // Only strip if the content after hr contains known author-block patterns
      const afterHr = htmlContent.substring(lastHrIdx);
      if (afterHr.includes("萱宜") || afterHr.includes("声明")) {
        htmlContent = htmlContent.substring(0, lastHrIdx).trim();
      }
    }

    // Normalize md-to-wechat heading styles for v29 template
    // Strip the blue-pill display:table style from h2, replace with clean block style
    htmlContent = htmlContent
      .replace(/<h2([^>]*?)data-heading="true"([^>]*?)>/gi, (match, before, after) => {
        // Extract inner text from inside the h2 tags
        const innerMatch = match.match(/>([^<]+)</);
        const text = innerMatch ? innerMatch[1] : "";
        return `<h2 style="display:block;padding:0;margin:2em 0 1em;font-size:18px;font-weight:bold;color:#111;letter-spacing:0.5px;line-height:1.4;background:none;">${text}</h2>`;
      })
      .replace(/<h3([^>]*?)data-heading="true"([^>]*?)>/gi, (match) => {
        const innerMatch = match.match(/>([^<]+)</);
        const text = innerMatch ? innerMatch[1] : "";
        return `<h3 style="display:block;padding:0;margin:1.5em 0 0.75em;font-size:16px;font-weight:bold;color:#222;letter-spacing:0.3px;border-left:none;line-height:1.4;">${text}</h3>`;
      });

    // Wrap in HTML template if specified (auto = detect from content)
    if (args.template) {
      let template = args.template;
      if (template === "auto") {
        const rawMarkdown = fs.readFileSync(filePath, "utf-8");
        template = detectTemplate(rawMarkdown);
        console.error(`[wechat-api] Template auto-detected: ${template}`);
      }
      const wrapperDir = path.join(path.dirname(fileURLToPath(import.meta.url)), "..", "wrappers");
      if (template === "v29") {
        // v29: read wrapper with 01/02/03 numbered sections, inject article H2 headings as section titles
        const wrapperPath = path.join(wrapperDir, "v29.html");
        let wrapper = fs.readFileSync(wrapperPath, "utf-8");

        // Strip author block: find the last hr that precedes "萱宜" or "声明"
        let cleanHtml: string;
        const lastHrBeforeAuthor = htmlContent.lastIndexOf("<hr");
        if (lastHrBeforeAuthor > 0) {
          const tail = htmlContent.substring(lastHrBeforeAuthor);
          if (tail.includes("萱宜") || tail.includes("声明")) {
            cleanHtml = htmlContent.substring(0, lastHrBeforeAuthor).trim();
          } else {
            cleanHtml = htmlContent;
          }
        } else {
          cleanHtml = htmlContent;
        }

        // Extract all H2 sections using indexOf (reliable, no regex issues)
        const sections: { heading: string; body: string }[] = [];
        const h2Marker = '<h2';
        let searchFrom = 0;
        while (true) {
          const h2Start = cleanHtml.indexOf(h2Marker, searchFrom);
          if (h2Start === -1) break;
          // Find the opening tag's closing '>'
          // The > may be HTML-encoded as &gt; (e.g. calc(16px * 1.2) → &gt;) — skip those
          let firstGtAfterH2 = cleanHtml.indexOf('>', h2Start);
          while (firstGtAfterH2 !== -1 && firstGtAfterH2 > 0 && cleanHtml.charAt(firstGtAfterH2 - 1) === '&') {
            firstGtAfterH2 = cleanHtml.indexOf('>', firstGtAfterH2 + 1);
          }
          if (firstGtAfterH2 === -1) break;
          // Find the closing </h2>: search from after the opening tag's >
          // If the first </h2> found is too close to the opening tag (inside the malformed opening tag),
          // skip it and find the NEXT </h2> (which will be the real section closing tag)
          let h2End = cleanHtml.indexOf('</h2>', firstGtAfterH2 + 1);
          while (h2End !== -1 && h2End - firstGtAfterH2 < 10) {
            // This </h2> is part of the malformed opening tag attribute — skip it
            h2End = cleanHtml.indexOf('</h2>', h2End + 5);
          }
          if (h2End === -1) break;
          // innerStart = position after the opening tag's >
          const innerStart = firstGtAfterH2 + 1;
          const rawTitle = cleanHtml.substring(innerStart, h2End).replace(/<[^>]+>/g, "").trim()
            .replace(/^[零一二三四五六七八九十百千\d]+[.、\s]+/, "").trim();
          // Find next h2 or end of content
          const contentStart = h2End + 5; // after </h2>
          const nextH2 = cleanHtml.indexOf(h2Marker, contentStart);
          const contentEnd = nextH2 === -1 ? cleanHtml.length : nextH2;
          const body = cleanHtml.substring(contentStart, contentEnd).trim();
          if (rawTitle && body) sections.push({ heading: rawTitle, body });
          searchFrom = contentEnd;
        }

        // Extract word count
        const wordCount = Math.round(cleanHtml.replace(/<[^>]+>/g, "").length / 2);

        // Extract opening (first paragraph before first H2, or first paragraph of article)
        let openingText = "";
        if (sections.length > 0) {
          // Everything before the first h2 is the opening/preface
          const firstH2Pos = cleanHtml.indexOf('<h2');
          const preface = cleanHtml.substring(0, firstH2Pos);
          const paraMatch = preface.match(/<p[^>]*>([^<]{20,120})<\/p>/);
          if (paraMatch) openingText = paraMatch[1].replace(/<[^>]+>/g, "").trim();
        } else {
          // No h2 found, use first paragraph
          const paraMatch = cleanHtml.match(/<p[^>]*>([^<]{20,120})<\/p>/);
          if (paraMatch) openingText = paraMatch[1].replace(/<[^>]+>/g, "").trim();
        }

        // Extract quote (longest paragraph with <strong>)
        let quoteText = "";
        let maxLen = 0;
        for (const m of cleanHtml.matchAll(/<p[^>]*>([\s\S]*?)<\/p>/g)) {
          const para = m[1] || "";
          if (para.includes("<strong") && para.length > maxLen) {
            const clean = para.replace(/<[^>]+>/g, "").trim();
            if (clean.length > 30) { quoteText = clean; maxLen = para.length; }
          }
        }

        // Fill basic placeholders
        wrapper = wrapper.replace("{{TITLE}}", title || "");
        wrapper = wrapper.replace("{{WORD_COUNT}}", `共 ${wordCount} 字 · 阅读约 ${Math.max(1, Math.round(wordCount / 300))} 分钟`);
        wrapper = wrapper.replace("{{OPENING}}", openingText || "判断力、审美、系统——这三点，才是真正不可替代的竞争力。");
        wrapper = wrapper.replace("{{QUOTE}}", quoteText || "你的判断力、审美、系统——这三点，才是真正不可替代的竞争力。");

        // Inject up to 3 sections into S01/S02/S03
        const sectionSubs = ["THE CORE INSIGHT", "THE METHOD", "THE FRAMEWORK"];
        for (let i = 1; i <= 3; i++) {
          const sd = sections[i - 1];
          const num = String(i).padStart(2, "0");
          if (sd) {
            wrapper = wrapper.replace(`{{S0${i}_NUM}}`, num);
            wrapper = wrapper.replace(`{{S0${i}_TITLE}}`, sd.heading);
            wrapper = wrapper.replace(`{{S0${i}_SUB}}`, sectionSubs[i - 1] || "THE SECTION");
            wrapper = wrapper.replace(`{{S0${i}_BODY}}`, sd.body);
          } else {
            // Hide unused section and its divider with simple string replacement
            wrapper = wrapper.replace(
              `\n<div style="padding:34px 28px;" id="sec-0${i}">\n  <div style="display:flex;align-items:flex-end;margin-bottom:24px;">\n    <div style="font-size:82px;font-weight:bold;color:rgba(62,62,62,0.1);line-height:1;margin-right:18px;letter-spacing:-3px;flex-shrink:0;">{{S0${i}_NUM}}</div>\n    <div style="padding-bottom:7px;">\n      <p style="font-size:20px;font-weight:bold;color:#111111;letter-spacing:0.5px;margin:0;line-height:1.3;">{{S0${i}_TITLE}}</p>\n      <p style="font-size:11px;color:#B8A898;margin:6px 0 0;letter-spacing:1px;">{{S0${i}_SUB}}</p>\n    </div>\n  </div>\n  <div>{{S0${i}_BODY}}</div>\n</div>`,
              ""
            );
          }
        }

        // Extra sections beyond 3 go into {{EXTRA_SECTIONS}}
        const extraSections = sections.slice(3);
        if (extraSections.length > 0) {
          const extraHtml = extraSections.map((s, idx) => {
            const num = String(idx + 4).padStart(2, "0");
            return `<div style="padding:34px 28px;">
  <div style="display:flex;align-items:flex-end;margin-bottom:24px;">
    <div style="font-size:82px;font-weight:bold;color:rgba(62,62,62,0.1);line-height:1;margin-right:18px;letter-spacing:-3px;flex-shrink:0;">${num}</div>
    <div style="padding-bottom:7px;">
      <p style="font-size:20px;font-weight:bold;color:#111111;letter-spacing:0.5px;margin:0;line-height:1.3;">${s.heading}</p>
    </div>
  </div>
  ${s.body}
</div><div style="padding:10px 28px;"><div style="height:1px;background:rgba(62,62,62,0.12);margin:0 auto;width:60px;"></div></div>`;
          }).join("");
          wrapper = wrapper.replace("{{EXTRA_SECTIONS}}", extraHtml);
        } else {
          wrapper = wrapper.replace("{{EXTRA_SECTIONS}}", "");
        }

        htmlContent = wrapper;
        // Strip blue color from md-to-wechat injected inline styles before final publish
        htmlContent = htmlContent
          .replace(/color:\s*#1E50A2[^;]*;?/gi, "color:#3D3D3D!important;")
          .replace(/background:\s*#0F4C81[^;]*;?/gi, "background:transparent!important;")
          .replace(/color:\s*rgb\(30[,\s]+80[,\s]+162\)[^;]*;?/gi, "color:#3D3D3D!important;")
          .replace(/color:\s*#[0-9A-Fa-f]{6}[^;]*;?/gi, (m: string) =>
            m.includes("3D3D3D") || m.includes("888888") || m.includes("B8A898") || m.includes("BBBBBB") || m.includes("C8956C") ? m : "color:#3D3D3D!important;");
        console.error(`[wechat-api] Template applied: v29 (${sections.length} sections)`);
      } else {
        // ny: use wrapper template
        const wrapperPath = path.join(wrapperDir, `${template}.html`);
        if (fs.existsSync(wrapperPath)) {
          let wrapper = fs.readFileSync(wrapperPath, "utf-8");
          wrapper = wrapper.replace("{{TITLE}}", title || "");
          wrapper = wrapper.replace("{{CONTENT}}", htmlContent);
          htmlContent = wrapper;
          console.error(`[wechat-api] Template applied: ${template}`);
        } else {
          console.error(`[wechat-api] Template not found: ${wrapperPath}`);
        }
      }
    }
  }

  if (!title) {
    console.error("Error: No title found. Provide via --title, frontmatter, or <title> tag.");
    process.exit(1);
  }

  if (digest && digest.length > 120) {
    const truncated = digest.slice(0, 117);
    const lastPunct = Math.max(truncated.lastIndexOf("。"), truncated.lastIndexOf("，"), truncated.lastIndexOf("；"), truncated.lastIndexOf("、"));
    digest = lastPunct > 80 ? truncated.slice(0, lastPunct + 1) : truncated + "...";
    console.error(`[wechat-api] Digest truncated to ${digest.length} chars`);
  }

  console.error(`[wechat-api] Title: ${title}`);
  if (author) console.error(`[wechat-api] Author: ${author}`);
  if (digest) console.error(`[wechat-api] Digest: ${digest.slice(0, 50)}...`);
  console.error(`[wechat-api] Type: ${args.articleType}`);

  const extConfig = loadWechatExtendConfig();
  const resolved = resolveAccount(extConfig, args.account);
  if (resolved.name) console.error(`[wechat-api] Account: ${resolved.name} (${resolved.alias})`);

  if (!author && resolved.default_author) author = resolved.default_author;

  if (args.dryRun) {
    console.log(JSON.stringify({
      articleType: args.articleType,
      title,
      author: author || undefined,
      digest: digest || undefined,
      htmlPath,
      contentLength: htmlContent.length,
      placeholderImageCount: contentImages.length || undefined,
      account: resolved.alias || undefined,
    }, null, 2));
    return;
  }

  const creds = loadCredentials(resolved);
  for (const skippedSource of creds.skippedSources) {
    console.error(`[wechat-api] Skipped incomplete credential source: ${skippedSource}`);
  }
  console.error(`[wechat-api] Credentials source: ${creds.source}`);
  console.error("[wechat-api] Fetching access token...");
  const accessToken = await fetchAccessToken(creds.appId, creds.appSecret);

  const rawCoverPath = args.cover ||
    frontmatter.coverImage ||
    frontmatter.featureImage ||
    frontmatter.cover ||
    frontmatter.image;
  const coverPath = rawCoverPath && !path.isAbsolute(rawCoverPath) && args.cover
    ? path.resolve(process.cwd(), rawCoverPath)
    : rawCoverPath;
  const needNewsCoverFallback = args.articleType === "news" && !coverPath;

  console.error("[wechat-api] Uploading body images...");
  const { html: processedHtml, firstCoverMediaId, imageMediaIds } = await uploadImagesInHtml(
    htmlContent,
    accessToken,
    baseDir,
    contentImages,
    args.articleType,
    needNewsCoverFallback,
  );
  htmlContent = processedHtml;

  let thumbMediaId = "";

  if (coverPath) {
    console.error(`[wechat-api] Uploading cover: ${coverPath}`);
    // 封面图片使用 material/add_material 接口
    const coverResp = await uploadImage(coverPath, accessToken, baseDir, "material");
    thumbMediaId = coverResp.media_id;
    console.error(`[wechat-api] Cover uploaded successfully, media_id: ${thumbMediaId}`);
  } else if (firstCoverMediaId && args.articleType === "news") {
    // news 类型没有封面时，使用第一张正文图的 media_id 作为封面（兜底逻辑）
    thumbMediaId = firstCoverMediaId;
    console.error(`[wechat-api] Using first body image as cover (fallback), media_id: ${thumbMediaId}`);
  }

  if (args.articleType === "news" && !thumbMediaId) {
    console.error("Error: No cover image. Provide via --cover, frontmatter.coverImage, or include an image in content.");
    process.exit(1);
  }

  if (args.articleType === "newspic" && imageMediaIds.length === 0) {
    console.error("Error: newspic requires at least one image in content.");
    process.exit(1);
  }

  console.error("[wechat-api] Publishing to draft...");
  const result = await publishToDraft({
    title,
    author: author || undefined,
    digest: digest || undefined,
    content: htmlContent,
    thumbMediaId,
    articleType: args.articleType,
    imageMediaIds: args.articleType === "newspic" ? imageMediaIds : undefined,
    needOpenComment: resolved.need_open_comment,
    onlyFansCanComment: resolved.only_fans_can_comment,
  }, accessToken);

  console.log(JSON.stringify({
    success: true,
    media_id: result.media_id,
    title,
    articleType: args.articleType,
  }, null, 2));

  console.error(`[wechat-api] Published successfully! media_id: ${result.media_id}`);
}

await main().catch((err) => {
  console.error(`Error: ${err instanceof Error ? err.message : String(err)}`);
  process.exit(1);
});
