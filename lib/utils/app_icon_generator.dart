import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:by_hex/constants/app_colors.dart';

/// مولد أيقونة التطبيق
/// يستخدم لإنشاء أيقونة التطبيق بحرفي "B H" بألوان التطبيق
class AppIconGenerator {
  /// إنشاء أيقونة التطبيق وحفظها في مجلد الأصول
  static Future<String> generateAppIcon(BuildContext context, {int size = 512}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = AppColors.deepPurple
      ..style = PaintingStyle.fill;
    
    // رسم الخلفية
    canvas.drawRect(Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()), paint);
    
    // رسم الحرفين "B H"
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: size * 0.4,
      fontWeight: FontWeight.bold,
    );
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'B H',
        style: textStyle,
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );
    
    // تحويل الرسم إلى صورة
    final picture = recorder.endRecording();
    final img = await picture.toImage(size, size);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();
    
    // حفظ الصورة في مجلد الأصول
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/app_icon.png';
    final file = File(path);
    await file.writeAsBytes(buffer);
    
    return path;
  }
}
