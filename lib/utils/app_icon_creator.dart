import 'package:flutter/material.dart';
import 'dart:io';
import 'package:by_hex/constants/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class AppIconCreator {
  // إنشاء أيقونة التطبيق بشكل مباشر
  static Future<String> createAppIcon() async {
    // إنشاء صورة بحجم 1024×1024 (الحجم المطلوب لأيقونات التطبيقات)
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final size = 1024.0;
    
    // رسم الخلفية
    final bgPaint = Paint()
      ..color = AppColors.deepPurple
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size, size), bgPaint);
    
    // إضافة تأثير الظل
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawRect(Rect.fromLTWH(50, 50, size - 100, size - 100), shadowPaint);
    
    // رسم الخلفية الداخلية
    final innerBgPaint = Paint()
      ..color = AppColors.lightPurple
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(50, 50, size - 100, size - 100), innerBgPaint);
    
    // رسم الحرف B
    final textPainterB = TextPainter(
      text: TextSpan(
        text: 'B',
        style: TextStyle(
          color: AppColors.darkGray,
          fontSize: 400,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainterB.layout();
    textPainterB.paint(canvas, Offset(200, 300));
    
    // رسم الحرف H
    final textPainterH = TextPainter(
      text: TextSpan(
        text: 'H',
        style: TextStyle(
          color: AppColors.darkGray,
          fontSize: 400,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainterH.layout();
    textPainterH.paint(canvas, Offset(500, 300));
    
    // تحويل الرسم إلى صورة
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();
    
    // حفظ الصورة في ملف
    final directory = await getApplicationDocumentsDirectory();
    final iconPath = '${directory.path}/app_icon.png';
    final iconFile = File(iconPath);
    await iconFile.writeAsBytes(pngBytes);
    
    // نسخ الأيقونة إلى مجلد الأصول
    final assetPath = '/home/ubuntu/projects/by_hex/assets/icon/app_icon.png';
    final assetFile = File(assetPath);
    await assetFile.writeAsBytes(pngBytes);
    
    return assetPath;
  }
}
