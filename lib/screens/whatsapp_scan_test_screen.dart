import 'package:flutter/material.dart';
import 'package:by_hex/constants/app_colors.dart';
import 'package:by_hex/services/whatsapp_service.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class WhatsAppScanTestScreen extends StatefulWidget {
  const WhatsAppScanTestScreen({super.key});

  @override
  State<WhatsAppScanTestScreen> createState() => _WhatsAppScanTestScreenState();
}

class _WhatsAppScanTestScreenState extends State<WhatsAppScanTestScreen> {
  String _testStatus = 'جاهز للاختبار';
  bool _isRunningTest = false;
  final List<String> _testResults = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار فحص واتساب'),
        backgroundColor: AppColors.darkGrayLight,
      ),
      body: Consumer<WhatsAppService>(
        builder: (context, whatsappService, _) {
          return Container(
            color: AppColors.backgroundColor,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: AppColors.darkGray,
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'حالة الخدمة',
                          style: TextStyle(
                            color: AppColors.lightPurple,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildStatusItem(
                          'تهيئة الخدمة',
                          whatsappService.isInitialized ? 'تم التهيئة' : 'لم يتم التهيئة',
                          whatsappService.isInitialized ? Colors.green : Colors.red,
                        ),
                        _buildStatusItem(
                          'الفحص التلقائي',
                          whatsappService.autoScanEnabled ? 'مفعل' : 'معطل',
                          whatsappService.autoScanEnabled ? Colors.green : Colors.grey,
                        ),
                        _buildStatusItem(
                          'الإشعارات',
                          whatsappService.notifyOnScan ? 'مفعلة' : 'معطلة',
                          whatsappService.notifyOnScan ? Colors.green : Colors.grey,
                        ),
                        _buildStatusItem(
                          'استخدام VirusTotal',
                          whatsappService.useVirusTotal ? 'مفعل' : 'معطل',
                          whatsappService.useVirusTotal ? Colors.green : Colors.grey,
                        ),
                        _buildStatusItem(
                          'مسار واتساب',
                          whatsappService.whatsappMediaPath,
                          Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  color: AppColors.darkGray,
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'اختبار الفحص',
                          style: TextStyle(
                            color: AppColors.lightPurple,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'الحالة: $_testStatus',
                          style: TextStyle(
                            color: _isRunningTest ? Colors.yellow : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.file_open),
                              label: const Text('اختبار ملف نظيف'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.mediumPurple,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              onPressed: _isRunningTest
                                  ? null
                                  : () => _testCleanFile(whatsappService),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.warning),
                              label: const Text('اختبار ملف ضار'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              onPressed: _isRunningTest
                                  ? null
                                  : () => _testMaliciousFile(whatsappService),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'نتائج الاختبار:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Card(
                    color: AppColors.darkGray,
                    elevation: 3,
                    child: ListView.builder(
                      itemCount: _testResults.length,
                      itemBuilder: (context, index) {
                        final result = _testResults[index];
                        return ListTile(
                          leading: Icon(
                            result.contains('نجاح') ? Icons.check_circle : Icons.info,
                            color: result.contains('نجاح') ? Colors.green : Colors.blue,
                          ),
                          title: Text(
                            result,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            value,
            style: TextStyle(color: valueColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _testCleanFile(WhatsAppService whatsappService) async {
    if (!whatsappService.isInitialized) {
      _addTestResult('فشل: يجب تهيئة الخدمة أولاً');
      return;
    }

    setState(() {
      _isRunningTest = true;
      _testStatus = 'جاري اختبار ملف نظيف...';
    });

    try {
      // إنشاء ملف نصي بسيط للاختبار
      final tempDir = Directory.systemTemp;
      final testFile = File('${tempDir.path}/clean_test_file.txt');
      await testFile.writeAsString('هذا ملف نظيف للاختبار');

      _addTestResult('تم إنشاء ملف اختبار نظيف: ${testFile.path}');

      // فحص الملف
      final result = await whatsappService.scanFileManually(testFile);

      if (result != null) {
        _addTestResult('نجاح: تم فحص الملف النظيف');
        _addTestResult('النتيجة: ${result.isClean ? 'نظيف' : 'غير نظيف'}');
      } else {
        _addTestResult('فشل: لم يتم فحص الملف بشكل صحيح');
      }
    } catch (e) {
      _addTestResult('خطأ: $e');
    } finally {
      setState(() {
        _isRunningTest = false;
        _testStatus = 'اكتمل اختبار الملف النظيف';
      });
    }
  }

  Future<void> _testMaliciousFile(WhatsAppService whatsappService) async {
    if (!whatsappService.isInitialized) {
      _addTestResult('فشل: يجب تهيئة الخدمة أولاً');
      return;
    }

    setState(() {
      _isRunningTest = true;
      _testStatus = 'جاري اختبار ملف ضار...';
    });

    try {
      // إنشاء ملف يحتوي على توقيع ضار وهمي للاختبار
      final tempDir = Directory.systemTemp;
      final testFile = File('${tempDir.path}/malicious_test_file.exe');
      
      // إنشاء محتوى يحتوي على توقيع PE/MZ header
      final List<int> maliciousContent = [
        0x4D, 0x5A, 0x90, 0x00, 0x03, 0x00, 0x00, 0x00, // MZ header
        // باقي المحتوى
        0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
      ];
      
      await testFile.writeAsBytes(maliciousContent);

      _addTestResult('تم إنشاء ملف اختبار ضار: ${testFile.path}');

      // فحص الملف
      final result = await whatsappService.scanFileManually(testFile);

      if (result != null) {
        _addTestResult('نجاح: تم فحص الملف الضار');
        _addTestResult('النتيجة: ${result.isClean ? 'نظيف' : 'غير نظيف'}');
        
        if (!result.isClean && result.threats != null) {
          for (final threat in result.threats!) {
            _addTestResult('تهديد: ${threat.description} (خطورة: ${threat.severity}/10)');
          }
        }
      } else {
        _addTestResult('فشل: لم يتم فحص الملف بشكل صحيح');
      }
    } catch (e) {
      _addTestResult('خطأ: $e');
    } finally {
      setState(() {
        _isRunningTest = false;
        _testStatus = 'اكتمل اختبار الملف الضار';
      });
    }
  }

  void _addTestResult(String result) {
    setState(() {
      _testResults.add('${DateTime.now().toString().substring(11, 19)} - $result');
    });
  }
}
