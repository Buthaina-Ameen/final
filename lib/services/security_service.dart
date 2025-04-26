import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class SecurityService extends ChangeNotifier {
  // مستويات الفحص الأمني
  enum SecurityScanLevel {
    basic,    // فحص أساسي
    medium,   // فحص متوسط
    thorough  // فحص شامل
  }
  
  // أنواع التهديدات
  enum ThreatType {
    malware,        // برمجيات ضارة
    invalidHeader,  // رأس ملف غير صالح
    suspiciousEntropy, // إنتروبيا مشبوهة
    modifiedExtension, // امتداد ملف معدل
    executableContent, // محتوى تنفيذي مخفي
    unknown         // تهديد غير معروف
  }
  
  // نتيجة الفحص الأمني
  class ScanResult {
    final bool isClean;
    final List<SecurityThreat> threats;
    final DateTime scanTime;
    
    ScanResult({
      required this.isClean,
      required this.threats,
      required this.scanTime,
    });
  }
  
  // تهديد أمني
  class SecurityThreat {
    final ThreatType type;
    final String description;
    final int offset;
    final int length;
    final int severity; // 1-10
    
    SecurityThreat({
      required this.type,
      required this.description,
      required this.offset,
      required this.length,
      required this.severity,
    });
  }
  
  // إعدادات الأمان
  SecurityScanLevel _autoScanLevel = SecurityScanLevel.basic;
  bool _notifyOnThreats = true;
  bool _scanOnFileOpen = true;
  
  // قائمة الملفات في الحجر الصحي
  final List<File> _quarantinedFiles = [];
  
  // سجل نتائج الفحص
  final Map<String, ScanResult> _scanHistory = {};
  
  // قاعدة بيانات بصمات البرمجيات الضارة (مبسطة للتوضيح)
  final List<String> _malwareSignatures = [
    '4D5A900003000000', // بصمة PE/MZ header
    '504B0304', // بصمة ZIP/JAR مع محتوى تنفيذي
    'CAFEBABE', // بصمة Java class
    '7F454C46', // بصمة ELF
  ];
  
  // الحصول على مستوى الفحص التلقائي
  SecurityScanLevel get autoScanLevel => _autoScanLevel;
  
  // تعيين مستوى الفحص التلقائي
  set autoScanLevel(SecurityScanLevel level) {
    _autoScanLevel = level;
    notifyListeners();
  }
  
  // الحصول على إعداد التنبيه عند اكتشاف تهديدات
  bool get notifyOnThreats => _notifyOnThreats;
  
  // تعيين إعداد التنبيه عند اكتشاف تهديدات
  set notifyOnThreats(bool value) {
    _notifyOnThreats = value;
    notifyListeners();
  }
  
  // الحصول على إعداد الفحص عند فتح الملف
  bool get scanOnFileOpen => _scanOnFileOpen;
  
  // تعيين إعداد الفحص عند فتح الملف
  set scanOnFileOpen(bool value) {
    _scanOnFileOpen = value;
    notifyListeners();
  }
  
  // الحصول على قائمة الملفات في الحجر الصحي
  List<File> get quarantinedFiles => List.unmodifiable(_quarantinedFiles);
  
  // الحصول على سجل نتائج الفحص
  Map<String, ScanResult> get scanHistory => Map.unmodifiable(_scanHistory);
  
  // فحص ملف عند فتحه (فحص أساسي)
  Future<ScanResult> quickScanFile(File file) async {
    // قراءة جزء من الملف للفحص السريع
    final fileSize = await file.length();
    final headerSize = min(4096, fileSize);
    final fileHeader = await file.openRead(0, headerSize).toList();
    final headerBytes = fileHeader.expand((chunk) => chunk).toList();
    
    // قائمة التهديدات المكتشفة
    final threats = <SecurityThreat>[];
    
    // فحص رأس الملف
    final headerThreat = _checkFileHeader(file.path, headerBytes);
    if (headerThreat != null) {
      threats.add(headerThreat);
    }
    
    // فحص امتداد الملف
    final extensionThreat = _checkFileExtension(file.path, headerBytes);
    if (extensionThreat != null) {
      threats.add(extensionThreat);
    }
    
    // فحص بصمات البرمجيات الضارة (مبسط)
    final signatureThreat = _checkMalwareSignatures(headerBytes);
    if (signatureThreat != null) {
      threats.add(signatureThreat);
    }
    
    // إنشاء نتيجة الفحص
    final result = ScanResult(
      isClean: threats.isEmpty,
      threats: threats,
      scanTime: DateTime.now(),
    );
    
    // حفظ نتيجة الفحص في السجل
    _scanHistory[file.path] = result;
    
    return result;
  }
  
  // فحص شامل للملف
  Future<ScanResult> thoroughScanFile(File file) async {
    // قراءة الملف بالكامل
    final fileSize = await file.length();
    final fileBytes = await file.readAsBytes();
    
    // قائمة التهديدات المكتشفة
    final threats = <SecurityThreat>[];
    
    // فحص رأس الملف
    final headerThreat = _checkFileHeader(file.path, fileBytes);
    if (headerThreat != null) {
      threats.add(headerThreat);
    }
    
    // فحص امتداد الملف
    final extensionThreat = _checkFileExtension(file.path, fileBytes);
    if (extensionThreat != null) {
      threats.add(extensionThreat);
    }
    
    // فحص بصمات البرمجيات الضارة
    final signatureThreat = _checkMalwareSignatures(fileBytes);
    if (signatureThreat != null) {
      threats.add(signatureThreat);
    }
    
    // فحص الإنتروبيا
    final entropyThreats = _analyzeEntropy(fileBytes);
    threats.addAll(entropyThreats);
    
    // فحص المحتوى التنفيذي المخفي
    final executableThreats = _checkForHiddenExecutableContent(fileBytes);
    threats.addAll(executableThreats);
    
    // إنشاء نتيجة الفحص
    final result = ScanResult(
      isClean: threats.isEmpty,
      threats: threats,
      scanTime: DateTime.now(),
    );
    
    // حفظ نتيجة الفحص في السجل
    _scanHistory[file.path] = result;
    
    return result;
  }
  
  // وضع ملف في الحجر الصحي
  Future<void> quarantineFile(File file) async {
    // نسخ الملف إلى مجلد الحجر الصحي
    final quarantineDir = await _getQuarantineDirectory();
    final fileName = file.path.split('/').last;
    final quarantineFile = File('${quarantineDir.path}/$fileName');
    
    await file.copy(quarantineFile.path);
    
    // إضافة الملف إلى قائمة الحجر الصحي
    _quarantinedFiles.add(quarantineFile);
    
    // حذف الملف الأصلي
    await file.delete();
    
    notifyListeners();
  }
  
  // استعادة ملف من الحجر الصحي
  Future<File> restoreFromQuarantine(File quarantineFile, String destinationPath) async {
    // نسخ الملف من الحجر الصحي إلى الوجهة المحددة
    final restoredFile = await quarantineFile.copy(destinationPath);
    
    // إزالة الملف من قائمة الحجر الصحي
    _quarantinedFiles.remove(quarantineFile);
    
    // حذف الملف من مجلد الحجر الصحي
    await quarantineFile.delete();
    
    notifyListeners();
    
    return restoredFile;
  }
  
  // حذف ملف من الحجر الصحي
  Future<void> deleteFromQuarantine(File quarantineFile) async {
    // إزالة الملف من قائمة الحجر الصحي
    _quarantinedFiles.remove(quarantineFile);
    
    // حذف الملف من مجلد الحجر الصحي
    await quarantineFile.delete();
    
    notifyListeners();
  }
  
  // الحصول على مجلد الحجر الصحي
  Future<Directory> _getQuarantineDirectory() async {
    final appDir = Directory('/home/ubuntu/projects/by_hex/quarantine');
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return appDir;
  }
  
  // فحص رأس الملف
  SecurityThreat? _checkFileHeader(String filePath, List<int> bytes) {
    if (bytes.isEmpty) {
      return SecurityThreat(
        type: ThreatType.invalidHeader,
        description: 'ملف فارغ أو تالف',
        offset: 0,
        length: 0,
        severity: 5,
      );
    }
    
    final extension = filePath.split('.').last.toLowerCase();
    
    // التحقق من رؤوس الملفات الشائعة
    switch (extension) {
      case 'png':
        // رأس PNG: 89 50 4E 47 0D 0A 1A 0A
        if (bytes.length < 8 || 
            bytes[0] != 0x89 || 
            bytes[1] != 0x50 || 
            bytes[2] != 0x4E || 
            bytes[3] != 0x47 || 
            bytes[4] != 0x0D || 
            bytes[5] != 0x0A || 
            bytes[6] != 0x1A || 
            bytes[7] != 0x0A) {
          return SecurityThreat(
            type: ThreatType.invalidHeader,
            description: 'رأس ملف PNG غير صالح',
            offset: 0,
            length: 8,
            severity: 7,
          );
        }
        break;
      case 'jpg':
      case 'jpeg':
        // رأس JPEG: FF D8 FF
        if (bytes.length < 3 || 
            bytes[0] != 0xFF || 
            bytes[1] != 0xD8 || 
            bytes[2] != 0xFF) {
          return SecurityThreat(
            type: ThreatType.invalidHeader,
            description: 'رأس ملف JPEG غير صالح',
            offset: 0,
            length: 3,
            severity: 7,
          );
        }
        break;
      case 'pdf':
        // رأس PDF: 25 50 44 46 2D
        if (bytes.length < 5 || 
            bytes[0] != 0x25 || 
            bytes[1] != 0x50 || 
            bytes[2] != 0x44 || 
            bytes[3] != 0x46 || 
            bytes[4] != 0x2D) {
          return SecurityThreat(
            type: ThreatType.invalidHeader,
            description: 'رأس ملف PDF غير صالح',
            offset: 0,
            length: 5,
            severity: 7,
          );
        }
        break;
      case 'zip':
        // رأس ZIP: 50 4B 03 04
        if (bytes.length < 4 || 
            bytes[0] != 0x50 || 
            bytes[1] != 0x4B || 
            bytes[2] != 0x03 || 
            bytes[3] != 0x04) {
          return SecurityThreat(
            type: ThreatType.invalidHeader,
            description: 'رأس ملف ZIP غير صالح',
            offset: 0,
            length: 4,
            severity: 7,
          );
        }
        break;
    }
    
    return null;
  }
  
  // فحص امتداد الملف
  SecurityThreat? _checkFileExtension(String filePath, List<int> bytes) {
    if (bytes.isEmpty) {
      return null;
    }
    
    final extension = filePath.split('.').last.toLowerCase();
    
    // التحقق من تطابق الامتداد مع محتوى الملف
    if (bytes.length >= 4) {
      // التحقق من ملفات PNG
      if (bytes[0] == 0x89 && 
          bytes[1] == 0x50 && 
          bytes[2] == 0x4E && 
          bytes[3] == 0x47 && 
          extension != 'png') {
        return SecurityThreat(
          type: ThreatType.modifiedExtension,
          description: 'ملف PNG بامتداد غير صحيح',
          offset: 0,
          length: 4,
          severity: 6,
        );
      }
      
      // التحقق من ملفات JPEG
      if (bytes[0] == 0xFF && 
          bytes[1] == 0xD8 && 
          bytes[2] == 0xFF && 
          extension != 'jpg' && 
          extension != 'jpeg') {
        return SecurityThreat(
          type: ThreatType.modifiedExtension,
          description: 'ملف JPEG بامتداد غير صحيح',
          offset: 0,
          length: 3,
          severity: 6,
        );
      }
      
      // التحقق من ملفات PDF
      if (bytes.length >= 5 && 
          bytes[0] == 0x25 && 
          bytes[1] == 0x50 && 
          bytes[2] == 0x44 && 
          bytes[3] == 0x46 && 
          bytes[4] == 0x2D && 
          extension != 'pdf') {
        return SecurityThreat(
          type: ThreatType.modifiedExtension,
          description: 'ملف PDF بامتداد غير صحيح',
          offset: 0,
          length: 5,
          severity: 6,
        );
      }
      
      // التحقق من ملفات ZIP
      if (bytes[0] == 0x50 && 
          bytes[1] == 0x4B && 
          bytes[2] == 0x03 && 
          bytes[3] == 0x04 && 
          extension != 'zip' && 
          extension != 'jar' && 
          extension != 'apk' && 
          extension != 'docx' && 
          extension != 'xlsx' && 
          extension != 'pptx') {
        return SecurityThreat(
          type: ThreatType.modifiedExtension,
          description: 'ملف ZIP بامتداد غير صحيح',
          offset: 0,
          length: 4,
          severity: 6,
        );
      }
      
      // التحقق من ملفات تنفيذية
      if (bytes[0] == 0x4D && 
          bytes[1] == 0x5A && 
          extension != 'exe' && 
          extension != 'dll' && 
          extension != 'sys') {
        return SecurityThreat(
          type: ThreatType.modifiedExtension,
          description: 'ملف تنفيذي بامتداد غير صحيح',
          offset: 0,
          length: 2,
          severity: 9,
        );
      }
    }
    
    return null;
  }
  
  // فحص بصمات البرمجيات الضارة
  SecurityThreat? _checkMalwareSignatures(List<int> bytes) {
    if (bytes.isEmpty) {
      return null;
    }
    
    // تحويل البايتات إلى سلسلة سداسية عشرية
    final hexString = _bytesToHex(bytes);
    
    // البحث عن بصمات البرمجيات الضارة
    for (final signature in _malwareSignatures) {
      if (hexString.contains(signature)) {
        return SecurityThreat(
          type: ThreatType.malware,
          description: 'تم اكتشاف بصمة برمجية ضارة: $signature',
          offset: hexString.indexOf(signature) ~/ 2,
          length: signature.length ~/ 2,
          severity: 10,
        );
      }
    }
    
    return null;
  }
  
  // تحليل الإنتروبيا
  List<SecurityThreat> _analyzeEntropy(List<int> bytes) {
    final threats = <SecurityThreat>[];
    
    if (bytes.length < 256) {
      return threats;
    }
    
    // تقسيم الملف إلى أجزاء وحساب الإنتروبيا لكل جزء
    final chunkSize = 4096;
    for (int i = 0; i < bytes.length; i += chunkSize) {
      final end = min(i + chunkSize, bytes.length);
      final chunk = bytes.sublist(i, end);
      
      final entropy = _calculateEntropy(chunk);
      
      // الإنتروبيا العالية جدًا قد تشير إلى محتوى مشفر أو مضغوط
      if (entropy > 7.8) {
        threats.add(SecurityThreat(
          type: ThreatType.suspiciousEntropy,
          description: 'إنتروبيا عالية جدًا (${entropy.toStringAsFixed(2)}): قد تشير إلى محتوى مشفر أو مضغوط',
          offset: i,
          length: chunk.length,
          severity: 5,
        ));
      }
    }
    
    return threats;
  }
  
  // حساب الإنتروبيا لمجموعة من البايتات
  double _calculateEntropy(List<int> bytes) {
    if (bytes.isEmpty) {
      return 0.0;
    }
    
    // حساب تكرار كل قيمة
    final Map<int, int> frequencies = {};
    for (final byte in bytes) {
      frequencies[byte] = (frequencies[byte] ?? 0) + 1;
    }
    
    // حساب الإنتروبيا
    double entropy = 0.0;
    final length = bytes.length;
    
    for (final frequency in frequencies.values) {
      final probability = frequency / length;
      entropy -= probability * (log(probability) / log(2));
    }
    
    return entropy;
  }
  
  // فحص المحتوى التنفيذي المخفي
  List<SecurityThreat> _checkForHiddenExecutableContent(List<int> bytes) {
    final threats = <SecurityThreat>[];
    
    if (bytes.length < 64) {
      return threats;
    }
    
    // البحث عن رؤوس الملفات التنفيذية المخفية
    for (int i = 0; i < bytes.length - 4; i++) {
      // البحث عن رأس PE (MZ)
      if (bytes[i] == 0x4D && bytes[i + 1] == 0x5A) {
        threats.add(SecurityThreat(
          type: ThreatType.executableContent,
          description: 'تم اكتشاف محتوى تنفيذي مخفي (PE/MZ header)',
          offset: i,
          length: 2,
          severity: 9,
        ));
      }
      
      // البحث عن رأس ELF
      if (i < bytes.length - 4 && 
          bytes[i] == 0x7F && 
          bytes[i + 1] == 0x45 && 
          bytes[i + 2] == 0x4C && 
          bytes[i + 3] == 0x46) {
        threats.add(SecurityThreat(
          type: ThreatType.executableContent,
          description: 'تم اكتشاف محتوى تنفيذي مخفي (ELF header)',
          offset: i,
          length: 4,
          severity: 9,
        ));
      }
      
      // البحث عن رأس Java Class
      if (i < bytes.length - 4 && 
          bytes[i] == 0xCA && 
          bytes[i + 1] == 0xFE && 
          bytes[i + 2] == 0xBA && 
          bytes[i + 3] == 0xBE) {
        threats.add(SecurityThreat(
          type: ThreatType.executableContent,
          description: 'تم اكتشاف محتوى تنفيذي مخفي (Java Class)',
          offset: i,
          length: 4,
          severity: 8,
        ));
      }
    }
    
    return threats;
  }
  
  // تحويل البايتات إلى سلسلة سداسية عشرية
  String _bytesToHex(List<int> bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase()).join('');
  }
  
  // حساب بصمة SHA-256 للملف
  Future<String> calculateFileHash(File file) async {
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
