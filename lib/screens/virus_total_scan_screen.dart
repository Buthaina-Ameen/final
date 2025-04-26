import 'package:flutter/material.dart';
import 'package:by_hex/constants/app_colors.dart';
import 'package:by_hex/services/virus_total_service.dart';
import 'package:provider/provider.dart';
import 'dart:io';

class VirusTotalScanScreen extends StatefulWidget {
  final File file;
  
  const VirusTotalScanScreen({
    Key? key,
    required this.file,
  }) : super(key: key);

  @override
  State<VirusTotalScanScreen> createState() => _VirusTotalScanScreenState();
}

class _VirusTotalScanScreenState extends State<VirusTotalScanScreen> {
  bool _isScanning = false;
  VirusTotalService.VirusTotalResult? _scanResult;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    // التحقق من وجود مفتاح API صالح قبل بدء الفحص
    final virusTotalService = Provider.of<VirusTotalService>(context, listen: false);
    if (virusTotalService.apiKey.isEmpty || 
        virusTotalService.apiKey == 'YOUR_VIRUSTOTAL_API_KEY' ||
        virusTotalService.apiKey.startsWith('e90ad3de')) {
      // عرض رسالة تحذير للمستخدم
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تنبيه: تم استخدام مفتاح API تجريبي. للحصول على نتائج دقيقة، يرجى استخدام مفتاح API خاص بك.'),
            duration: Duration(seconds: 5),
          ),
        );
      });
    }
    _startScan();
  }
  
  Future<void> _startScan() async {
    final virusTotalService = Provider.of<VirusTotalService>(context, listen: false);
    
    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });
    
    try {
      // إجراء فحص الملف باستخدام VirusTotal
      final result = await virusTotalService.scanFile(widget.file);
      
      setState(() {
        _scanResult = result;
        _isScanning = false;
        if (result == null) {
          _errorMessage = 'فشل الفحص. يرجى المحاولة مرة أخرى لاحقًا.';
        }
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _errorMessage = 'حدث خطأ أثناء الفحص: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فحص VirusTotal'),
        backgroundColor: AppColors.appBarColor,
        foregroundColor: Colors.black87,
      ),
      body: Container(
        color: AppColors.backgroundColor,
        child: _isScanning
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.mediumPurple),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'جاري فحص الملف باستخدام VirusTotal...',
                      style: TextStyle(color: AppColors.textColor),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'قد يستغرق هذا بضع دقائق',
                      style: TextStyle(color: AppColors.secondaryTextColor, fontSize: 12),
                    ),
                  ],
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.textColor),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _startScan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                : _scanResult == null
                    ? const Center(
                        child: Text(
                          'لم يتم إجراء الفحص',
                          style: TextStyle(color: AppColors.textColor),
                        ),
                      )
                    : _buildScanResultView(context, _scanResult!),
      ),
    );
  }
  
  Widget _buildScanResultView(BuildContext context, VirusTotalService.VirusTotalResult result) {
    // حفظ نتيجة الفحص في خدمة الملفات
    final fileService = Provider.of<EnhancedFileService>(context, listen: false);
    if (fileService.currentFile != null && fileService.currentFile!.path == widget.file.path) {
      fileService._isInfected = !result.isClean;
      fileService._securityMessage = result.isClean 
          ? "الملف آمن وفقاً لفحص VirusTotal" 
          : "تم اكتشاف تهديد: ${result.detectedEngines} من أصل ${result.totalEngines} محرك فحص اكتشف تهديدات";
      fileService.notifyListeners();
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان الملف
          Text(
            'الملف: ${widget.file.path.split('/').last}',
            style: const TextStyle(
              color: AppColors.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // وقت الفحص
          Text(
            'وقت الفحص: ${result.scanDate.toString().substring(0, 19)}',
            style: TextStyle(
              color: AppColors.secondaryTextColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          
          // نتيجة الفحص
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: result.isClean ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: result.isClean ? Colors.green : Colors.red,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      result.isClean ? Icons.check_circle : Icons.warning,
                      color: result.isClean ? Colors.green : Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        result.isClean
                            ? 'الملف آمن'
                            : 'تم اكتشاف تهديدات',
                        style: TextStyle(
                          color: result.isClean ? Colors.green : Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'نتيجة الفحص: ${result.detectedEngines} من أصل ${result.totalEngines} محرك فحص اكتشف تهديدات',
                  style: const TextStyle(color: AppColors.textColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // رابط التقرير
          InkWell(
            onTap: () {
              // فتح الرابط في المتصفح
              // يمكن استخدام مكتبة url_launcher هنا
            },
            child: Row(
              children: [
                const Icon(
                  Icons.link,
                  color: AppColors.mediumPurple,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'عرض التقرير الكامل على VirusTotal',
                  style: TextStyle(
                    color: AppColors.mediumPurple,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // نتائج محركات الفحص
          const Text(
            'نتائج محركات الفحص:',
            style: TextStyle(
              color: AppColors.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _buildEngineResultsList(result),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEngineResultsList(VirusTotalService.VirusTotalResult result) {
    // تحويل نتائج المحركات إلى قائمة
    final engineResults = <Map<String, dynamic>>[];
    
    result.detections.forEach((engine, data) {
      engineResults.add({
        'engine': engine,
        'category': data['category'],
        'result': data['result'],
        'method': data['method'],
        'isDetected': data['category'] == 'malicious' || data['category'] == 'suspicious',
      });
    });
    
    // ترتيب النتائج: المحركات التي اكتشفت تهديدات أولاً
    engineResults.sort((a, b) {
      if (a['isDetected'] && !b['isDetected']) return -1;
      if (!a['isDetected'] && b['isDetected']) return 1;
      return (a['engine'] as String).compareTo(b['engine'] as String);
    });
    
    return ListView.builder(
      itemCount: engineResults.length,
      itemBuilder: (context, index) {
        final engineResult = engineResults[index];
        final isDetected = engineResult['isDetected'] as bool;
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: AppColors.cardColor,
          child: ListTile(
            leading: Icon(
              isDetected ? Icons.warning : Icons.check_circle,
              color: isDetected ? Colors.red : Colors.green,
            ),
            title: Text(
              engineResult['engine'] as String,
              style: const TextStyle(
                color: AppColors.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (engineResult['result'] != null)
                  Text(
                    'النتيجة: ${engineResult['result']}',
                    style: TextStyle(color: AppColors.secondaryTextColor),
                  ),
                Text(
                  'التصنيف: ${_getCategoryTranslation(engineResult['category'] as String)}',
                  style: TextStyle(
                    color: _getCategoryColor(engineResult['category'] as String),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  String _getCategoryTranslation(String category) {
    switch (category) {
      case 'malicious':
        return 'ضار';
      case 'suspicious':
        return 'مشبوه';
      case 'undetected':
        return 'غير مكتشف';
      case 'harmless':
        return 'غير ضار';
      default:
        return category;
    }
  }
  
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'malicious':
        return Colors.red;
      case 'suspicious':
        return Colors.orange;
      case 'undetected':
        return Colors.grey;
      case 'harmless':
        return Colors.green;
      default:
        return AppColors.secondaryTextColor;
    }
  }
}
