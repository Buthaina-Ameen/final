import 'dart:io';
import 'package:flutter/material.dart';
import 'package:by_hex/utils/large_file_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;
import 'package:by_hex/services/virus_total_service.dart';
import 'package:by_hex/services/security_service.dart';
import 'package:provider/provider.dart';

class EnhancedFileService extends ChangeNotifier {
  // الملف الحالي
  FileModel? _currentFile;
  FileModel? get currentFile => _currentFile;
  
  // بيانات الملف
  List<int>? _fileBytes;
  List<int>? get fileBytes => _fileBytes;
  
  // حالة التعديل
  bool _isModified = false;
  bool get isModified => _isModified;
  
  // حالة الفحص الأمني
  bool _isInfected = false;
  bool get isInfected => _isInfected;
  String? _securityMessage;
  String? get securityMessage => _securityMessage;
  
  // مدير الملفات الكبيرة
  LargeFileHandler? _largeFileHandler;
  LargeFileHandler? get largeFileHandler => _largeFileHandler;
  
  // قائمة الملفات الحديثة
  List<FileModel> _recentFiles = [];
  List<FileModel> get recentFiles => List.unmodifiable(_recentFiles);
  
  // حد حجم الملف الكبير (10 ميجابايت)
  static const int _largeFileSizeThreshold = 10 * 1024 * 1024;
  
