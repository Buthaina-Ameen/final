from PIL import Image, ImageDraw, ImageFont
import random
import math

# إنشاء صورة بخلفية شفافة
WIDTH, HEIGHT = 512, 512
image = Image.new('RGBA', (WIDTH, HEIGHT), (0, 0, 0, 0))
draw = ImageDraw.Draw(image)

# تحديد الألوان الرئيسية للشعار - جعلها أغمق
deep_purple = (72, 36, 108, 255)  # اللون البنفسجي الغامق أكثر
medium_purple = (102, 51, 153, 255)  # اللون البنفسجي المتوسط أغمق
light_purple = (153, 102, 204, 255)  # اللون البنفسجي الفاتح أغمق

# إنشاء خلفية مربعة متدرجة
center_x, center_y = WIDTH // 2, HEIGHT // 2
square_size = 400  # حجم المربع

# رسم مربع بلون متدرج
for r in range(square_size // 2, 0, -1):
    # حساب اللون المتدرج بناءً على المسافة من المركز
    ratio = r / (square_size // 2)
    color = (
        int(deep_purple[0] * (1 - ratio) + light_purple[0] * ratio),
        int(deep_purple[1] * (1 - ratio) + light_purple[1] * ratio),
        int(deep_purple[2] * (1 - ratio) + light_purple[2] * ratio),
        255
    )
    
    # رسم مربع متدرج من المركز
    square_left = center_x - r
    square_top = center_y - r
    square_right = center_x + r
    square_bottom = center_y + r
    draw.rectangle([square_left, square_top, square_right, square_bottom], fill=color, outline=None)

# إضافة حدود للمربع
border_width = 3
draw.rectangle([
    center_x - square_size//2, 
    center_y - square_size//2, 
    center_x + square_size//2, 
    center_y + square_size//2
], outline=(50, 25, 75, 255), width=border_width)

# إضافة نمط البايتات المصغرة في الخلفية
hex_chars = "0123456789ABCDEF"
small_font_size = 14
try:
    small_font = ImageFont.truetype("Arial.ttf", small_font_size)
except IOError:
    small_font = ImageFont.load_default().font_variant(size=small_font_size)

# إنشاء شبكة من البايتات العشوائية
for x in range(center_x - square_size//2 + 20, center_x + square_size//2 - 20, 30):
    for y in range(center_y - square_size//2 + 20, center_y + square_size//2 - 20, 20):
        # التحقق مما إذا كانت النقطة داخل المربع
        if (x >= center_x - square_size//2 and x <= center_x + square_size//2 and
            y >= center_y - square_size//2 and y <= center_y + square_size//2):
            # إنشاء بايت عشوائي (مثل "A4" أو "FF")
            byte_text = random.choice(hex_chars) + random.choice(hex_chars)
            # جعل البايتات أكثر شفافية في المنتصف (حيث ستكون الحروف الرئيسية)
            distance = math.sqrt((x - center_x)**2 + (y - center_y)**2)
            alpha = int(128 * (distance / (square_size//2)))
            draw.text((x, y), byte_text, fill=(255, 255, 255, alpha), font=small_font)

# محاولة تحميل الخط للحروف الرئيسية
try:
    main_font = ImageFont.truetype("Arial.ttf", 200)
    app_name_font = ImageFont.truetype("Arial.ttf", 60)
except IOError:
    main_font = ImageFont.load_default().font_variant(size=200)
    app_name_font = ImageFont.load_default().font_variant(size=60)

# رسم حرف B
b_text = "B"
b_width = draw.textlength(b_text, font=main_font)
b_height = 200  # تقريبي
draw.text((center_x - b_width - 20, center_y - b_height//2), b_text, fill=(255, 255, 255, 255), font=main_font)

# رسم حرف H
h_text = "H"
h_width = draw.textlength(h_text, font=main_font)
draw.text((center_x + 20, center_y - b_height//2), h_text, fill=(255, 255, 255, 255), font=main_font)

# رسم اسم التطبيق "BY HEX" في الأسفل
app_name = "BY HEX"
app_name_width = draw.textlength(app_name, font=app_name_font)
draw.text((center_x - app_name_width//2, center_y + 100), app_name, fill=(255, 255, 255, 230), font=app_name_font)

# إضافة تأثير توهج خفيف حول الحروف الرئيسية
glow_color = (255, 255, 255, 30)
for offset in range(1, 4):
    draw.text((center_x - b_width - 20 - offset, center_y - b_height//2), b_text, fill=glow_color, font=main_font)
    draw.text((center_x - b_width - 20 + offset, center_y - b_height//2), b_text, fill=glow_color, font=main_font)
    draw.text((center_x + 20 - offset, center_y - b_height//2), h_text, fill=glow_color, font=main_font)
    draw.text((center_x + 20 + offset, center_y - b_height//2), h_text, fill=glow_color, font=main_font)

# حفظ الشعار كملف PNG
image.save("/home/ubuntu/projects/by_hex/assets/logo/by_hex_logo_square.png")

# إنشاء نسخة أصغر للأيقونة
icon_size = 192
icon = image.resize((icon_size, icon_size), Image.LANCZOS)
icon.save("/home/ubuntu/projects/by_hex/assets/logo/by_hex_icon_square.png")

print("تم إنشاء الشعار والأيقونة المربعة بنجاح!")
