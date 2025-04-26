import 'package:flutter/material.dart';
import 'package:by_hex/constants/app_colors.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  // هذه الدالة تقوم بتهيئة Firebase مع التكوين المناسب
  static Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyBxHEBCBiSaPt4WnJXO_2lZ2nJ_IjCl5Zw",
          authDomain: "by-hex-editor.firebaseapp.com",
          projectId: "by-hex-editor",
          storageBucket: "by-hex-editor.appspot.com",
          messagingSenderId: "123456789012",
          appId: "1:123456789012:web:abc123def456ghi789jkl",
        ),
      );
      debugPrint('تم تهيئة Firebase بنجاح');
    } catch (e) {
      debugPrint('خطأ في تهيئة Firebase: $e');
      rethrow;
    }
  }
  
  // ملاحظة: يجب استبدال القيم أعلاه بالقيم الفعلية من مشروع Firebase الخاص بك
  // يمكن الحصول على هذه القيم من ملف google-services.json أو GoogleService-Info.plist
}
