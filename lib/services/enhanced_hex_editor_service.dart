import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:by_hex/services/file_service.dart';
import 'package:by_hex/utils/large_file_handler.dart';

class EnhancedHexEditorService extends ChangeNotifier {
  // عدد البايتات في كل صف
  final int bytesPerRow = 16;
  
  // الإزاحة المحددة حاليًا
  int? _selectedOffset;
  int? get selectedOffset => _selectedOffset;
  
  // نتائج البحث
  final List<int> _searchResults = [];
  List<int> get searchResults => List.unmodifiable(_searchResults);
  
  // مؤشر نتيجة البحث الحالية
  int _currentSearchResultIndex = -1;
  
  // تحديد بايت معين
  void selectByte(int offset) {
    _selectedOffset = offset;
    notifyListeners();
  }
  
  // تحديث قيمة البايت المحدد
  Future<void> updateSelectedByte(int newValue, FileService fileService) async {
    if (_selectedOffset == null || fileService.fileBytes == null) return;
    
    if (_selectedOffset! < fileService.fileBytes!.length) {
      // تحديث البايت في الذاكرة
      fileService.fileBytes![_selectedOffset!] = newValue;
      
      // تحديث البايت في الملف إذا كان مدير الملفات الكبيرة مستخدمًا
      if (fileService.largeFileHandler != null) {
        await fileService.largeFileHandler!.writeByte(_selectedOffset!, newValue);
      }
      
      // تعيين علامة التعديل
      fileService.setModified(true);
      
      notifyListeners();
    }
  }
  
  // تحويل بايت إلى تمثيل سداسي عشري
  String byteToHex(int byte) {
    return byte.toRadixString(16).padLeft(2, '0').toUpperCase();
  }
  
  // تحويل بايت إلى تمثيل ASCII
  String byteToAscii(int byte) {
    if (byte >= 32 && byte <= 126) {
      return String.fromCharCode(byte);
    } else {
      return '.';
    }
  }
  
  // البحث عن قيمة سداسية عشرية
  Future<void> searchHex(String hexString, FileService fileService) async {
    _searchResults.clear();
    _currentSearchResultIndex = -1;
    
    if (fileService.fileBytes == null) return;
    
    // تنظيف سلسلة البحث
    final cleanHex = hexString.replaceAll(' ', '').toUpperCase();
    if (cleanHex.isEmpty) return;
    
    // التحقق من صحة السلسلة السداسية عشرية
    final hexPattern = RegExp(r'^[0-9A-F]+$');
    if (!hexPattern.hasMatch(cleanHex)) return;
    
    // تحويل السلسلة السداسية عشرية إلى قائمة بايتات
    final List<int> pattern = [];
    for (int i = 0; i < cleanHex.length; i += 2) {
      if (i + 1 < cleanHex.length) {
        final hexByte = cleanHex.substring(i, i + 2);
        pattern.add(int.parse(hexByte, radix: 16));
      }
    }
    
    if (pattern.isEmpty) return;
    
    // البحث باستخدام مدير الملفات الكبيرة إذا كان متاحًا
    if (fileService.largeFileHandler != null) {
      _searchResults.addAll(await fileService.largeFileHandler!.searchPattern(pattern));
    } else {
      // البحث في الذاكرة للملفات الصغيرة
      final bytes = fileService.fileBytes!;
      for (int i = 0; i <= bytes.length - pattern.length; i++) {
        bool found = true;
        for (int j = 0; j < pattern.length; j++) {
          if (bytes[i + j] != pattern[j]) {
            found = false;
            break;
          }
        }
        
        if (found) {
          _searchResults.add(i);
        }
      }
    }
    
    // تحديد أول نتيجة إذا وجدت
    if (_searchResults.isNotEmpty) {
      _currentSearchResultIndex = 0;
      _selectedOffset = _searchResults[0];
    }
    
    notifyListeners();
  }
  
  // البحث عن نص
  Future<void> searchText(String text, FileService fileService) async {
    _searchResults.clear();
    _currentSearchResultIndex = -1;
    
    if (fileService.fileBytes == null || text.isEmpty) return;
    
    // تحويل النص إلى بايتات UTF-8
    final List<int> pattern = utf8.encode(text);
    
    // البحث باستخدام مدير الملفات الكبيرة إذا كان متاحًا
    if (fileService.largeFileHandler != null) {
      _searchResults.addAll(await fileService.largeFileHandler!.searchPattern(pattern));
    } else {
      // البحث في الذاكرة للملفات الصغيرة
      final bytes = fileService.fileBytes!;
      for (int i = 0; i <= bytes.length - pattern.length; i++) {
        bool found = true;
        for (int j = 0; j < pattern.length; j++) {
          if (bytes[i + j] != pattern[j]) {
            found = false;
            break;
          }
        }
        
        if (found) {
          _searchResults.add(i);
        }
      }
    }
    
    // تحديد أول نتيجة إذا وجدت
    if (_searchResults.isNotEmpty) {
      _currentSearchResultIndex = 0;
      _selectedOffset = _searchResults[0];
    }
    
    notifyListeners();
  }
  
  // الانتقال إلى نتيجة البحث التالية
  void nextSearchResult() {
    if (_searchResults.isEmpty) return;
    
    _currentSearchResultIndex = (_currentSearchResultIndex + 1) % _searchResults.length;
    _selectedOffset = _searchResults[_currentSearchResultIndex];
    
    notifyListeners();
  }
  
  // الانتقال إلى نتيجة البحث السابقة
  void previousSearchResult() {
    if (_searchResults.isEmpty) return;
    
    _currentSearchResultIndex = (_currentSearchResultIndex - 1 + _searchResults.length) % _searchResults.length;
    _selectedOffset = _searchResults[_currentSearchResultIndex];
    
    notifyListeners();
  }
  
