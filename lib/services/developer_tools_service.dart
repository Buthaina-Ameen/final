import 'package:flutter/material.dart';
import 'package:by_hex/constants/app_colors.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:by_hex/services/enhanced_file_service.dart';

class DeveloperToolsService {
  // تصدير البيانات بتنسيقات مختلفة
  static Future<String> exportDataAsFormat({
    required List<int> data,
    required String fileName,
    required ExportFormat format,
  }) async {
    final directory = await getTemporaryDirectory();
    String extension;
    List<int> formattedData;
    
    switch (format) {
      case ExportFormat.json:
        extension = 'json';
        formattedData = _formatAsJson(data);
        break;
      case ExportFormat.xml:
        extension = 'xml';
        formattedData = _formatAsXml(data);
        break;
      case ExportFormat.csv:
        extension = 'csv';
        formattedData = _formatAsCsv(data);
        break;
      case ExportFormat.base64:
        extension = 'txt';
        formattedData = utf8.encode(base64Encode(data));
        break;
      case ExportFormat.hexDump:
        extension = 'txt';
        formattedData = utf8.encode(_formatAsHexDump(data));
        break;
      case ExportFormat.binary:
        extension = 'bin';
        formattedData = data;
        break;
    }
    
    final baseFileName = fileName.contains('.')
        ? fileName.substring(0, fileName.lastIndexOf('.'))
        : fileName;
    
    final outputFile = File('${directory.path}/${baseFileName}_export.$extension');
    await outputFile.writeAsBytes(formattedData);
    
    return outputFile.path;
  }
  
  // استيراد البيانات من تنسيقات مختلفة
  static Future<List<int>> importDataFromFormat({
    required File file,
    required ImportFormat format,
  }) async {
    final fileData = await file.readAsBytes();
    
    switch (format) {
      case ImportFormat.json:
        return _parseFromJson(fileData);
      case ImportFormat.xml:
        return _parseFromXml(fileData);
      case ImportFormat.base64:
        return _parseFromBase64(fileData);
      case ImportFormat.hexDump:
        return _parseFromHexDump(fileData);
      case ImportFormat.binary:
        return fileData;
    }
  }
  
  // تحليل نوع الملف وتنسيقه
  static Future<ImportFormat?> detectFileFormat(File file) async {
    final extension = file.path.split('.').last.toLowerCase();
    final firstBytes = await file.openRead(0, 50).first;
    
    // التحقق من التنسيق بناءً على الامتداد
    switch (extension) {
      case 'json':
        return ImportFormat.json;
      case 'xml':
        return ImportFormat.xml;
      case 'txt':
        // التحقق مما إذا كان النص base64 أو hex dump
        final content = utf8.decode(firstBytes, allowMalformed: true);
        if (_isBase64(content)) {
          return ImportFormat.base64;
        } else if (_isHexDump(content)) {
          return ImportFormat.hexDump;
        }
        break;
      case 'bin':
        return ImportFormat.binary;
    }
    
    // إذا لم يتم التعرف على التنسيق من الامتداد، حاول التعرف من المحتوى
    final content = utf8.decode(firstBytes, allowMalformed: true);
    if (content.trim().startsWith('{') && content.contains('"')) {
      return ImportFormat.json;
    } else if (content.trim().startsWith('<') && content.contains('>')) {
      return ImportFormat.xml;
    } else if (_isBase64(content)) {
      return ImportFormat.base64;
    } else if (_isHexDump(content)) {
      return ImportFormat.hexDump;
    }
    
    // إذا لم يتم التعرف على التنسيق، افترض أنه ثنائي
    return ImportFormat.binary;
  }
  
  // التكامل مع أدوات التطوير الأخرى
  static Future<String> integrateWithExternalTool({
    required List<int> data,
    required ExternalTool tool,
    required String apiKey,
  }) async {
    switch (tool) {
      case ExternalTool.ghidra:
        return _exportForGhidra(data);
      case ExternalTool.ida:
        return _exportForIda(data);
      case ExternalTool.wireshark:
        return _exportForWireshark(data);
      case ExternalTool.ollydbg:
        return _exportForOllyDbg(data);
      case ExternalTool.radare2:
        return _exportForRadare2(data);
      case ExternalTool.binaryNinja:
        return _exportForBinaryNinja(data);
      case ExternalTool.custom:
        return _exportForCustomTool(data, apiKey);
    }
  }
  
