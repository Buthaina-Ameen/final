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

# رسم الشكل السداسي
center_x, center_y = WIDTH // 2, HEIGHT // 2
radius = 220
sides = 6
angle = 2 * math.pi / sides
points = []

for i in range(sides):
    x = center_x + radius * math.cos(angle * i)
    y = center_y + radius * math.sin(angle * i)
    points.append((x, y))

# تعبئة الشكل السداسي بلون متوسط
draw.polygon(points, fill=medium_purple)

# إضافة حدود للشكل السداسي
draw.line(points + [points[0]], fill=(76, 25, 127, 255), width=4)

# محاولة تحميل الخط
try:
    font = ImageFont.truetype("Arial.ttf", 180)
except IOError:
    # إذا لم يتم العثور على الخط، استخدم الخط الافتراضي
    font = ImageFont.load_default().font_variant(size=180)

# رسم حرف B
b_text = "B"
b_width = draw.textlength(b_text, font=font)
draw.text((center_x - b_width - 30, center_y - 90), b_text, fill=(255, 255, 255, 255), font=font)

# رسم حرف H
h_text = "H"
h_width = draw.textlength(h_text, font=font)
draw.text((center_x + 30, center_y - 90), h_text, fill=(255, 255, 255, 255), font=font)

# رسم خط صغير يربط بين الحرفين
draw.line([(center_x - 20, center_y), (center_x + 20, center_y)], fill=(255, 255, 255, 200), width=10)

# حفظ الشعار كملف PNG
image.save("/home/ubuntu/projects/by_hex/assets/logo/by_hex_logo.png")

# إنشاء نسخة أصغر للأيقونة
icon_size = 192
icon = image.resize((icon_size, icon_size), Image.LANCZOS)
icon.save("/home/ubuntu/projects/by_hex/assets/logo/by_hex_icon.png")

print("تم إنشاء الشعار والأيقونة بنجاح!")
