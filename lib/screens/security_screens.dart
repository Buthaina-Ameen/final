import 'package:flutter/material.dart';
import 'package:by_hex/constants/app_colors.dart';
import 'package:by_hex/services/security_service.dart';
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
  SecurityService.ScanResult? _scanResult;
  
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
    
    // إجراء فحص شامل للملف
    final result = await securityService.thoroughScanFile(widget.file);
    
    setState(() {
      _scanResult = result;
      _isScanning = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final securityService = Provider.of<SecurityService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('فحص أمني'),
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
    );
  }
  
  Widget _buildScanResultView(BuildContext context, SecurityService.ScanResult result) {
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
            'وقت الفحص: ${result.scanTime.toString().substring(0, 19)}',
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
            child: Row(
              children: [
                Icon(
                  result.isClean ? Icons.check_circle : Icons.warning,
                  color: result.isClean ? Colors.green : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  result.isClean
                      ? 'الملف آمن'
                      : 'تم اكتشاف ${result.threats.length} تهديد',
                  style: TextStyle(
                    color: result.isClean ? Colors.green : Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // قائمة التهديدات
          if (!result.isClean) ...[
            const Text(
              'التهديدات المكتشفة:',
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: result.threats.length,
                itemBuilder: (context, index) {
                  final threat = result.threats[index];
                  return _buildThreatItem(threat);
                },
              ),
            ),
            
            // أزرار الإجراءات
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.shield),
                    label: const Text('وضع في الحجر الصحي'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final securityService = Provider.of<SecurityService>(context, listen: false);
                      await securityService.quarantineFile(widget.file);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم وضع الملف في الحجر الصحي'),
                            backgroundColor: AppColors.deepPurple,
                          ),
                        );
                      }
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text('تجاهل'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.deepPurple,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ] else ...[
            const Spacer(),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('موافق'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            const Spacer(),
          ],
        ],
      ),
    );
  }
  
  Widget _buildThreatItem(SecurityService.SecurityThreat threat) {
    // تحديد لون التهديد بناءً على مستوى الخطورة
    Color severityColor;
    if (threat.severity >= 8) {
      severityColor = Colors.red;
    } else if (threat.severity >= 5) {
      severityColor = Colors.orange;
    } else {
      severityColor = Colors.yellow;
    }
    
    // تحديد أيقونة التهديد بناءً على نوعه
    IconData threatIcon;
    switch (threat.type) {
      case SecurityService.ThreatType.malware:
        threatIcon = Icons.bug_report;
        break;
      case SecurityService.ThreatType.invalidHeader:
        threatIcon = Icons.broken_image;
        break;
      case SecurityService.ThreatType.suspiciousEntropy:
        threatIcon = Icons.blur_on;
        break;
      case SecurityService.ThreatType.modifiedExtension:
        threatIcon = Icons.extension_off;
        break;
      case SecurityService.ThreatType.executableContent:
        threatIcon = Icons.code;
        break;
      default:
        threatIcon = Icons.warning;
        break;
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: AppColors.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  threatIcon,
                  color: severityColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getThreatTypeName(threat.type),
                    style: TextStyle(
                      color: severityColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'خطورة: ${threat.severity}/10',
                    style: TextStyle(
                      color: severityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              threat.description,
              style: const TextStyle(color: AppColors.textColor),
            ),
            const SizedBox(height: 4),
            Text(
              'الموقع: 0x${threat.offset.toRadixString(16).toUpperCase().padLeft(8, '0')} (${threat.length} بايت)',
              style: TextStyle(
                color: AppColors.secondaryTextColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getThreatTypeName(SecurityService.ThreatType type) {
    switch (type) {
      case SecurityService.ThreatType.malware:
        return 'برمجية ضارة';
      case SecurityService.ThreatType.invalidHeader:
        return 'رأس ملف غير صالح';
      case SecurityService.ThreatType.suspiciousEntropy:
        return 'إنتروبيا مشبوهة';
      case SecurityService.ThreatType.modifiedExtension:
        return 'امتداد ملف معدل';
      case SecurityService.ThreatType.executableContent:
        return 'محتوى تنفيذي مخفي';
      default:
        return 'تهديد غير معروف';
    }
  }
}

class SecuritySettingsScreen extends StatelessWidget {
  const SecuritySettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final securityService = Provider.of<SecurityService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات الأمان'),
        backgroundColor: AppColors.appBarColor,
        foregroundColor: Colors.black87,
      ),
      body: Container(
        color: AppColors.backgroundColor,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // مستوى الفحص التلقائي
            const Text(
              'مستوى الفحص التلقائي',
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: AppColors.cardColor,
              child: Column(
                children: [
                  RadioListTile<SecurityService.SecurityScanLevel>(
                    title: const Text(
                      'أساسي',
                      style: TextStyle(color: AppColors.textColor),
                    ),
                    subtitle: Text(
                      'فحص سريع لرؤوس الملفات والامتدادات',
                      style: TextStyle(color: AppColors.secondaryTextColor),
                    ),
                    value: SecurityService.SecurityScanLevel.basic,
                    groupValue: securityService.autoScanLevel,
                    activeColor: AppColors.mediumPurple,
                    onChanged: (value) {
                      if (value != null) {
                        securityService.autoScanLevel = value;
                      }
                    },
                  ),
                  RadioListTile<SecurityService.SecurityScanLevel>(
                    title: const Text(
                      'متوسط',
                      style: TextStyle(color: AppColors.textColor),
                    ),
                    subtitle: Text(
                      'فحص البصمات الرقمية والبنية الأساسية',
                      style: TextStyle(color: AppColors.secondaryTextColor),
                    ),
                    value: SecurityService.SecurityScanLevel.medium,
                    groupValue: securityService.autoScanLevel,
                    activeColor: AppColors.mediumPurple,
                    onChanged: (value) {
                      if (value != null) {
                        securityService.autoScanLevel = value;
                      }
                    },
                  ),
                  RadioListTile<SecurityService.SecurityScanLevel>(
                    title: const Text(
                      'شامل',
                      style: TextStyle(color: AppColors.textColor),
                    ),
                    subtitle: Text(
                      'فحص كامل يشمل تحليل الإنتروبيا والمحتوى المخفي',
                      style: TextStyle(color: AppColors.secondaryTextColor),
                    ),
                    value: SecurityService.SecurityScanLevel.thorough,
                    groupValue: securityService.autoScanLevel,
                    activeColor: AppColors.mediumPurple,
                    onChanged: (value) {
                      if (value != null) {
                        securityService.autoScanLevel = value;
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // خيارات الفحص
            const Text(
              'خيارات الفحص',
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: AppColors.cardColor,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      'فحص عند فتح الملف',
                      style: TextStyle(color: AppColors.textColor),
                    ),
                    subtitle: Text(
                      'إجراء فحص تلقائي عند فتح أي ملف',
                      style: TextStyle(color: AppColors.secondaryTextColor),
                    ),
                    value: securityService.scanOnFileOpen,
                    activeColor: AppColors.mediumPurple,
                    onChanged: (value) {
                      securityService.scanOnFileOpen = value;
                    },
                  ),
                  SwitchListTile(
                    title: const Text(
                      'تنبيه عند اكتشاف تهديدات',
                      style: TextStyle(color: AppColors.textColor),
                    ),
                    subtitle: Text(
                      'عرض تنبيه فوري عند اكتشاف أي تهديد',
                      style: TextStyle(color: AppColors.secondaryTextColor),
                    ),
                    value: securityService.notifyOnThreats,
                    activeColor: AppColors.mediumPurple,
                    onChanged: (value) {
                      securityService.notifyOnThreats = value;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // الحجر الصحي
            const Text(
              'الحجر الصحي',
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: AppColors.cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الملفات في الحجر الصحي: ${securityService.quarantinedFiles.length}',
                      style: const TextStyle(color: AppColors.textColor),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.folder),
                      label: const Text('إدارة الحجر الصحي'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QuarantineScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuarantineScreen extends StatelessWidget {
  const QuarantineScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final securityService = Provider.of<SecurityService>(context);
    final quarantinedFiles = securityService.quarantinedFiles;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('الحجر الصحي'),
        backgroundColor: AppColors.appBarColor,
        foregroundColor: Colors.black87,
      ),
      body: Container(
        color: AppColors.backgroundColor,
        child: quarantinedFiles.isEmpty
            ? const Center(
                child: Text(
                  'لا توجد ملفات في الحجر الصحي',
                  style: TextStyle(color: AppColors.textColor),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: quarantinedFiles.length,
                itemBuilder: (context, index) {
                  final file = quarantinedFiles[index];
                  final fileName = file.path.split('/').last;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: AppColors.cardColor,
                    child: ListTile(
                      leading: const Icon(
                        Icons.warning,
                        color: Colors.red,
                      ),
                      title: Text(
                        fileName,
                        style: const TextStyle(color: AppColors.textColor),
                      ),
                      subtitle: Text(
                        'تم وضعه في الحجر الصحي',
                        style: TextStyle(color: AppColors.secondaryTextColor),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.restore, color: AppColors.mediumPurple),
                            tooltip: 'استعادة',
                            onPressed: () {
                              _showRestoreDialog(context, securityService, file);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'حذف',
                            onPressed: () {
                              _showDeleteDialog(context, securityService, file);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
  
  void _showRestoreDialog(BuildContext context, SecurityService securityService, File file) {
    final fileName = file.path.split('/').last;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استعادة الملف'),
        content: Text('هل أنت متأكد من استعادة الملف "$fileName"؟ قد يحتوي على محتوى ضار.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // استعادة الملف إلى المجلد الأصلي
              final destinationPath = '/home/ubuntu/projects/by_hex/restored/$fileName';
              await securityService.restoreFromQuarantine(file, destinationPath);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم استعادة الملف "$fileName"'),
                    backgroundColor: AppColors.deepPurple,
                  ),
                );
              }
            },
            child: const Text('استعادة'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteDialog(BuildContext context, SecurityService securityService, File file) {
    final fileName = file.path.split('/').last;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الملف'),
        content: Text('هل أنت متأكد من حذف الملف "$fileName" نهائيًا؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // حذف الملف من الحجر الصحي
              await securityService.deleteFromQuarantine(file);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم حذف الملف "$fileName"'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
