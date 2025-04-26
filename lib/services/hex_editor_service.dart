import 'package:flutter/material.dart';
import 'package:by_hex/constants/app_colors.dart';
import 'package:by_hex/services/file_service.dart';
import 'package:provider/provider.dart';

class HexEditorService extends ChangeNotifier {
  // عدد البايتات في كل صف
  final int bytesPerRow = 16;
  
  // البايت المحدد حاليًا
  int? _selectedOffset;
  
  // نطاق البحث المحدد
  int? _searchStartOffset;
  int? _searchEndOffset;
  
  // نتائج البحث الحالية
  List<int> _searchResults = [];
  int _currentSearchResultIndex = -1;
  
  // الحصول على البايت المحدد
  int? get selectedOffset => _selectedOffset;
  
  // الحصول على نتائج البحث
  List<int> get searchResults => _searchResults;
  int get currentSearchResultIndex => _currentSearchResultIndex;
  
  // تحديد بايت
  void selectByte(int offset) {
    _selectedOffset = offset;
    notifyListeners();
  }
  
  // إلغاء تحديد البايت
  void clearSelection() {
    _selectedOffset = null;
    notifyListeners();
  }
  
  // تحديث قيمة البايت المحدد
  void updateSelectedByte(int value, FileService fileService) {
    if (_selectedOffset != null && fileService.fileBytes != null) {
      fileService.updateByte(_selectedOffset!, value);
      notifyListeners();
    }
  }
  
  // البحث عن قيمة Hex
  void searchHex(String hexValue, FileService fileService) {
    if (fileService.fileBytes == null) return;
    
    _searchResults = [];
    _currentSearchResultIndex = -1;
    
    try {
      // تحويل سلسلة Hex إلى قائمة بايتات
      final List<int> searchBytes = [];
      final hexPattern = RegExp(r'[0-9A-Fa-f]{2}');
      final matches = hexPattern.allMatches(hexValue);
      
      for (final match in matches) {
        final byteValue = int.parse(match.group(0)!, radix: 16);
        searchBytes.add(byteValue);
      }
      
      if (searchBytes.isEmpty) return;
      
      // البحث عن تطابق في البايتات
      final fileBytes = fileService.fileBytes!;
      for (int i = 0; i <= fileBytes.length - searchBytes.length; i++) {
        bool found = true;
        for (int j = 0; j < searchBytes.length; j++) {
          if (fileBytes[i + j] != searchBytes[j]) {
            found = false;
            break;
          }
        }
        
        if (found) {
          _searchResults.add(i);
        }
      }
      
      // الانتقال إلى النتيجة الأولى إذا وجدت
      if (_searchResults.isNotEmpty) {
        _currentSearchResultIndex = 0;
        _selectedOffset = _searchResults[0];
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('خطأ في البحث: $e');
    }
  }
  
  // البحث عن نص
  void searchText(String text, FileService fileService) {
    if (fileService.fileBytes == null) return;
    
    _searchResults = [];
    _currentSearchResultIndex = -1;
    
    try {
      // تحويل النص إلى بايتات UTF-8
      final List<int> searchBytes = text.codeUnits;
      
      if (searchBytes.isEmpty) return;
      
      // البحث عن تطابق في البايتات
      final fileBytes = fileService.fileBytes!;
      for (int i = 0; i <= fileBytes.length - searchBytes.length; i++) {
        bool found = true;
        for (int j = 0; j < searchBytes.length; j++) {
          if (fileBytes[i + j] != searchBytes[j]) {
            found = false;
            break;
          }
        }
        
        if (found) {
          _searchResults.add(i);
        }
      }
      
      // الانتقال إلى النتيجة الأولى إذا وجدت
      if (_searchResults.isNotEmpty) {
        _currentSearchResultIndex = 0;
        _selectedOffset = _searchResults[0];
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('خطأ في البحث: $e');
    }
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
  
  // تحويل بايت إلى تمثيل ASCII/UTF-8
  String byteToAscii(int byte) {
    if (byte >= 32 && byte <= 126) {
      return String.fromCharCode(byte);
    } else {
      return '.';
    }
  }
  
  // تحويل بايت إلى تمثيل Hex
  String byteToHex(int byte) {
    return byte.toRadixString(16).padLeft(2, '0').toUpperCase();
  }
  
  // تحويل قيمة Hex إلى بايت
  int? hexToByte(String hex) {
    try {
      return int.parse(hex, radix: 16);
    } catch (e) {
      return null;
    }
  }
  
  // مقارنة ملفين
  Map<String, dynamic> compareFiles(List<int> file1Bytes, List<int> file2Bytes) {
    final int minLength = file1Bytes.length < file2Bytes.length ? file1Bytes.length : file2Bytes.length;
    final List<int> diffOffsets = [];
    
    // البحث عن الاختلافات
    for (int i = 0; i < minLength; i++) {
      if (file1Bytes[i] != file2Bytes[i]) {
        diffOffsets.add(i);
      }
    }
    
    return {
      'diffCount': diffOffsets.length,
      'diffOffsets': diffOffsets,
      'sizeDiff': file1Bytes.length - file2Bytes.length,
      'file1Length': file1Bytes.length,
      'file2Length': file2Bytes.length,
    };
  }
}
