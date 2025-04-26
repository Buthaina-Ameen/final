import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'dart:io';

class VirusTotalService extends ChangeNotifier {
  // مفتاح API لـ VirusTotal
  // استخدام مفتاح API تجريبي للاختبار
  // في الإصدار النهائي، يجب أن يكون هناك إعداد يسمح للمستخدم بإدخال مفتاح API الخاص به
  String _apiKey = 'e90ad3de9c5d5d6d2c2bb5c9d7bc81b159c9e6f2f9df6a4b9c1d2e3f4g5h6i7j';
  
  // تعيين مفتاح API جديد
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
    notifyListeners();
  }
  
  // الحصول على مفتاح API الحالي
  String get apiKey => _apiKey;
  final String _baseUrl = 'https://www.virustotal.com/api/v3';
  
  // نتيجة فحص VirusTotal
  class VirusTotalResult {
    final bool isClean;
    final int totalEngines;
    final int detectedEngines;
    final Map<String, dynamic> detections;
    final String permalink;
    final DateTime scanDate;
    
    VirusTotalResult({
      required this.isClean,
      required this.totalEngines,
      required this.detectedEngines,
      required this.detections,
      required this.permalink,
      required this.scanDate,
    });
  }
  
  // حالة الفحص
  bool _isScanning = false;
  bool get isScanning => _isScanning;
  
  // سجل نتائج الفحص
  final Map<String, VirusTotalResult> _scanResults = {};
  Map<String, VirusTotalResult> get scanResults => Map.unmodifiable(_scanResults);
  
  // حساب بصمة SHA-256 للملف
  Future<String> _calculateFileHash(File file) async {
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // فحص ملف باستخدام VirusTotal
  Future<VirusTotalResult?> scanFile(File file) async {
    try {
      _isScanning = true;
      notifyListeners();
      
      // حساب بصمة الملف
      final fileHash = await _calculateFileHash(file);
      
      // التحقق من وجود نتيجة سابقة
      if (_scanResults.containsKey(fileHash)) {
        _isScanning = false;
        notifyListeners();
        return _scanResults[fileHash];
      }
      
      // البحث عن تقرير موجود
      final reportResult = await _getFileReport(fileHash);
      if (reportResult != null) {
        _scanResults[fileHash] = reportResult;
        _isScanning = false;
        notifyListeners();
        return reportResult;
      }
      
      // إرسال الملف للفحص إذا لم يكن له تقرير موجود
      final scanId = await _submitFileForScanning(file);
      if (scanId == null) {
        _isScanning = false;
        notifyListeners();
        return null;
      }
      
      // انتظار نتيجة الفحص
      VirusTotalResult? result;
      for (int i = 0; i < 10; i++) {
        // انتظار 15 ثانية بين كل محاولة
        await Future.delayed(const Duration(seconds: 15));
        
        // الحصول على نتيجة الفحص
        result = await _getAnalysisResult(scanId);
        if (result != null) {
          break;
        }
      }
      
      if (result != null) {
        _scanResults[fileHash] = result;
      }
      
      _isScanning = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isScanning = false;
      notifyListeners();
      print('خطأ في فحص الملف: $e');
      return null;
    }
  }
  
  // الحصول على تقرير ملف موجود
  Future<VirusTotalResult?> _getFileReport(String fileHash) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/files/$fileHash'),
        headers: {
          'x-apikey': _apiKey,
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseVirusTotalResponse(data);
      } else if (response.statusCode == 404) {
        // الملف غير موجود في قاعدة بيانات VirusTotal
        return null;
      } else {
        print('خطأ في الحصول على تقرير الملف: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('خطأ في الحصول على تقرير الملف: $e');
      return null;
    }
  }
  
  // إرسال ملف للفحص
  Future<String?> _submitFileForScanning(File file) async {
    try {
      // الحصول على URL لرفع الملف
      final uploadUrlResponse = await http.get(
        Uri.parse('$_baseUrl/files/upload_url'),
        headers: {
          'x-apikey': _apiKey,
        },
      );
      
      if (uploadUrlResponse.statusCode != 200) {
        print('خطأ في الحصول على URL لرفع الملف: ${uploadUrlResponse.statusCode}');
        return null;
      }
      
      final uploadUrl = json.decode(uploadUrlResponse.body)['data'];
      
      // إنشاء طلب متعدد الأجزاء
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.headers['x-apikey'] = _apiKey;
      
      // إضافة الملف إلى الطلب
      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );
      
      // إرسال الطلب
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['id'];
      } else {
        print('خطأ في رفع الملف: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('خطأ في رفع الملف: $e');
      return null;
    }
  }
  
  // الحصول على نتيجة التحليل
  Future<VirusTotalResult?> _getAnalysisResult(String analysisId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/analyses/$analysisId'),
        headers: {
          'x-apikey': _apiKey,
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // التحقق من اكتمال التحليل
        final status = data['data']['attributes']['status'];
        if (status == 'completed') {
          return _parseVirusTotalResponse(data);
        } else {
          // التحليل لا يزال قيد التنفيذ
          return null;
        }
      } else {
        print('خطأ في الحصول على نتيجة التحليل: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('خطأ في الحصول على نتيجة التحليل: $e');
      return null;
    }
  }
  
  // تحليل استجابة VirusTotal
  VirusTotalResult _parseVirusTotalResponse(Map<String, dynamic> data) {
    final attributes = data['data']['attributes'];
    final stats = attributes['stats'];
    final results = attributes['results'];
    
    final totalEngines = stats['total'] as int;
    final detectedEngines = stats['malicious'] as int;
    final scanDate = DateTime.parse(attributes['date']);
    final permalink = attributes['permalink'] as String;
    
    return VirusTotalResult(
      isClean: detectedEngines == 0,
      totalEngines: totalEngines,
      detectedEngines: detectedEngines,
      detections: results,
      permalink: permalink,
      scanDate: scanDate,
    );
  }
}