  // تنسيق البيانات كـ JSON
  static List<int> _formatAsJson(List<int> data) {
    final Map<String, dynamic> jsonData = {
      'format': 'hex',
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'size': data.length,
      'data': data.map((byte) => byte.toRadixString(16).padLeft(2, '0')).toList(),
    };
    
    return utf8.encode(JsonEncoder.withIndent('  ').convert(jsonData));
  }
  
  // تنسيق البيانات كـ XML
  static List<int> _formatAsXml(List<int> data) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<hexData>');
    buffer.writeln('  <metadata>');
    buffer.writeln('    <format>hex</format>');
    buffer.writeln('    <version>1.0</version>');
    buffer.writeln('    <timestamp>${DateTime.now().toIso8601String()}</timestamp>');
    buffer.writeln('    <size>${data.length}</size>');
    buffer.writeln('  </metadata>');
    buffer.writeln('  <bytes>');
    
    for (int i = 0; i < data.length; i += 16) {
      buffer.write('    <row offset="0x${i.toRadixString(16).padLeft(8, '0')}">');
      
      for (int j = 0; j < 16 && i + j < data.length; j++) {
        final byte = data[i + j];
        buffer.write('<byte>');
        buffer.write(byte.toRadixString(16).padLeft(2, '0'));
        buffer.write('</byte>');
      }
      
      buffer.writeln('</row>');
    }
    
    buffer.writeln('  </bytes>');
    buffer.writeln('</hexData>');
    
