import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// مدير للتعامل مع الملفات الكبيرة بكفاءة
/// يستخدم تقنية التحميل الجزئي والتخزين المؤقت لتحسين الأداء
class LargeFileHandler {
  final File file;
  final int chunkSize;
  final int maxCachedChunks;
  
  // التخزين المؤقت للأجزاء المحملة
  final Map<int, List<int>> _cachedChunks = {};
  // ترتيب استخدام الأجزاء للتخلص من الأقل استخدامًا
  final List<int> _chunkUsageOrder = [];
  
  int _fileSize = 0;
  RandomAccessFile? _randomAccessFile;
  
  LargeFileHandler({
    required this.file,
    this.chunkSize = 1024 * 1024, // 1 ميجابايت افتراضيًا
    this.maxCachedChunks = 10,    // 10 أجزاء كحد أقصى في الذاكرة
  });
  
  /// تهيئة المدير وفتح الملف
  Future<void> initialize() async {
    _fileSize = await file.length();
    _randomAccessFile = await file.open(mode: FileMode.read);
  }
  
  /// إغلاق الملف وتنظيف الموارد
  Future<void> dispose() async {
    await _randomAccessFile?.close();
    _randomAccessFile = null;
    _cachedChunks.clear();
    _chunkUsageOrder.clear();
  }
  
  /// الحصول على حجم الملف
  int get fileSize => _fileSize;
  
  /// قراءة جزء من البيانات من الملف
  Future<List<int>> readBytes(int offset, int length) async {
    if (_randomAccessFile == null) {
      throw Exception('File not initialized. Call initialize() first.');
    }
    
    // التأكد من أن الطلب ضمن حدود الملف
    if (offset < 0 || offset >= _fileSize) {
      throw RangeError('Offset out of range');
    }
    
    final actualLength = (offset + length > _fileSize) 
        ? _fileSize - offset 
        : length;
    
    // تحديد الأجزاء المطلوبة
    final startChunk = offset ~/ chunkSize;
    final endChunk = (offset + actualLength - 1) ~/ chunkSize;
    
    // تجميع البيانات من الأجزاء
    final result = Uint8List(actualLength);
    var resultOffset = 0;
    
    for (var i = startChunk; i <= endChunk; i++) {
      final chunk = await _getChunk(i);
      
      final chunkOffset = i * chunkSize;
      final readOffset = (offset > chunkOffset) ? offset - chunkOffset : 0;
      final readLength = min(
        chunk.length - readOffset,
        actualLength - resultOffset
      );
      
      for (var j = 0; j < readLength; j++) {
        result[resultOffset + j] = chunk[readOffset + j];
      }
      
      resultOffset += readLength;
    }
    
    return result;
  }
  
  /// تعديل بايت واحد في الملف
  Future<void> writeByte(int offset, int value) async {
    if (_randomAccessFile == null) {
      throw Exception('File not initialized. Call initialize() first.');
    }
    
    if (offset < 0 || offset >= _fileSize) {
      throw RangeError('Offset out of range');
    }
    
    // تحديث التخزين المؤقت إذا كان الجزء محملًا
    final chunkIndex = offset ~/ chunkSize;
    if (_cachedChunks.containsKey(chunkIndex)) {
      final chunk = _cachedChunks[chunkIndex]!;
      final chunkOffset = offset % chunkSize;
      chunk[chunkOffset] = value;
    }
    
    // كتابة البايت في الملف
    await _randomAccessFile!.setPosition(offset);
    await _randomAccessFile!.writeByte(value);
    await _randomAccessFile!.flush();
  }
  
  /// البحث عن نمط من البايتات في الملف
  Future<List<int>> searchPattern(List<int> pattern) async {
    final results = <int>[];
    
    // استخدام حجم مناسب للبحث
    const searchBufferSize = 1024 * 1024; // 1 ميجابايت
    
    for (var offset = 0; offset < _fileSize; offset += searchBufferSize - pattern.length + 1) {
      final bufferSize = min(searchBufferSize, _fileSize - offset);
      final buffer = await readBytes(offset, bufferSize);
      
      // البحث عن النمط في المخزن المؤقت
      for (var i = 0; i <= buffer.length - pattern.length; i++) {
        var found = true;
        for (var j = 0; j < pattern.length; j++) {
          if (buffer[i + j] != pattern[j]) {
            found = false;
            break;
          }
        }
        
        if (found) {
          results.add(offset + i);
        }
      }
    }
    
    return results;
  }
  
  /// الحصول على جزء من الملف، إما من التخزين المؤقت أو بقراءته من الملف
  Future<List<int>> _getChunk(int chunkIndex) async {
    // تحديث ترتيب استخدام الأجزاء
    _updateChunkUsage(chunkIndex);
    
    // إذا كان الجزء موجودًا في التخزين المؤقت، أعده
    if (_cachedChunks.containsKey(chunkIndex)) {
      return _cachedChunks[chunkIndex]!;
    }
    
    // حساب موقع وحجم الجزء
    final chunkOffset = chunkIndex * chunkSize;
    final chunkLength = min(chunkSize, _fileSize - chunkOffset);
    
    // قراءة الجزء من الملف
    await _randomAccessFile!.setPosition(chunkOffset);
    final chunk = await _randomAccessFile!.read(chunkLength);
    
    // تخزين الجزء في التخزين المؤقت
    _cacheChunk(chunkIndex, chunk);
    
    return chunk;
  }
  
  /// تخزين جزء في التخزين المؤقت مع التخلص من الأجزاء القديمة إذا لزم الأمر
  void _cacheChunk(int chunkIndex, List<int> chunk) {
    // إذا وصلنا للحد الأقصى، تخلص من الجزء الأقدم
    if (_cachedChunks.length >= maxCachedChunks && _chunkUsageOrder.isNotEmpty) {
      final oldestChunk = _chunkUsageOrder.removeAt(0);
      _cachedChunks.remove(oldestChunk);
    }
    
    // تخزين الجزء الجديد
    _cachedChunks[chunkIndex] = chunk;
  }
  
  /// تحديث ترتيب استخدام الأجزاء
  void _updateChunkUsage(int chunkIndex) {
    // إزالة الجزء من الترتيب الحالي إذا كان موجودًا
    _chunkUsageOrder.remove(chunkIndex);
    // إضافة الجزء في نهاية القائمة (الأحدث استخدامًا)
    _chunkUsageOrder.add(chunkIndex);
  }
  
  /// دالة مساعدة لإيجاد الحد الأدنى بين قيمتين
  int min(int a, int b) => (a < b) ? a : b;
}
