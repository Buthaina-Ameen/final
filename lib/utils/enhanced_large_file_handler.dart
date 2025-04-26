import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// مدير للتعامل مع الملفات الكبيرة بكفاءة
/// يستخدم تقنية التحميل الجزئي والتخزين المؤقت لتحسين الأداء
class EnhancedLargeFileHandler {
  final File file;
  final int chunkSize;
  final int maxCachedChunks;
  
  RandomAccessFile? _randomAccessFile;
  int _fileSize = 0;
  
  // ذاكرة التخزين المؤقت للأجزاء المقروءة
  final Map<int, List<int>> _cachedChunks = {};
  // قائمة بترتيب استخدام الأجزاء (LRU - Least Recently Used)
  final List<int> _chunkUsageOrder = [];
  
  // حالة التعديل
  bool _isModified = false;
  bool get isModified => _isModified;
  
  // سجل التعديلات
  final Map<int, int> _originalBytes = {};
  final Map<int, int> _modifiedBytes = {};
  
  EnhancedLargeFileHandler({
    required this.file,
    this.chunkSize = 1024 * 1024, // 1 ميجابايت افتراضيًا
    this.maxCachedChunks = 10,    // 10 أجزاء كحد أقصى
  });
  
  /// تهيئة المدير وفتح الملف
  Future<void> initialize() async {
    _randomAccessFile = await file.open(mode: FileMode.readWrite);
    _fileSize = await file.length();
  }
  
  /// إغلاق الملف وتنظيف الموارد
  Future<void> dispose() async {
    await _randomAccessFile?.close();
    _randomAccessFile = null;
    _cachedChunks.clear();
    _chunkUsageOrder.clear();
    _originalBytes.clear();
    _modifiedBytes.clear();
  }
  
  /// الحصول على حجم الملف
  int get fileSize => _fileSize;
  
  /// قراءة مجموعة من البايتات من الملف
  Future<List<int>> readBytes(int offset, int length) async {
    if (_randomAccessFile == null) {
      throw Exception('File not initialized');
    }
    
    // التأكد من أن الإزاحة والطول ضمن حدود الملف
    offset = max(0, min(offset, _fileSize));
    length = min(length, _fileSize - offset);
    
    // تحديد الأجزاء المطلوبة
    final startChunk = offset ~/ chunkSize;
    final endChunk = (offset + length - 1) ~/ chunkSize;
    
    // قراءة جميع الأجزاء المطلوبة
    List<int> result = List<int>.filled(length, 0);
    int resultOffset = 0;
    
    for (int chunkIndex = startChunk; chunkIndex <= endChunk; chunkIndex++) {
      final chunk = await _getChunk(chunkIndex);
      
      // حساب الإزاحة داخل الجزء
      final chunkStartOffset = chunkIndex * chunkSize;
      final dataStartOffset = max(0, offset - chunkStartOffset);
      final dataEndOffset = min(chunk.length, offset + length - chunkStartOffset);
      final dataLength = dataEndOffset - dataStartOffset;
      
      // نسخ البيانات إلى النتيجة
      for (int i = 0; i < dataLength; i++) {
        if (resultOffset < result.length) {
          // التحقق من وجود تعديلات على هذا البايت
          final globalOffset = chunkStartOffset + dataStartOffset + i;
          if (_modifiedBytes.containsKey(globalOffset)) {
            result[resultOffset] = _modifiedBytes[globalOffset]!;
          } else {
            result[resultOffset] = chunk[dataStartOffset + i];
          }
          resultOffset++;
        }
      }
    }
    
    return result;
  }
  
  /// كتابة بايت في موقع محدد
  Future<void> writeByte(int offset, int value) async {
    if (offset < 0 || offset >= _fileSize) {
      throw RangeError('Offset out of range');
    }
    
    // حفظ القيمة الأصلية إذا لم تكن محفوظة بالفعل
    if (!_originalBytes.containsKey(offset)) {
      final originalValue = await _readOriginalByte(offset);
      _originalBytes[offset] = originalValue;
    }
    
    // تحديث القيمة المعدلة
    _modifiedBytes[offset] = value;
    
    // تحديث حالة التعديل
    _isModified = true;
    
    // تحديث الذاكرة المؤقتة إذا كان الجزء موجودًا فيها
    final chunkIndex = offset ~/ chunkSize;
    if (_cachedChunks.containsKey(chunkIndex)) {
      final chunkOffset = offset % chunkSize;
      _cachedChunks[chunkIndex]![chunkOffset] = value;
    }
  }
  