    return utf8.encode(buffer.toString());
  }
  
  // تنسيق البيانات كـ CSV
  static List<int> _formatAsCsv(List<int> data) {
    final buffer = StringBuffer();
    buffer.writeln('Offset,Byte 0,Byte 1,Byte 2,Byte 3,Byte 4,Byte 5,Byte 6,Byte 7,Byte 8,Byte 9,Byte A,Byte B,Byte C,Byte D,Byte E,Byte F,ASCII');
    
    for (int i = 0; i < data.length; i += 16) {
      // إضافة الإزاحة
      buffer.write('0x${i.toRadixString(16).padLeft(8, '0')},');
      
      // إضافة قيم البايتات
      for (int j = 0; j < 16; j++) {
        if (i + j < data.length) {
          buffer.write(data[i + j].toRadixString(16).padLeft(2, '0'));
        }
        buffer.write(',');
      }
      
      // إضافة تمثيل ASCII
      for (int j = 0; j < 16 && i + j < data.length; j++) {
        final byte = data[i + j];
        if (byte >= 32 && byte <= 126) {
          buffer.write(String.fromCharCode(byte));
        } else {
          buffer.write('.');
        }
      }
      
      buffer.writeln();
    }
    
    return utf8.encode(buffer.toString());
  }
  
  // تنسيق البيانات كـ Hex Dump
  static String _formatAsHexDump(List<int> data) {
    final buffer = StringBuffer();
    
    for (int i = 0; i < data.length; i += 16) {
      // إضافة الإزاحة
      buffer.write('${i.toRadixString(16).padLeft(8, '0')}  ');
      
      // إضافة قيم البايتات
      for (int j = 0; j < 16; j++) {
        if (i + j < data.length) {
          buffer.write(data[i + j].toRadixString(16).padLeft(2, '0'));
          buffer.write(' ');
        } else {
          buffer.write('   ');
        }
        
        if (j == 7) {
          buffer.write(' ');
        }
      }
      
      buffer.write(' |');
      
      // إضافة تمثيل ASCII
      for (int j = 0; j < 16 && i + j < data.length; j++) {
        final byte = data[i + j];
        if (byte >= 32 && byte <= 126) {
          buffer.write(String.fromCharCode(byte));
        } else {
          buffer.write('.');
        }
      }
      
      buffer.writeln('|');
    }
    
    return buffer.toString();
  }
  
  // تحليل البيانات من JSON
  static List<int> _parseFromJson(List<int> fileData) {
    try {
      final jsonString = utf8.decode(fileData);
      final jsonData = json.decode(jsonString);
      
      if (jsonData is Map && jsonData.containsKey('data')) {
        final dataList = jsonData['data'];
        if (dataList is List) {
          if (dataList.isNotEmpty && dataList.first is String) {
            // تحويل سلاسل سداسية عشرية إلى أرقام
            return dataList.map<int>((hex) => int.parse(hex, radix: 16)).toList();
          } else if (dataList.isNotEmpty && dataList.first is int) {
            // استخدام القيم العددية مباشرة
            return List<int>.from(dataList);
          }
        }
      }
      
      throw FormatException('تنسيق JSON غير صالح');
    } catch (e) {
      throw FormatException('خطأ في تحليل JSON: $e');
    }
  }
  
  // تحليل البيانات من XML
  static List<int> _parseFromXml(List<int> fileData) {
    try {
      final xmlString = utf8.decode(fileData);
      final List<int> result = [];
      
      // تحليل بسيط للعثور على علامات <byte>
      final byteRegex = RegExp(r'<byte>([0-9a-fA-F]{2})</byte>');
      final matches = byteRegex.allMatches(xmlString);
      
      for (final match in matches) {
        if (match.groupCount >= 1) {
          final hexValue = match.group(1);
          if (hexValue != null) {
            result.add(int.parse(hexValue, radix: 16));
          }
        }
      }
      
      if (result.isEmpty) {
        throw FormatException('لم يتم العثور على بيانات بايت في XML');
      }
      
      return result;
    } catch (e) {
      throw FormatException('خطأ في تحليل XML: $e');
    }
  }
  
  // تحليل البيانات من Base64
  static List<int> _parseFromBase64(List<int> fileData) {
    try {
      final base64String = utf8.decode(fileData).trim();
      return base64Decode(base64String);
    } catch (e) {
      throw FormatException('خطأ في تحليل Base64: $e');
    }
  }
  
  // تحليل البيانات من Hex Dump
  static List<int> _parseFromHexDump(List<int> fileData) {
    try {
      final hexDumpString = utf8.decode(fileData);
      final List<int> result = [];
      
      // تحليل كل سطر
      final lines = hexDumpString.split('\n');
      for (final line in lines) {
        // تجاهل السطور الفارغة أو غير الصالحة
        if (line.trim().isEmpty) continue;
        
        // البحث عن جزء البايتات (بعد الإزاحة وقبل تمثيل ASCII)
        final parts = line.split('|');
        if (parts.length < 1) continue;
        
        final hexPart = parts[0].trim();
        // تجاهل الإزاحة (عادة 8 أحرف في البداية)
        final hexValues = hexPart.substring(8).trim();
        
        // استخراج قيم البايتات
        final hexRegex = RegExp(r'([0-9a-fA-F]{2})');
        final matches = hexRegex.allMatches(hexValues);
        
        for (final match in matches) {
          if (match.groupCount >= 1) {
            final hexValue = match.group(1);
            if (hexValue != null) {
              result.add(int.parse(hexValue, radix: 16));
            }
          }
        }
      }
      
      if (result.isEmpty) {
        throw FormatException('لم يتم العثور على بيانات بايت في Hex Dump');
      }
      
      return result;
    } catch (e) {
      throw FormatException('خطأ في تحليل Hex Dump: $e');
    }
  }
  
  // التحقق مما إذا كان النص بتنسيق Base64
  static bool _isBase64(String text) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return false;
    
    // التحقق من أن النص يحتوي فقط على أحرف Base64 الصالحة
    final base64Regex = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');
    return base64Regex.hasMatch(trimmedText);
  }
  
  // التحقق مما إذا كان النص بتنسيق Hex Dump
  static bool _isHexDump(String text) {
    final lines = text.split('\n');
    if (lines.isEmpty) return false;
    
    // التحقق من أن السطر الأول يبدأ بإزاحة سداسية عشرية
    final offsetRegex = RegExp(r'^[0-9a-fA-F]{8}');
    return offsetRegex.hasMatch(lines[0].trim());
  }
  
  // تصدير البيانات لأداة Ghidra
  static Future<String> _exportForGhidra(List<int> data) async {
    final directory = await getTemporaryDirectory();
    final outputFile = File('${directory.path}/ghidra_export.bin');
    await outputFile.writeAsBytes(data);
    
    // إنشاء ملف الإعدادات لـ Ghidra
    final settingsFile = File('${directory.path}/ghidra_settings.txt');
    await settingsFile.writeAsString('''
# Ghidra Program Settings
Format: Binary
Architecture: x86
Base Address: 0x00000000
Compiler: gcc
Endian: little
''');
    
    return outputFile.path;
  }
  
  // تصدير البيانات لأداة IDA
  static Future<String> _exportForIda(List<int> data) async {
    final directory = await getTemporaryDirectory();
    final outputFile = File('${directory.path}/ida_export.bin');
    await outputFile.writeAsBytes(data);
    return outputFile.path;
  }
  
  // تصدير البيانات لأداة Wireshark
  static Future<String> _exportForWireshark(List<int> data) async {
    final directory = await getTemporaryDirectory();
    final outputFile = File('${directory.path}/wireshark_export.pcap');
    
    // إنشاء رأس PCAP بسيط
    final pcapHeader = [
      // Magic Number: 0xa1b2c3d4 (little endian)
      0xd4, 0xc3, 0xb2, 0xa1,
      // Version Major: 2
      0x02, 0x00,
      // Version Minor: 4
      0x04, 0x00,
      // Timezone: GMT (0)
      0x00, 0x00, 0x00, 0x00,
      // Timestamp Accuracy: 0
      0x00, 0x00, 0x00, 0x00,
      // Snapshot Length: 65535
      0xff, 0xff, 0x00, 0x00,
      // Link Layer Type: Ethernet (1)
      0x01, 0x00, 0x00, 0x00,
    ];
    
    // إنشاء رأس حزمة بسيط
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final packetHeader = [
      // Timestamp Seconds
      timestamp & 0xff,
      (timestamp >> 8) & 0xff,
      (timestamp >> 16) & 0xff,
      (timestamp >> 24) & 0xff,
      // Timestamp Microseconds: 0
      0x00, 0x00, 0x00, 0x00,
      // Captured Packet Length
      data.length & 0xff,
      (data.length >> 8) & 0xff,
      (data.length >> 16) & 0xff,
      (data.length >> 24) & 0xff,
      // Original Packet Length
      data.length & 0xff,
      (data.length >> 8) & 0xff,
      (data.length >> 16) & 0xff,
      (data.length >> 24) & 0xff,
    ];
    
    // دمج الرؤوس والبيانات
    final pcapData = [...pcapHeader, ...packetHeader, ...data];
    await outputFile.writeAsBytes(pcapData);
    
    return outputFile.path;
  }
  
  // تصدير البيانات لأداة OllyDbg
  static Future<String> _exportForOllyDbg(List<int> data) async {
    final directory = await getTemporaryDirectory();
    final outputFile = File('${directory.path}/ollydbg_export.bin');
    await outputFile.writeAsBytes(data);
    return outputFile.path;
  }
  
  // تصدير البيانات لأداة Radare2
  static Future<String> _exportForRadare2(List<int> data) async {
    final directory = await getTemporaryDirectory();
    final outputFile = File('${directory.path}/radare2_export.bin');
    await outputFile.writeAsBytes(data);
    
    // إنشاء ملف الإعدادات لـ Radare2
    final settingsFile = File('${directory.path}/radare2_settings.r2');
    await settingsFile.writeAsString('''
# Radare2 Settings
e asm.arch=x86
e asm.bits=32
e file.analyze=true
e file.info=true
''');
    
    return outputFile.path;
  }
  
  // تصدير البيانات لأداة Binary Ninja
  static Future<String> _exportForBinaryNinja(List<int> data) async {
    final directory = await getTemporaryDirectory();
    final outputFile = File('${directory.path}/binaryninja_export.bin');
    await outputFile.writeAsBytes(data);
    return outputFile.path;
  }
  
  // تصدير البيانات لأداة مخصصة
  static Future<String> _exportForCustomTool(List<int> data, String apiKey) async {
    final directory = await getTemporaryDirectory();
    final outputFile = File('${directory.path}/custom_export.bin');
    await outputFile.writeAsBytes(data);
    
    // إذا تم توفير مفتاح API، يمكن استخدامه للتكامل مع خدمة مخصصة
    if (apiKey.isNotEmpty) {
      try {
        // مثال: إرسال البيانات إلى خدمة مخصصة
        final response = await http.post(
          Uri.parse('https://api.example.com/analyze'),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/octet-stream',
          },
          body: data,
        );
        
        if (response.statusCode == 200) {
          // حفظ نتيجة التحليل
          final resultFile = File('${directory.path}/custom_analysis_result.json');
          await resultFile.writeAsString(response.body);
          return resultFile.path;
        }
      } catch (e) {
        // تجاهل أخطاء الاتصال وإرجاع الملف الأصلي
      }
    }
    
    return outputFile.path;
  }
}

