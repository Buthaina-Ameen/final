import 'package:flutter/material.dart';
import 'package:by_hex/models/file_model.dart';
import 'package:by_hex/services/auth_service.dart';
import 'package:by_hex/services/cloud_storage_service.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class FileService extends ChangeNotifier {
  final CloudStorageService _cloudStorageService = CloudStorageService();
  
  List<FileModel> _recentFiles = [];
  FileModel? _currentFile;
  List<int>? _fileBytes;
  bool _isModified = false;
  
  List<FileModel> get recentFiles => _recentFiles;
  FileModel? get currentFile => _currentFile;
  List<int>? get fileBytes => _fileBytes;
  bool get isModified => _isModified;
  
  // تحميل قائمة الملفات الأخيرة من Firebase
  Future<void> loadRecentFiles() async {
    _recentFiles = await _cloudStorageService.getUserFiles();
    notifyListeners();
  }
  
  // فتح ملف من الجهاز
  Future<bool> openLocalFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final filePath = file.path!;
        
        // قراءة محتوى الملف
        final bytes = await File(filePath).readAsBytes();
        
        _currentFile = FileModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: path.basename(filePath),
          path: filePath,
          size: bytes.length,
          lastModified: DateTime.now(),
        );
        
        _fileBytes = bytes;
        _isModified = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('خطأ في فتح الملف: $e');
      return false;
    }
  }
  
  // إنشاء ملف جديد
  void createNewFile(String fileName) {
    _currentFile = FileModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: fileName,
      path: '',
      size: 0,
      lastModified: DateTime.now(),
    );
    
    _fileBytes = [];
    _isModified = true;
    notifyListeners();
  }
  
  // حفظ الملف الحالي
  Future<bool> saveCurrentFile() async {
    if (_currentFile == null || _fileBytes == null) return false;
    
    try {
      String filePath = _currentFile!.path;
      
      // إذا كان الملف جديدًا، اطلب من المستخدم اختيار مكان الحفظ
      if (filePath.isEmpty) {
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'حفظ الملف',
          fileName: _currentFile!.name,
        );
        
        if (result == null) return false;
        filePath = result;
        _currentFile = _currentFile!.copyWith(path: filePath);
      }
      
      // حفظ الملف محليًا
      await File(filePath).writeAsBytes(_fileBytes!);
      
      // تحديث حالة الملف
      _currentFile = _currentFile!.copyWith(
        size: _fileBytes!.length,
        lastModified: DateTime.now(),
        isModified: false,
      );
      
      _isModified = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('خطأ في حفظ الملف: $e');
      return false;
    }
  }
  
  // تحميل الملف إلى التخزين السحابي
  Future<bool> uploadCurrentFile() async {
    if (_currentFile == null || _fileBytes == null || _currentFile!.path.isEmpty) {
      return false;
    }
    
    try {
      // حفظ الملف محليًا أولاً إذا كان معدلًا
      if (_isModified) {
        final saveResult = await saveCurrentFile();
        if (!saveResult) return false;
      }
      
      // تحميل الملف إلى التخزين السحابي
      final cloudPath = await _cloudStorageService.uploadFile(
        _currentFile!.path,
        _currentFile!.name,
      );
      
      if (cloudPath != null) {
        _currentFile = _currentFile!.copyWith(cloudPath: cloudPath);
        
        // تحديث قائمة الملفات الأخيرة
        await loadRecentFiles();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('خطأ في تحميل الملف: $e');
      return false;
    }
  }
  
  // تعديل محتوى الملف
  void updateFileBytes(List<int> newBytes) {
    _fileBytes = newBytes;
    _isModified = true;
    notifyListeners();
  }
  
  // تعديل بايت محدد في الملف
  void updateByte(int offset, int value) {
    if (_fileBytes != null && offset >= 0 && offset < _fileBytes!.length) {
      _fileBytes![offset] = value;
      _isModified = true;
      notifyListeners();
    }
  }
}

// إضافة دالة copyWith إلى FileModel
extension FileModelExtension on FileModel {
  FileModel copyWith({
    String? id,
    String? name,
    String? path,
    int? size,
    DateTime? lastModified,
    String? cloudPath,
    bool? isModified,
  }) {
    return FileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      size: size ?? this.size,
      lastModified: lastModified ?? this.lastModified,
      cloudPath: cloudPath ?? this.cloudPath,
      isModified: isModified ?? this.isModified,
    );
  }
}
