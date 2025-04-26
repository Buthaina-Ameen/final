import 'package:flutter/material.dart';
import 'package:by_hex/services/security_service.dart';
import 'package:by_hex/services/virus_total_service.dart';
import 'package:by_hex/screens/virus_total_scan_screen.dart';
import 'package:by_hex/constants/app_colors.dart';
import 'package:provider/provider.dart';
import 'dart:io';

class SecurityScanScreen extends StatefulWidget {
  final File file;
  
  const SecurityScanScreen({
    Key? key,
    required this.file,
  }) : super(key: key);

  @override
  State<SecurityScanScreen> createState() => _SecurityScanScreenState();
}

class _SecurityScanScreenState extends State<SecurityScanScreen> {
  bool _isScanning = false;
  SecurityScanResult? _scanResult;
  
  @override
  void initState() {
    super.initState();
    _startScan();
  }
  
  Future<void> _startScan() async {
    final securityService = Provider.of<SecurityService>(context, listen: false);
    
    setState(() {
      _isScanning = true;
    });
    
    // إجراء الفحص الأمني الداخلي
    final result = await securityService.scanFile(widget.file);
    
    setState(() {
      _scanResult = result;
      _isScanning = false;
    });
  }
  
  void _navigateToVirusTotalScan() {
    // إظهار مؤشر التحميل قبل الانتقال إلى شاشة فحص VirusTotal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.mediumPurple),
        ),
      ),
    );
    
    // التحقق من وجود مفتاح API صالح
    final virusTotalService = Provider.of<VirusTotalService>(context, listen: false);
    if (virusTotalService.apiKey.isEmpty || virusTotalService.apiKey == 'YOUR_VIRUSTOTAL_API_KEY') {
      // إغلاق مؤشر التحميل
      Navigator.pop(context);
      
      // عرض رسالة خطأ
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('مفتاح API غير صالح'),
          content: const Text('يرجى إدخال مفتاح API صالح لـ VirusTotal للاستمرار.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showApiKeyDialog();
              },
              child: const Text('إدخال مفتاح API'),
            ),
          ],
        ),
      );
      return;
    }
    
    // إغلاق مؤشر التحميل والانتقال إلى شاشة فحص VirusTotal
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VirusTotalScanScreen(file: widget.file),
      ),
    );
  }
  
  void _showApiKeyDialog() {
    final virusTotalService = Provider.of<VirusTotalService>(context, listen: false);
    final TextEditingController apiKeyController = TextEditingController(text: virusTotalService.apiKey);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إدخال مفتاح API لـ VirusTotal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'يمكنك الحصول على مفتاح API من موقع VirusTotal بعد إنشاء حساب.',
              style: TextStyle(fontSize: 12, color: AppColors.secondaryTextColor),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: apiKeyController,
              decoration: const InputDecoration(
                labelText: 'مفتاح API',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final apiKey = apiKeyController.text.trim();
              if (apiKey.isNotEmpty) {
                virusTotalService.setApiKey(apiKey);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حفظ مفتاح API بنجاح')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepPurple,
            ),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فحص أمان الملف'),
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
                      'جاري فحص الملف...',
                      style: TextStyle(color: AppColors.textColor),
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
      bottomNavigationBar: _isScanning
          ? null
          : BottomAppBar(
              color: AppColors.deepPurple,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _startScan,
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة الفحص'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lightPurple,
                        foregroundColor: Colors.black87,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _navigateToVirusTotalScan,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('فحص عبر VirusTotal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lightPurple,
                        foregroundColor: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildScanResultView(BuildContext context, SecurityScanResult result) {
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
          
          // حجم الملف
          FutureBuilder<int>(
            future: widget.file.length(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final fileSize = snapshot.data!;
                return Text(
                  'الحجم: ${_formatFileSize(fileSize)}',
                  style: TextStyle(
                    color: AppColors.secondaryTextColor,
                    fontSize: 14,
                  ),
                );
              } else {
                return const Text(
                  'الحجم: جاري الحساب...',
                  style: TextStyle(
                    color: AppColors.secondaryTextColor,
                    fontSize: 14,
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          
          // نتيجة الفحص
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: result.threatLevel == ThreatLevel.safe
                  ? Colors.green.withOpacity(0.1)
                  : result.threatLevel == ThreatLevel.suspicious
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: result.threatLevel == ThreatLevel.safe
                    ? Colors.green
                    : result.threatLevel == ThreatLevel.suspicious
                        ? Colors.orange
                        : Colors.red,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      result.threatLevel == ThreatLevel.safe
                          ? Icons.check_circle
                          : result.threatLevel == ThreatLevel.suspicious
                              ? Icons.help_outline
                              : Icons.warning,
                      color: result.threatLevel == ThreatLevel.safe
                          ? Colors.green
                          : result.threatLevel == ThreatLevel.suspicious
                              ? Colors.orange
                              : Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        result.threatLevel == ThreatLevel.safe
                            ? 'الملف آمن'
                            : result.threatLevel == ThreatLevel.suspicious
                                ? 'الملف مشبوه'
                                : 'الملف ضار',
                        style: TextStyle(
                          color: result.threatLevel == ThreatLevel.safe
                              ? Colors.green
                              : result.threatLevel == ThreatLevel.suspicious
                                  ? Colors.orange
                                  : Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (result.threatDescription != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    result.threatDescription!,
                    style: const TextStyle(color: AppColors.textColor),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // نتائج الفحص التفصيلية
          const Text(
            'نتائج الفحص التفصيلية:',
            style: TextStyle(
              color: AppColors.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                _buildScanResultItem(
                  'فحص رؤوس الملف',
                  result.headerAnalysis.isValid,
                  result.headerAnalysis.details,
                ),
                _buildScanResultItem(
                  'تحليل الإنتروبيا',
                  result.entropyAnalysis.isNormal,
                  result.entropyAnalysis.details,
                ),
                _buildScanResultItem(
                  'فحص البصمات الرقمية',
                  !result.signatureAnalysis.malwareDetected,
                  result.signatureAnalysis.details,
                ),
                _buildScanResultItem(
                  'تحليل الأنماط السلوكية',
                  !result.behavioralAnalysis.suspiciousBehavior,
                  result.behavioralAnalysis.details,
                ),
              ],
            ),
          ),
          
          // توصية للمستخدم
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.mediumPurple,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.mediumPurple,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'توصية',
                        style: TextStyle(
                          color: AppColors.mediumPurple,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  result.recommendation,
                  style: const TextStyle(color: AppColors.textColor),
                ),
                const SizedBox(height: 12),
                const Text(
                  'للحصول على تحليل أكثر دقة، يمكنك فحص الملف عبر VirusTotal باستخدام الزر أدناه.',
                  style: TextStyle(
                    color: AppColors.secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildScanResultItem(String title, bool isGood, String details) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: AppColors.cardColor,
      child: ExpansionTile(
        leading: Icon(
          isGood ? Icons.check_circle : Icons.warning,
          color: isGood ? Colors.green : Colors.red,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          isGood ? 'آمن' : 'مشكلة محتملة',
          style: TextStyle(
            color: isGood ? Colors.green : Colors.red,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              details,
              style: TextStyle(color: AppColors.secondaryTextColor),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes بايت';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} كيلوبايت';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} ميجابايت';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} جيجابايت';
    }
  }
}
