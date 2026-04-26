# 🖥️ 新电脑配置清单

克隆完 hermes-skills 后，必须手动配置以下项目才能完整运行：

## 1. API Keys → `~/.hermes/.env`

```bash
# MiniMax（图像生成用）
MINIMAX_CN_API_KEY=你的key

# 博客Token
BLOG_TOKEN=qm_8uXMYOrTzQxFF6I0QAUV_YXKrzchqyBT

# Vercel
VERCEL_TOKEN=vcp_xxx

# Notion
NOTION_API_KEY=ntn_xxx
```

## 2. OpenCLI + Chrome扩展（10分钟）

```bash
# 安装 OpenCLI
npm install -g @jackwener/opencli

# 下载Chrome扩展
curl -L -o /tmp/opencli-extension.zip \
  "https://github.com/jackwener/OpenCLI/releases/download/v1.7.8/opencli-extension-v1.0.2.zip"

# 解压
unzip -o /tmp/opencli-extension.zip -d /tmp/opencli-extension

# Chrome地址栏输入：chrome://extensions
# 右上角开"开发者模式"
# 点击"加载已解压的扩展程序"
# 选择 /tmp/opencli-extension 文件夹
```

## 3. 重新登录微博/X（Chrome Profile）

微博和X的登录状态在Chrome profile里，git不备份：
- 微博：打开 weibo.com 重新扫码登录
- X (Twitter)：打开 x.com 重新登录

## 4. 博客后台密码

`blog.filldmy.com/admin` → 账号 admin / 密码 admin888

---

配置完成后，说"发文章"即可开始多平台发布。

---

## 当前已备份 vs 需手动配置

| 内容 | 状态 |
|------|------|
| hermes-skills（含 baoyu-skills） | ✅ GitHub已有 |
| API keys | ❌ 需手动配置 |
| OpenCLI + Chrome扩展 | ❌ 需重装 |
| Chrome profile（微博/X登录） | ❌ 需重新登录 |
| 博客Admin密码 | ❌ 需手动记录 |
