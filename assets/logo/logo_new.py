from PIL import Image, ImageDraw, ImageFont
import math

# إنشاء صورة بخلفية شفافة
WIDTH, HEIGHT = 512, 512
image = Image.new('RGBA', (WIDTH, HEIGHT), (0, 0, 0, 0))
draw = ImageDraw.Draw(image)

# تحديد الألوان الرئيسية للشعار
deep_purple = (102, 51, 153, 255)  # اللون البنفسجي الغامق
medium_purple = (153, 102, 204, 255)  # اللون البنفسجي المتوسط
light_purple = (204, 179, 230, 255)  # اللون البنفسجي الفاتح

# إنشاء خلفية دائرية متدرجة
center_x, center_y = WIDTH // 2, HEIGHT // 2
radius = 220

# رسم دائرة بلون متدرج
for r in range(radius, 0, -1):
    # حساب اللون المتدرج بناءً على المسافة من المركز
    ratio = r / radius
    color = (
        int(deep_purple[0] * (1 - ratio) + light_purple[0] * ratio),
        int(deep_purple[1] * (1 - ratio) + light_purple[1] * ratio),
        int(deep_purple[2] * (1 - ratio) + light_purple[2] * ratio),
        255
    )
    draw.ellipse((center_x - r, center_y - r, center_x + r, center_y + r), fill=color, outline=None)

# محاولة تحميل الخط
try:
    font = ImageFont.truetype("Arial.ttf", 200)
    small_font = ImageFont.truetype("Arial.ttf", 80)
except IOError:
    # إذا لم يتم العثور على الخط، استخدم الخط الافتراضي
    font = ImageFont.load_default().font_variant(size=200)
    small_font = ImageFont.load_default().font_variant(size=80)

# رسم حرف B
b_text = "B"
b_width = draw.textlength(b_text, font=font)
b_height = 200  # تقريبي
draw.text((center_x - b_width - 20, center_y - b_height//2), b_text, fill=(255, 255, 255, 255), font=font)

# رسم حرف H
h_text = "H"
h_width = draw.textlength(h_text, font=font)
draw.text((center_x + 20, center_y - b_height//2), h_text, fill=(255, 255, 255, 255), font=font)

# رسم كلمة HEX بحجم أصغر تحت الحروف الرئيسية
hex_text = "HEX"
hex_width = draw.textlength(hex_text, font=small_font)
draw.text((center_x - hex_width//2, center_y + 80), hex_text, fill=(255, 255, 255, 200), font=small_font)

# إضافة تأثير توهج خفيف حول الحروف
glow_color = (255, 255, 255, 50)
for offset in range(1, 6):
    draw.text((center_x - b_width - 20 - offset, center_y - b_height//2), b_text, fill=glow_color, font=font)
    draw.text((center_x - b_width - 20 + offset, center_y - b_height//2), b_text, fill=glow_color, font=font)
    draw.text((center_x + 20 - offset, center_y - b_height//2), h_text, fill=glow_color, font=font)
    draw.text((center_x + 20 + offset, center_y - b_height//2), h_text, fill=glow_color, font=font)

# حفظ الشعار كملف PNG
image.save("/home/ubuntu/projects/by_hex/assets/logo/by_hex_logo_new.png")

# إنشاء نسخة أصغر للأيقونة
icon_size = 192
icon = image.resize((icon_size, icon_size), Image.LANCZOS)
icon.save("/home/ubuntu/projects/by_hex/assets/logo/by_hex_icon_new.png")

print("تم إنشاء الشعار والأيقونة الجديدة بنجاح!")