// تنسيقات التصدير المدعومة
enum ExportFormat {
  json,
  xml,
  csv,
  base64,
  hexDump,
  binary,
}

// تنسيقات الاستيراد المدعومة
enum ImportFormat {
  json,
  xml,
  base64,
  hexDump,
  binary,
}

// أدوات التطوير الخارجية المدعومة
enum ExternalTool {
  ghidra,
  ida,
  wireshark,
  ollydbg,
  radare2,
  binaryNinja,
  custom,
}

// شاشة التكامل مع أدوات التطوير
class DeveloperToolsScreen extends StatefulWidget {
  final File file;
  
  const DeveloperToolsScreen({
    Key? key,
    required this.file,
  }) : super(key: key);

  @override
  State<DeveloperToolsScreen> createState() => _DeveloperToolsScreenState();
}

class _DeveloperToolsScreenState extends State<DeveloperToolsScreen> {
  bool _isLoading = false;
  String? _exportedFilePath;
  String? _errorMessage;
  ExportFormat _selectedExportFormat = ExportFormat.json;
  ExternalTool _selectedExternalTool = ExternalTool.ghidra;
  final TextEditingController _apiKeyController = TextEditingController();
  
  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أدوات التطوير'),
        backgroundColor: AppColors.appBarColor,
        foregroundColor: Colors.black87,
      ),
      body: Container(
        color: AppColors.backgroundColor,
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.mediumPurple),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'جاري معالجة الملف...',
                      style: TextStyle(color: AppColors.textColor),
                    ),
                  ],
                ),
              )
            : _exportedFilePath != null
                ? _buildSuccessView()
                : _errorMessage != null
                    ? _buildErrorView()
                    : _buildOptionsView(),
      ),
    );
  }
  
  Widget _buildOptionsView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تصدير البيانات',
            style: TextStyle(
              color: AppColors.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اختر تنسيق التصدير المطلوب:',
            style: TextStyle(color: AppColors.secondaryTextColor),
          ),
          const SizedBox(height: 16),
          
          // خيارات تنسيق التصدير
          _buildFormatOptions(),
          
          const SizedBox(height: 24),
          
          const Text(
            'التكامل مع أدوات التطوير',
            style: TextStyle(
              color: AppColors.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اختر أداة التطوير المطلوبة:',
            style: TextStyle(color: AppColors.secondaryTextColor),
          ),
          const SizedBox(height: 16),
          
          // خيارات أدوات التطوير
          _buildToolOptions(),
          
          // حقل مفتاح API للأداة المخصصة
          if (_selectedExternalTool == ExternalTool.custom) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'مفتاح API (اختياري)',
                border: OutlineInputBorder(),
                hintText: 'أدخل مفتاح API للخدمة المخصصة',
              ),
            ),
          ],
          
          const SizedBox(height: 32),
          
          // أزرار الإجراءات
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exportData,
                  icon: const Icon(Icons.file_download),
                  label: const Text('تصدير البيانات'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _integrateWithTool,
                  icon: const Icon(Icons.build),
                  label: const Text('تكامل مع الأداة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mediumPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          OutlinedButton.icon(
            onPressed: _importData,
            icon: const Icon(Icons.file_upload),
            label: const Text('استيراد بيانات من ملف'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.deepPurple,
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(double.infinity, 0),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFormatOptions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ExportFormat.values.map((format) {
        return ChoiceChip(
          label: Text(_getFormatName(format)),
          selected: _selectedExportFormat == format,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedExportFormat = format;
              });
            }
          },
          backgroundColor: AppColors.cardColor,
          selectedColor: AppColors.lightPurple,
          labelStyle: TextStyle(
            color: _selectedExportFormat == format
                ? Colors.black87
                : AppColors.textColor,
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildToolOptions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ExternalTool.values.map((tool) {
        return ChoiceChip(
          label: Text(_getToolName(tool)),
          selected: _selectedExternalTool == tool,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedExternalTool = tool;
              });
            }
          },
          backgroundColor: AppColors.cardColor,
          selectedColor: AppColors.lightPurple,
          labelStyle: TextStyle(
            color: _selectedExternalTool == tool
                ? Colors.black87
                : AppColors.textColor,
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'تمت العملية بنجاح!',
            style: TextStyle(
              color: AppColors.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تم حفظ الملف في:',
            style: TextStyle(color: AppColors.secondaryTextColor),
          ),
          const SizedBox(height: 4),
          Text(
            _exportedFilePath!,
            style: const TextStyle(
              color: AppColors.mediumPurple,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _shareFile(_exportedFilePath!),
                icon: const Icon(Icons.share),
                label: const Text('مشاركة الملف'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _exportedFilePath = null;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('عملية جديدة'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.deepPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'حدث خطأ أثناء العملية',
            style: TextStyle(
              color: AppColors.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: TextStyle(color: AppColors.secondaryTextColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _errorMessage = null;
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepPurple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getFormatName(ExportFormat format) {
    switch (format) {
      case ExportFormat.json:
        return 'JSON';
      case ExportFormat.xml:
        return 'XML';
      case ExportFormat.csv:
        return 'CSV';
      case ExportFormat.base64:
        return 'Base64';
      case ExportFormat.hexDump:
        return 'Hex Dump';
      case ExportFormat.binary:
        return 'Binary';
    }
  }
  
  String _getToolName(ExternalTool tool) {
    switch (tool) {
      case ExternalTool.ghidra:
        return 'Ghidra';
      case ExternalTool.ida:
        return 'IDA Pro';
      case ExternalTool.wireshark:
        return 'Wireshark';
      case ExternalTool.ollydbg:
        return 'OllyDbg';
      case ExternalTool.radare2:
        return 'Radare2';
      case ExternalTool.binaryNinja:
        return 'Binary Ninja';
      case ExternalTool.custom:
        return 'أداة مخصصة';
    }
  }
  
  Future<void> _exportData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _exportedFilePath = null;
    });
    
    try {
      final fileData = await widget.file.readAsBytes();
      final fileName = widget.file.path.split('/').last;
      
      final filePath = await DeveloperToolsService.exportDataAsFormat(
        data: fileData,
        fileName: fileName,
        format: _selectedExportFormat,
      );
      
      setState(() {
        _exportedFilePath = filePath;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ أثناء تصدير البيانات: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _integrateWithTool() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _exportedFilePath = null;
    });
    
    try {
      final fileData = await widget.file.readAsBytes();
      
      final filePath = await DeveloperToolsService.integrateWithExternalTool(
        data: fileData,
        tool: _selectedExternalTool,
        apiKey: _apiKeyController.text,
      );
      
      setState(() {
        _exportedFilePath = filePath;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ أثناء التكامل مع الأداة: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _importData() async {
    try {
      // اختيار ملف للاستيراد
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.isEmpty) return;
      
      final filePath = result.files.first.path;
      if (filePath == null) return;
      
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _exportedFilePath = null;
      });
      
      final file = File(filePath);
      
      // اكتشاف تنسيق الملف
      final format = await DeveloperToolsService.detectFileFormat(file);
      if (format == null) {
        setState(() {
          _errorMessage = 'لم يتم التعرف على تنسيق الملف';
          _isLoading = false;
        });
        return;
      }
      
      // استيراد البيانات
      final importedData = await DeveloperToolsService.importDataFromFormat(
        file: file,
        format: format,
      );
      
      // حفظ البيانات المستوردة
      final fileService = Provider.of<EnhancedFileService>(context, listen: false);
      final newFile = await fileService.createNewFile('imported_data.bin');
      await newFile.writeAsBytes(importedData);
      
      setState(() {
        _exportedFilePath = newFile.path;
        _isLoading = false;
      });
      
      // إظهار رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم استيراد البيانات بنجاح إلى: ${newFile.path}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ أثناء استيراد البيانات: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _shareFile(String filePath) async {
    try {
      await Share.shareFiles([filePath]);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء مشاركة الملف: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
