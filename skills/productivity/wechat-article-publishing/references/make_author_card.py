from PIL import Image, ImageDraw, ImageFont
import os

# Load and resize author photo
photo = Image.open("/tmp/cover_photo.jpg").convert("RGBA")
photo = photo.resize((300, 300), Image.LANCZOS)

# Create circular mask
mask = Image.new("L", (300, 300), 0)
draw_mask = ImageDraw.Draw(mask)
draw_mask.ellipse((0, 0, 300, 300), fill=255)

# Apply circular mask
circle = Image.new("RGBA", (300, 300), (0,0,0,0))
circle.paste(photo, (0, 0), mask)
circle = circle.resize((130, 130), Image.LANCZOS)

# Canvas - warm off-white #FAF5EF
canvas = Image.new("RGB", (900, 560), (250, 245, 239))
canvas.paste(circle, (55, 50), circle)

d = ImageDraw.Draw(canvas)

# Load fonts (macOS paths)
try:
    font_name  = ImageFont.truetype("/System/Library/Fonts/Supplemental/PingFang.ttc", 38)
    font_title = ImageFont.truetype("/System/Library/Fonts/Supplemental/PingFang.ttc", 21)
    font_bio   = ImageFont.truetype("/System/Library/Fonts/Supplemental/PingFang.ttc", 23)
    font_cta   = ImageFont.truetype("/System/Library/Fonts/Supplemental/PingFang.ttc", 21)
    font_small = ImageFont.truetype("/System/Library/Fonts/Supplemental/PingFang.ttc", 19)
except:
    font_name = font_title = font_bio = font_cta = font_small = ImageFont.load_default()

# Name
d.text((205, 55), "萱宜", font=font_name, fill=(26, 26, 26))

# Title
d.text((205, 102), "医美增长架构师 · AI+系统增长架构师", font=font_title, fill=(148, 140, 128))

# Separator
d.line([(55, 150), (845, 150)], fill=(220, 215, 205), width=1)

# Bio lines
y = 170
for line in [
    "行业老兵 · 17年+医美全产业链实战。曾任职艾尔建、国药中生等",
    "世界500强及央企。曾任斐缦董事长兼总经理，",
    "深度参与6项胶原蛋白专利研发。",
    "",
    "AI科班 · IBM《生成式AI》、 DeepLearning.AI等多项国际认证。",
    "精通Python编程与Make.com自动化工作流。",
    "",
    "专注做啥 · 帮医美创始人用AI+系统搭建",
    "永不离职的数字增长团队。",
]:
    d.text((55, y), line, font=font_bio, fill=(90, 90, 90))
    y += 36

# CTA
y += 16
d.text((55, y), "👉 更多实战拆解，关注公众号「陈萱宜的增长实验室」", font=font_cta, fill=(120, 100, 80))
y += 36
d.text((55, y), "合作可私信，或发邮件至 471151795@qq.com", font=font_small, fill=(120, 100, 80))

canvas.save("/tmp/author_card.png", "PNG", quality=95)
print(f"Saved: {os.path.getsize('/tmp/author_card.png')//1024}KB")
