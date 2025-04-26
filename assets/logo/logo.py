import cairo
import math

# إنشاء سطح رسم بحجم 512×512 بكسل
WIDTH, HEIGHT = 512, 512
surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, WIDTH, HEIGHT)
ctx = cairo.Context(surface)

# تعيين خلفية شفافة
ctx.set_source_rgba(0, 0, 0, 0)
ctx.paint()

# تحديد الألوان الرئيسية للشعار
deep_purple = (0.4, 0.2, 0.6, 1)  # اللون البنفسجي الغامق
medium_purple = (0.6, 0.4, 0.8, 1)  # اللون البنفسجي المتوسط
light_purple = (0.8, 0.7, 0.9, 1)  # اللون البنفسجي الفاتح

# رسم الخلفية السداسية
ctx.save()
ctx.translate(WIDTH/2, HEIGHT/2)  # نقل نقطة الأصل إلى وسط الصورة

# رسم شكل سداسي
radius = 220
sides = 6
ctx.move_to(radius, 0)
for i in range(1, sides + 1):
    angle = i * 2 * math.pi / sides
    ctx.line_to(radius * math.cos(angle), radius * math.sin(angle))

# تعبئة الشكل السداسي بتدرج لوني
gradient = cairo.LinearGradient(0, -radius, 0, radius)
gradient.add_color_stop_rgba(0, *deep_purple)
gradient.add_color_stop_rgba(0.5, *medium_purple)
gradient.add_color_stop_rgba(1, *light_purple)
ctx.set_source(gradient)
ctx.fill_preserve()

# إضافة حدود للشكل السداسي
ctx.set_line_width(4)
ctx.set_source_rgba(0.3, 0.1, 0.5, 1)  # لون الحدود
ctx.stroke()

# رسم حرف B
ctx.set_source_rgba(1, 1, 1, 1)  # اللون الأبيض
ctx.select_font_face("Arial", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD)
ctx.set_font_size(180)
text_extents = ctx.text_extents("B")
ctx.move_to(-text_extents.width/2 - 60, text_extents.height/2)
ctx.show_text("B")

# رسم حرف H
ctx.set_source_rgba(1, 1, 1, 1)  # اللون الأبيض
ctx.select_font_face("Arial", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD)
ctx.set_font_size(180)
text_extents = ctx.text_extents("H")
ctx.move_to(-text_extents.width/2 + 60, text_extents.height/2)
ctx.show_text("H")

# رسم خط صغير يربط بين الحرفين
ctx.set_line_width(10)
ctx.set_source_rgba(1, 1, 1, 0.8)  # اللون الأبيض بشفافية
ctx.move_to(-20, 20)
ctx.line_to(20, 20)
ctx.stroke()

# إضافة تأثير ظل خفيف
ctx.restore()

# حفظ الشعار كملف PNG
surface.write_to_png("/home/ubuntu/projects/by_hex/assets/logo/by_hex_logo.png")

# إنشاء نسخة أصغر للأيقونة
icon_size = 192
icon_surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, icon_size, icon_size)
icon_ctx = cairo.Context(icon_surface)

# تعيين خلفية شفافة
icon_ctx.set_source_rgba(0, 0, 0, 0)
icon_ctx.paint()

# تصغير الشعار للأيقونة
scale_factor = icon_size / WIDTH
icon_ctx.scale(scale_factor, scale_factor)
icon_ctx.set_source_surface(surface, 0, 0)
icon_ctx.paint()

# حفظ الأيقونة كملف PNG
icon_surface.write_to_png("/home/ubuntu/projects/by_hex/assets/logo/by_hex_icon.png")

print("تم إنشاء الشعار والأيقونة بنجاح!")