  // مقارنة ملفين
  Map<String, dynamic> compareFiles(List<int> file1Bytes, List<int> file2Bytes) {
    final List<int> diffOffsets = [];
    final int minLength = file1Bytes.length < file2Bytes.length ? file1Bytes.length : file2Bytes.length;
    
    // البحث عن الاختلافات في الجزء المشترك
    for (int i = 0; i < minLength; i++) {
      if (file1Bytes[i] != file2Bytes[i]) {
        diffOffsets.add(i);
      }
    }
    
    return {
      'diffOffsets': diffOffsets,
      'diffCount': diffOffsets.length,
      'sizeDiff': file1Bytes.length - file2Bytes.length,
      'file1Length': file1Bytes.length,
      'file2Length': file2Bytes.length,
    };
  }
  
  // تحليل نوع الملف بناءً على السحرية (magic numbers)
  String analyzeFileType(List<int> bytes) {
    if (bytes.length < 8) return 'Unknown';
    
    // التحقق من أنواع الملفات الشائعة بناءً على السحرية
    if (bytes[0] == 0x50 && bytes[1] == 0x4B && bytes[2] == 0x03 && bytes[3] == 0x04) {
      return 'ZIP Archive';
    } else if (bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46) {
      return 'PDF Document';
    } else if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'JPEG Image';
    } else if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return 'PNG Image';
    } else if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x38) {
      return 'GIF Image';
    } else if ((bytes[0] == 0x49 && bytes[1] == 0x49) || (bytes[0] == 0x4D && bytes[1] == 0x4D)) {
      return 'TIFF Image';
    } else if (bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return 'BMP Image';
    } else if (bytes[0] == 0x7F && bytes[1] == 0x45 && bytes[2] == 0x4C && bytes[3] == 0x46) {
      return 'ELF Executable';
    } else if (bytes[0] == 0x4D && bytes[1] == 0x5A) {
      return 'Windows Executable';
    } else if (bytes[0] == 0xCA && bytes[1] == 0xFE && bytes[2] == 0xBA && bytes[3] == 0xBE) {
      return 'Java Class File';
    } else if (bytes[0] == 0x52 && bytes[1] == 0x61 && bytes[2] == 0x72 && bytes[3] == 0x21) {
      return 'RAR Archive';
    } else if (bytes[0] == 0x1F && bytes[1] == 0x8B) {
      return 'GZIP Archive';
    } else if (bytes[0] == 0x37 && bytes[1] == 0x7A && bytes[2] == 0xBC && bytes[3] == 0xAF) {
      return '7Z Archive';
    } else if (bytes[0] == 0xD0 && bytes[1] == 0xCF && bytes[2] == 0x11 && bytes[3] == 0xE0) {
      return 'Microsoft Office Document';
    } else if (bytes[0] == 0x50 && bytes[1] == 0x4B && bytes[2] == 0x03 && bytes[3] == 0x04 &&
               bytes[30] == 0x77 && bytes[31] == 0x6F && bytes[32] == 0x72 && bytes[33] == 0x64) {
      return 'DOCX Document';
    } else if (bytes[0] == 0x50 && bytes[1] == 0x4B && bytes[2] == 0x03 && bytes[3] == 0x04 &&
               bytes[30] == 0x78 && bytes[31] == 0x6C && bytes[32] == 0x73 && bytes[33] == 0x78) {
      return 'XLSX Spreadsheet';
    }
    
    return 'Unknown';
  }
  
  // تحليل توزيع البايتات في الملف
  Map<String, dynamic> analyzeByteDistribution(List<int> bytes) {
    final Map<int, int> distribution = {};
    
    // حساب تكرار كل بايت
    for (int i = 0; i < bytes.length; i++) {
      final byte = bytes[i];
      distribution[byte] = (distribution[byte] ?? 0) + 1;
    }
    
    // حساب النسبة المئوية لكل بايت
    final Map<int, double> percentages = {};
    distribution.forEach((byte, count) {
      percentages[byte] = (count / bytes.length) * 100;
    });
    
    // إيجاد أكثر البايتات تكرارًا
    final List<MapEntry<int, int>> mostCommon = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // حساب الإنتروبيا (مقياس للعشوائية)
    double entropy = 0;
    percentages.forEach((byte, percentage) {
      final probability = percentage / 100;
      entropy -= probability * (log2(probability));
    });
    
    return {
      'distribution': distribution,
      'percentages': percentages,
      'mostCommon': mostCommon.take(10).toList(),
      'entropy': entropy,
      'isCompressed': entropy > 7.0, // قيمة تقريبية للملفات المضغوطة
      'isEncrypted': entropy > 7.8, // قيمة تقريبية للملفات المشفرة
    };
  }
  
  // حساب لوغاريتم الأساس 2
  double log2(double x) {
    return log(x) / log(2);
  }
  
  // حساب لوغاريتم طبيعي
  double log(double x) {
    return x > 0 ? _naturalLog(x) : 0;
  }
  
  // تقريب للوغاريتم الطبيعي
  double _naturalLog(double x) {
    if (x <= 0) return 0;
    
    // تقريب للوغاريتم الطبيعي باستخدام سلسلة تايلور
    double result = 0;
    double term = (x - 1) / (x + 1);
    double termSquared = term * term;
    double currentTerm = term;
    
    for (int i = 1; i <= 10; i += 2) {
      result += currentTerm / i;
      currentTerm *= termSquared;
    }
    
    return 2 * result;
  }
}