  // فتح ملف محلي
  Future<bool> openLocalFile({BuildContext? context}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final filePath = file.path!;
        
        // إغلاق الملف الحالي إذا كان مفتوحًا
        await closeCurrentFile();
        
        final fileObj = File(filePath);
        final fileSize = await fileObj.length();
        
        _currentFile = FileModel(
          name: file.name,
          path: filePath,
          size: fileSize,
          lastModified: DateTime.now(),
        );
        
        // استخدام مدير الملفات الكبيرة للملفات الكبيرة
        if (fileSize > _largeFileSizeThreshold) {
          _largeFileHandler = LargeFileHandler(file: fileObj);
          await _largeFileHandler!.initialize();
          
          // قراءة الجزء الأول من الملف فقط
          _fileBytes = await _largeFileHandler!.readBytes(0, 1024 * 1024);
        } else {
          _fileBytes = await fileObj.readAsBytes();
          _largeFileHandler = null;
        }
        
        _isModified = false;
        
        // فحص الملف أمنياً بشكل تلقائي
        if (context != null) {
          await _scanFileForSecurity(context, fileObj);
        }
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error opening file: $e');
      return false;
    }
  }
  
  // فحص الملف أمنياً
  Future<void> _scanFileForSecurity(BuildContext context, File file) async {
    try {
      // إعادة تعيين حالة الفحص الأمني
      _isInfected = false;
      _securityMessage = null;
      notifyListeners();
      
      // فحص الملف باستخدام خدمة الأمان الداخلية
      final securityService = Provider.of<SecurityService>(context, listen: false);
      final securityResult = await securityService.scanFile(file);
      
      if (securityResult.threatLevel != ThreatLevel.safe) {
        _isInfected = true;
        _securityMessage = securityResult.threatLevel == ThreatLevel.suspicious
            ? "الملف مشبوه: ${securityResult.threatDescription}"
            : "الملف ضار: ${securityResult.threatDescription}";
        notifyListeners();
        return;
      }
      
      // فحص الملف باستخدام VirusTotal إذا كان حجم الملف مناسباً (أقل من 32 ميجابايت)
      if (file.lengthSync() < 32 * 1024 * 1024) {
        final virusTotalService = Provider.of<VirusTotalService>(context, listen: false);
        
        // التحقق من وجود مفتاح API صالح
        if (virusTotalService.apiKey.isNotEmpty && 
            virusTotalService.apiKey != 'YOUR_VIRUSTOTAL_API_KEY') {
          try {
            final vtResult = await virusTotalService.scanFile(file);
            
            if (vtResult != null && !vtResult.isClean) {
              _isInfected = true;
              _securityMessage = "تم اكتشاف تهديد: ${vtResult.detectedEngines} من أصل ${vtResult.totalEngines} محرك فحص اكتشف تهديدات";
            } else {
              _isInfected = false;
              _securityMessage = "الملف آمن";
            }
          } catch (e) {
            debugPrint('Error scanning with VirusTotal: $e');
            // استمر بدون فحص VirusTotal في حالة حدوث خطأ
          }
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error during security scan: $e');
    }
  }
  
  // إنشاء ملف جديد
  Future<bool> createNewFile() async {
    try {
      // إغلاق الملف الحالي إذا كان مفتوحًا
      await closeCurrentFile();
      
      // إنشاء ملف جديد فارغ
      _currentFile = FileModel(
        name: 'New File.bin',
        path: '',
        size: 0,
        lastModified: DateTime.now(),
      );
      
      _fileBytes = [];
      _largeFileHandler = null;
      _isModified = false;
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error creating new file: $e');
      return false;
    }
  }
  
  // حفظ الملف الحالي
  Future<bool> saveCurrentFile() async {
    if (_currentFile == null || _fileBytes == null) return false;
    
    try {
      // إذا كان الملف جديدًا، اطلب من المستخدم اختيار مكان الحفظ
      if (_currentFile!.path.isEmpty) {
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'حفظ الملف',
          fileName: _currentFile!.name,
        );
        
        if (result != null) {
          _currentFile = FileModel(
            name: path.basename(result),
            path: result,
            size: _fileBytes!.length,
            lastModified: DateTime.now(),
          );
        } else {
          return false;
        }
      }
      
      // حفظ الملف
      final file = File(_currentFile!.path);
      await file.writeAsBytes(_fileBytes!);
      
      _isModified = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving file: $e');
      return false;
    }
  }
  
  // تحميل الملف إلى السحابة
  Future<bool> uploadCurrentFile() async {
    if (_currentFile == null || _fileBytes == null) return false;
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      
      final fileName = _currentFile!.name;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users/${user.uid}/files/$fileName');
      
      // تحميل الملف
      if (_largeFileHandler != null) {
        // للملفات الكبيرة، استخدم تحميل الملف المحلي
        await storageRef.putFile(File(_currentFile!.path));
      } else {
        // للملفات الصغيرة، استخدم تحميل البيانات من الذاكرة
        await storageRef.putData(Uint8List.fromList(_fileBytes!));
      }
      
      // تحديث قائمة الملفات الحديثة
      await loadRecentFiles();
      
      return true;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return false;
    }
  }
  
  // تحميل قائمة الملفات الحديثة من السحابة
  Future<void> loadRecentFiles() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users/${user.uid}/files');
      
      final result = await storageRef.listAll();
      
      _recentFiles = [];
      
      for (var item in result.items) {
        final metadata = await item.getMetadata();
        
        _recentFiles.add(FileModel(
          name: item.name,
          path: '',
          size: metadata.size ?? 0,
          lastModified: metadata.updated ?? DateTime.now(),
          cloudPath: item.fullPath,
        ));
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading recent files: $e');
    }
  }
  
  // تنزيل ملف من السحابة
  Future<bool> downloadCloudFile(FileModel cloudFile) async {
    try {
      // إغلاق الملف الحالي إذا كان مفتوحًا
      await closeCurrentFile();
      
      final storageRef = FirebaseStorage.instance.ref().child(cloudFile.cloudPath!);
      
      // تنزيل البيانات
      final data = await storageRef.getData();
      if (data == null) return false;
      
      _fileBytes = data;
      _currentFile = FileModel(
        name: cloudFile.name,
        path: '',
        size: data.length,
        lastModified: DateTime.now(),
        cloudPath: cloudFile.cloudPath,
      );
      
      // استخدام مدير الملفات الكبيرة للملفات الكبيرة
      if (data.length > _largeFileSizeThreshold) {
        // حفظ البيانات في ملف مؤقت
        final tempDir = await Directory.systemTemp.createTemp('byhex_');
        final tempFile = File('${tempDir.path}/${cloudFile.name}');
        await tempFile.writeAsBytes(data);
        
        _largeFileHandler = LargeFileHandler(file: tempFile);
        await _largeFileHandler!.initialize();
      } else {
        _largeFileHandler = null;
      }
      
      _isModified = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error downloading cloud file: $e');
      return false;
    }
  }
  
  // إغلاق الملف الحالي
  Future<void> closeCurrentFile() async {
    if (_largeFileHandler != null) {
      await _largeFileHandler!.dispose();
      _largeFileHandler = null;
    }
    
    _currentFile = null;
    _fileBytes = null;
    _isModified = false;
    
    notifyListeners();
  }
  
  // تعيين حالة التعديل
  void setModified(bool value) {
    _isModified = value;
    notifyListeners();
  }
  
  // قراءة جزء من ملف كبير
  Future<List<int>> readLargeFilePart(int offset, int length) async {
    if (_largeFileHandler == null) {
      throw Exception('Large file handler not initialized');
    }
    
    return await _largeFileHandler!.readBytes(offset, length);
  }
}

// نموذج الملف
class FileModel {
  final String name;
  final String path;
  final int size;
  final DateTime lastModified;
  final String? cloudPath;
  
  FileModel({
    required this.name,
    required this.path,
    required this.size,
    required this.lastModified,
    this.cloudPath,
  });
}

// استيراد Uint8List
import 'dart:typed_data';
