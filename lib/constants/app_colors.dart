import 'package:flutter/material.dart';

/// ألوان التطبيق الثابتة
class AppColors {
  // ألوان البنفسجي
  static const Color lightPurple = Color(0xFFE6B8F0);    // بنفسجي فاتح جداً للشريط العلوي
  static const Color mediumPurple = Color(0xFFBA68C8);   // بنفسجي متوسط للأزرار
  static const Color deepPurple = Color(0xFF9C27B0);     // بنفسجي غامق للتأكيد والتحديد
  
  // ألوان الرمادي
  static const Color darkGray = Color(0xFF121212);       // رمادي غامق جداً للخلفية
  static const Color darkGrayLight = Color(0xFF1E1E1E);  // رمادي غامق للعناصر
  static const Color mediumGray = Color(0xFF333333);     // رمادي متوسط للفصل
  static const Color lightGray = Color(0xFF666666);      // رمادي فاتح للنصوص الثانوية
  
  // ألوان وظيفية
  static const Color hexValueColor = Color(0xFFE0E0E0);  // لون قيم Hex
  static const Color asciiValueColor = Color(0xFFB0B0B0); // لون قيم ASCII
  static const Color offsetColor = Color(0xFF808080);    // لون الإزاحة
  static const Color selectedByteColor = Color(0xFFBA68C8); // لون البايت المحدد
  static const Color modifiedByteColor = Color(0xFFE57373); // لون البايت المعدل
  
  // ألوان إضافية
  static const Color backgroundColor = Color(0xFF000000); // لون الخلفية الأساسي (أسود)
  static const Color appBarColor = Color(0xFFE6B8F0);    // لون شريط التطبيق (بنفسجي فاتح)
  static const Color bottomBarColor = Color(0xFFE6B8F0); // لون الشريط السفلي (بنفسجي فاتح)
  static const Color buttonColor = Color(0xFFBA68C8);    // لون الأزرار الرئيسية
  static const Color textColor = Color(0xFFFFFFFF);      // لون النص الأساسي (أبيض)
  static const Color secondaryTextColor = Color(0xFFB0B0B0); // لون النص الثانوي
}