  /// حفظ التغييرات إلى الملف
  Future<void> saveChanges() async {
    if (_randomAccessFile == null || !_isModified) {
      return;
    }
    
    // كتابة جميع التعديلات إلى الملف
    for (final entry in _modifiedBytes.entries) {
      final offset = entry.key;
      final value = entry.value;
      
      await _randomAccessFile!.setPosition(offset);
      await _randomAccessFile!.writeByte(value);
    }
    
    // إعادة تعيين حالة التعديل
    _isModified = false;
    _originalBytes.clear();
    _modifiedBytes.clear();
    
    // إعادة تحميل الأجزاء المخزنة مؤقتًا
    _cachedChunks.clear();
    _chunkUsageOrder.clear();
  }
  
  /// التراجع عن جميع التغييرات
  void discardChanges() {
    _isModified = false;
    _originalBytes.clear();
    _modifiedBytes.clear();
    
    // إعادة تحميل الأجزاء المخزنة مؤقتًا
    _cachedChunks.clear();
    _chunkUsageOrder.clear();
  }
  
  /// الحصول على قائمة بالتعديلات
  List<MapEntry<int, List<int>>> getModifications() {
    List<MapEntry<int, List<int>>> modifications = [];
    
    for (final entry in _modifiedBytes.entries) {
      final offset = entry.key;
      final newValue = entry.value;
      final originalValue = _originalBytes[offset] ?? 0;
      
      modifications.add(MapEntry(offset, [originalValue, newValue]));
    }
    
    // ترتيب التعديلات حسب الإزاحة
    modifications.sort((a, b) => a.key.compareTo(b.key));
    
    return modifications;
  }
  
  /// قراءة جزء من الملف وتخزينه مؤقتًا
  Future<List<int>> _getChunk(int chunkIndex) async {
    // التحقق من وجود الجزء في الذاكرة المؤقتة
    if (_cachedChunks.containsKey(chunkIndex)) {
      // تحديث ترتيب الاستخدام
      _chunkUsageOrder.remove(chunkIndex);
      _chunkUsageOrder.add(chunkIndex);
      
      return _cachedChunks[chunkIndex]!;
    }
    
    // قراءة الجزء من الملف
    final chunkOffset = chunkIndex * chunkSize;
    final chunkLength = min(chunkSize, _fileSize - chunkOffset);
    
    await _randomAccessFile!.setPosition(chunkOffset);
    final chunk = await _randomAccessFile!.read(chunkLength);
    
    // إدارة الذاكرة المؤقتة (LRU)
    if (_cachedChunks.length >= maxCachedChunks && _chunkUsageOrder.isNotEmpty) {
      final oldestChunk = _chunkUsageOrder.removeAt(0);
      _cachedChunks.remove(oldestChunk);
    }
    
    // تخزين الجزء في الذاكرة المؤقتة
    _cachedChunks[chunkIndex] = chunk;
    _chunkUsageOrder.add(chunkIndex);
    
    return chunk;
  }
  
  /// قراءة بايت أصلي من الملف (بدون تعديلات)
  Future<int> _readOriginalByte(int offset) async {
    final chunkIndex = offset ~/ chunkSize;
    final chunkOffset = offset % chunkSize;
    
    // محاولة قراءة من الذاكرة المؤقتة أولاً
    if (_cachedChunks.containsKey(chunkIndex)) {
      return _cachedChunks[chunkIndex]![chunkOffset];
    }
    
    // قراءة مباشرة من الملف
    await _randomAccessFile!.setPosition(offset);
    return await _randomAccessFile!.readByte();
  }
  
