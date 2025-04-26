import 'package:flutter/material.dart';
import 'package:by_hex/models/file_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CloudStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // الحصول على معرف المستخدم الحالي
  String? get _userId => _auth.currentUser?.uid;

  // تحميل ملف إلى التخزين السحابي
  Future<String?> uploadFile(String localFilePath, String fileName) async {
    if (_userId == null) return null;

    try {
      final fileRef = _storage.ref().child('users/$_userId/files/$fileName');
      final uploadTask = await fileRef.putFile(File(localFilePath));
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // حفظ معلومات الملف في Firestore
      await _saveFileMetadata(fileName, downloadUrl, localFilePath);

      return downloadUrl;
    } catch (e) {
      debugPrint('خطأ في تحميل الملف: $e');
      return null;
    }
  }

  // حفظ بيانات الملف في Firestore
  Future<void> _saveFileMetadata(String fileName, String downloadUrl, String localPath) async {
    if (_userId == null) return;

    try {
      final fileInfo = await File(localPath).stat();
      
      final fileModel = FileModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: fileName,
        path: localPath,
        size: fileInfo.size,
        lastModified: fileInfo.modified,
        cloudPath: downloadUrl,
      );

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('files')
          .doc(fileModel.id)
          .set(fileModel.toMap());
    } catch (e) {
      debugPrint('خطأ في حفظ بيانات الملف: $e');
    }
  }

  // الحصول على قائمة الملفات من Firestore
  Future<List<FileModel>> getUserFiles() async {
    if (_userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('files')
          .get();

      return snapshot.docs
          .map((doc) => FileModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('خطأ في الحصول على ملفات المستخدم: $e');
      return [];
    }
  }

  // تنزيل ملف من التخزين السحابي
  Future<String?> downloadFile(String cloudPath, String localPath) async {
    try {
      final fileRef = _storage.refFromURL(cloudPath);
      final file = File(localPath);
      await fileRef.writeToFile(file);
      return localPath;
    } catch (e) {
      debugPrint('خطأ في تنزيل الملف: $e');
      return null;
    }
  }

  // حذف ملف من التخزين السحابي
  Future<bool> deleteFile(String fileId, String cloudPath) async {
    if (_userId == null) return false;

    try {
      // حذف الملف من Storage
      if (cloudPath.isNotEmpty) {
        final fileRef = _storage.refFromURL(cloudPath);
        await fileRef.delete();
      }

      // حذف بيانات الملف من Firestore
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('files')
          .doc(fileId)
          .delete();

      return true;
    } catch (e) {
      debugPrint('خطأ في حذف الملف: $e');
      return false;
    }
  }
}

// استيراد دالة File
import 'dart:io';