  /// إضافة بايتات إلى نهاية الملف
  Future<void> appendBytes(List<int> bytes) async {
    if (_randomAccessFile == null) {
      throw Exception('File not initialized');
    }
    
    // الانتقال إلى نهاية الملف
    await _randomAccessFile!.setPosition(_fileSize);
    
    // كتابة البايتات
    await _randomAccessFile!.writeFrom(bytes);
    
    // تحديث حجم الملف
    _fileSize += bytes.length;
    
    // تحديث حالة التعديل
    _isModified = true;
  }
  
  /// حذف مجموعة من البايتات
  Future<void> deleteBytes(int offset, int length) async {
    if (_randomAccessFile == null) {
      throw Exception('File not initialized');
    }
    
    if (offset < 0 || offset >= _fileSize || length <= 0) {
      return;
    }
    
    // التأكد من أن الطول ضمن حدود الملف
    length = min(length, _fileSize - offset);
    
    // قراءة البايتات بعد المنطقة المحذوفة
    final tailOffset = offset + length;
    final tailLength = _fileSize - tailOffset;
    List<int> tailBytes = [];
    
    if (tailLength > 0) {
      tailBytes = await readBytes(tailOffset, tailLength);
    }
    
    // إعادة كتابة الملف
    await _randomAccessFile!.setPosition(offset);
    if (tailBytes.isNotEmpty) {
      await _randomAccessFile!.writeFrom(tailBytes);
    }
    
    // تحديث حجم الملف
    _fileSize -= length;
    await _randomAccessFile!.truncate(_fileSize);
    
    // تحديث حالة التعديل
    _isModified = true;
    
    // إعادة تعيين الذاكرة المؤقتة
    _cachedChunks.clear();
    _chunkUsageOrder.clear();
    _originalBytes.clear();
    _modifiedBytes.clear();
  }
  
  /// إدراج مجموعة من البايتات
  Future<void> insertBytes(int offset, List<int> bytes) async {
    if (_randomAccessFile == null) {
      throw Exception('File not initialized');
    }
    
    if (offset < 0 || offset > _fileSize || bytes.isEmpty) {
      return;
    }
    
    // قراءة البايتات بعد نقطة الإدراج
    final tailLength = _fileSize - offset;
    List<int> tailBytes = [];
    
    if (tailLength > 0) {
      tailBytes = await readBytes(offset, tailLength);
    }
    
    // كتابة البايتات الجديدة
    await _randomAccessFile!.setPosition(offset);
    await _randomAccessFile!.writeFrom(bytes);
    
    // كتابة البايتات القديمة بعد البايتات الجديدة
    if (tailBytes.isNotEmpty) {
      await _randomAccessFile!.writeFrom(tailBytes);
    }
    
    // تحديث حجم الملف
    _fileSize += bytes.length;
    
    // تحديث حالة التعديل
    _isModified = true;
    
    // إعادة تعيين الذاكرة المؤقتة
    _cachedChunks.clear();
    _chunkUsageOrder.clear();
    _originalBytes.clear();
    _modifiedBytes.clear();
  }
  
  /// البحث عن نمط من البايتات
  Future<List<int>> searchPattern(List<int> pattern) async {
    if (_randomAccessFile == null || pattern.isEmpty) {
      return [];
    }
    
    List<int> results = [];
    final bufferSize = max(chunkSize, pattern.length * 2);
    int offset = 0;
    
    while (offset < _fileSize) {
      // قراءة جزء من الملف
      final length = min(bufferSize, _fileSize - offset);
      final buffer = await readBytes(offset, length);
      
      // البحث عن النمط في الجزء
      for (int i = 0; i <= buffer.length - pattern.length; i++) {
        bool found = true;
        
        for (int j = 0; j < pattern.length; j++) {
          if (buffer[i + j] != pattern[j]) {
            found = false;
            break;
          }
        }
        
        if (found) {
          results.add(offset + i);
        }
      }
      
      // الانتقال إلى الجزء التالي مع تداخل بحجم النمط - 1
      offset += bufferSize - (pattern.length - 1);
    }
    
    return results;
  }
}
