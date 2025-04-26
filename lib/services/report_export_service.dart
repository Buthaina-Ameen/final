import 'package:flutter/material.dart';
import 'package:by_hex/constants/app_colors.dart';
import 'package:by_hex/services/enhanced_file_service.dart';
import 'package:by_hex/services/security_service.dart';
import 'package:by_hex/services/virus_total_service.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class ReportExportService {
  // تصدير تقرير عن الملف
  static Future<String> exportFileReport({
    required BuildContext context,
    required File file,
    required SecurityScanResult? securityScanResult,
    required VirusTotalService.VirusTotalResult? virusTotalResult,
  }) async {
    final fileService = Provider.of<EnhancedFileService>(context, listen: false);
    
    // إنشاء مستند PDF
    final pdf = pw.Document();
    
    // الحصول على معلومات الملف
    final fileSize = await file.length();
    final fileName = file.path.split('/').last;
    final fileExtension = fileName.contains('.') ? fileName.split('.').last : '';
    final fileModificationDate = await file.lastModified();
    
    // إنشاء نمط للعناوين
    final headerStyle = pw.TextStyle(
      fontSize: 18,
      fontWeight: pw.FontWeight.bold,
    );
    
    final subHeaderStyle = pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
    );
    
    final normalStyle = pw.TextStyle(
      fontSize: 12,
    );
    
    final smallStyle = pw.TextStyle(
      fontSize: 10,
      color: PdfColors.grey700,
    );
    
    // إضافة صفحة الغلاف
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'تقرير تحليل الملف',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  fileName,
                  style: pw.TextStyle(
                    fontSize: 18,
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Text(
                  'تم إنشاؤه بواسطة تطبيق By Hex',
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.purple700,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'تاريخ التقرير: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                  style: smallStyle,
                ),
              ],
            ),
          );
        },
      ),
    );
    
    // إضافة صفحة معلومات الملف
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('معلومات الملف', style: headerStyle),
              pw.Divider(),
              pw.SizedBox(height: 10),
              
              _buildInfoRow('اسم الملف:', fileName, normalStyle),
              _buildInfoRow('امتداد الملف:', fileExtension, normalStyle),
              _buildInfoRow('حجم الملف:', _formatFileSize(fileSize), normalStyle),
              _buildInfoRow(
                'تاريخ التعديل:',
                DateFormat('yyyy-MM-dd HH:mm').format(fileModificationDate),
                normalStyle,
              ),
              _buildInfoRow(
                'المسار:',
                file.path,
                normalStyle,
              ),
              
              pw.SizedBox(height: 20),
              
              // إضافة معلومات إضافية عن الملف إذا كانت متوفرة
              if (fileService.fileInfo != null) ...[
                pw.Text('معلومات إضافية', style: subHeaderStyle),
                pw.SizedBox(height: 10),
                _buildInfoRow(
                  'نوع الملف:',
                  fileService.fileInfo!.fileType ?? 'غير معروف',
                  normalStyle,
                ),
                if (fileService.fileInfo!.description != null)
                  _buildInfoRow(
                    'الوصف:',
                    fileService.fileInfo!.description!,
                    normalStyle,
                  ),
              ],
            ],
          );
        },
      ),
    );
    
    // إضافة صفحة نتائج الفحص الأمني إذا كانت متوفرة
    if (securityScanResult != null) {
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('نتائج الفحص الأمني', style: headerStyle),
                pw.Divider(),
                pw.SizedBox(height: 10),
                
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: securityScanResult.threatLevel == ThreatLevel.safe
                        ? PdfColors.green100
                        : securityScanResult.threatLevel == ThreatLevel.suspicious
                            ? PdfColors.orange100
                            : PdfColors.red100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text(
                        securityScanResult.threatLevel == ThreatLevel.safe
                            ? '✓'
                            : securityScanResult.threatLevel == ThreatLevel.suspicious
                                ? '!'
                                : '✗',
                        style: pw.TextStyle(
                          fontSize: 18,
                          color: securityScanResult.threatLevel == ThreatLevel.safe
                              ? PdfColors.green800
                              : securityScanResult.threatLevel == ThreatLevel.suspicious
                                  ? PdfColors.orange800
                                  : PdfColors.red800,
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Text(
                        securityScanResult.threatLevel == ThreatLevel.safe
                            ? 'الملف آمن'
                            : securityScanResult.threatLevel == ThreatLevel.suspicious
                                ? 'الملف مشبوه'
                                : 'الملف ضار',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: securityScanResult.threatLevel == ThreatLevel.safe
                              ? PdfColors.green800
                              : securityScanResult.threatLevel == ThreatLevel.suspicious
                                  ? PdfColors.orange800
                                  : PdfColors.red800,
                        ),
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 15),
                
                if (securityScanResult.threatDescription != null) ...[
                  pw.Text('وصف التهديد:', style: subHeaderStyle),
                  pw.SizedBox(height: 5),
                  pw.Text(securityScanResult.threatDescription!, style: normalStyle),
                  pw.SizedBox(height: 15),
                ],
                
                pw.Text('نتائج الفحص التفصيلية:', style: subHeaderStyle),
                pw.SizedBox(height: 10),
                
                _buildScanResultItem(
                  'فحص رؤوس الملف',
                  securityScanResult.headerAnalysis.isValid,
                  securityScanResult.headerAnalysis.details,
                  normalStyle,
                  smallStyle,
                ),
                
                _buildScanResultItem(
                  'تحليل الإنتروبيا',
                  securityScanResult.entropyAnalysis.isNormal,
                  securityScanResult.entropyAnalysis.details,
                  normalStyle,
                  smallStyle,
                ),
                
                _buildScanResultItem(
                  'فحص البصمات الرقمية',
                  !securityScanResult.signatureAnalysis.malwareDetected,
                  securityScanResult.signatureAnalysis.details,
                  normalStyle,
                  smallStyle,
                ),
                
                _buildScanResultItem(
                  'تحليل الأنماط السلوكية',
                  !securityScanResult.behavioralAnalysis.suspiciousBehavior,
                  securityScanResult.behavioralAnalysis.details,
                  normalStyle,
                  smallStyle,
                ),
                
                pw.SizedBox(height: 15),
                
                pw.Text('التوصية:', style: subHeaderStyle),
                pw.SizedBox(height: 5),
                pw.Text(securityScanResult.recommendation, style: normalStyle),
              ],
            );
          },
        ),
      );
    }
    
    // إضافة صفحة نتائج فحص VirusTotal إذا كانت متوفرة
    if (virusTotalResult != null) {
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('نتائج فحص VirusTotal', style: headerStyle),
                pw.Divider(),
                pw.SizedBox(height: 10),
                
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: virusTotalResult.isClean
                        ? PdfColors.green100
                        : PdfColors.red100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text(
                        virusTotalResult.isClean ? '✓' : '✗',
                        style: pw.TextStyle(
                          fontSize: 18,
                          color: virusTotalResult.isClean
                              ? PdfColors.green800
                              : PdfColors.red800,
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Text(
                        virusTotalResult.isClean
                            ? 'الملف آمن'
                            : 'تم اكتشاف تهديدات',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: virusTotalResult.isClean
                              ? PdfColors.green800
                              : PdfColors.red800,
                        ),
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 15),
                
                _buildInfoRow(
                  'نتيجة الفحص:',
                  '${virusTotalResult.detectedEngines} من أصل ${virusTotalResult.totalEngines} محرك فحص اكتشف تهديدات',
                  normalStyle,
                ),
                
                _buildInfoRow(
                  'تاريخ الفحص:',
                  DateFormat('yyyy-MM-dd HH:mm').format(virusTotalResult.scanDate),
                  normalStyle,
                ),
                
                pw.SizedBox(height: 15),
                
                pw.Text('رابط التقرير:', style: subHeaderStyle),
                pw.SizedBox(height: 5),
                pw.Text(virusTotalResult.permalink, style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.blue700,
                  decoration: pw.TextDecoration.underline,
                )),
                
                pw.SizedBox(height: 20),
                
                pw.Text('ملاحظة: للاطلاع على التقرير الكامل، يرجى زيارة الرابط أعلاه.', style: smallStyle),
              ],
            );
          },
        ),
      );
    }
    
    // إضافة صفحة التعديلات إذا كانت متوفرة
    if (fileService.modificationHistory.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('سجل التعديلات', style: headerStyle),
                pw.Divider(),
                pw.SizedBox(height: 10),
                
                pw.Text(
                  'عدد التعديلات: ${fileService.modificationHistory.length}',
                  style: normalStyle,
                ),
                
                pw.SizedBox(height: 15),
                
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  children: [
                    // رأس الجدول
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
                      children: [
                        _buildTableCell('نوع التعديل', subHeaderStyle, isHeader: true),
                        _buildTableCell('الموقع', subHeaderStyle, isHeader: true),
                        _buildTableCell('التاريخ', subHeaderStyle, isHeader: true),
                      ],
                    ),
                    
                    // صفوف البيانات
                    ...fileService.modificationHistory.map((modification) {
                      return pw.TableRow(
                        children: [
                          _buildTableCell(
                            _getModificationTypeText(modification.type),
                            normalStyle,
                          ),
                          _buildTableCell(
                            '0x${modification.offset.toRadixString(16).toUpperCase().padLeft(8, '0')}',
                            normalStyle,
                          ),
                          _buildTableCell(
                            DateFormat('yyyy-MM-dd HH:mm').format(modification.timestamp),
                            normalStyle,
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }
    
    // حفظ ملف PDF
    final output = await getTemporaryDirectory();
    final reportName = 'by_hex_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
    final file = File('${output.path}/$reportName');
    await file.writeAsBytes(await pdf.save());
    
    return file.path;
  }
  
  // مشاركة التقرير
  static Future<void> shareReport(String filePath) async {
    await Share.shareFiles([filePath], text: 'تقرير تحليل الملف من تطبيق By Hex');
  }
  
  // بناء صف معلومات
  static pw.Widget _buildInfoRow(String label, String value, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: style.copyWith(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
  
  // بناء عنصر نتيجة الفحص
  static pw.Widget _buildScanResultItem(
    String title,
    bool isGood,
    String details,
    pw.TextStyle normalStyle,
    pw.TextStyle smallStyle,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: isGood ? PdfColors.green300 : PdfColors.red300,
          width: 1,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text(
                isGood ? '✓' : '✗',
                style: pw.TextStyle(
                  color: isGood ? PdfColors.green800 : PdfColors.red800,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                title,
                style: normalStyle.copyWith(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            details,
            style: smallStyle,
          ),
        ],
      ),
    );
  }
  
  // بناء خلية جدول
  static pw.Widget _buildTableCell(String text, pw.TextStyle style, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: isHeader
            ? style.copyWith(fontWeight: pw.FontWeight.bold)
            : style,
        textAlign: pw.TextAlign.center,
      ),
    );
  }
  
  // تنسيق حجم الملف
  static String _formatFileSize(int bytes) {
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
  
  // الحصول على نص نوع التعديل
  static String _getModificationTypeText(ModificationType type) {
    switch (type) {
      case ModificationType.insert:
        return 'إضافة';
      case ModificationType.delete:
        return 'حذف';
      case ModificationType.replace:
        return 'تعديل';
      default:
        return 'غير معروف';
    }
  }
}

// شاشة تصدير التقارير
class ReportExportScreen extends StatefulWidget {
  final File file;
  final SecurityScanResult? securityScanResult;
  final VirusTotalService.VirusTotalResult? virusTotalResult;
  
  const ReportExportScreen({
    Key? key,
    required this.file,
    this.securityScanResult,
    this.virusTotalResult,
  }) : super(key: key);

  @override
  State<ReportExportScreen> createState() => _ReportExportScreenState();
}

class _ReportExportScreenState extends State<ReportExportScreen> {
  bool _isExporting = false;
  String? _exportedFilePath;
  String? _errorMessage;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تصدير التقرير'),
        backgroundColor: AppColors.appBarColor,
        foregroundColor: Colors.black87,
      ),
      body: Container(
        color: AppColors.backgroundColor,
        padding: const EdgeInsets.all(16),
        child: _isExporting
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.mediumPurple),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'جاري إنشاء التقرير...',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'تصدير تقرير عن الملف',
          style: TextStyle(
            color: AppColors.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'سيتم إنشاء تقرير PDF يتضمن معلومات عن الملف ونتائج الفحص الأمني.',
          style: TextStyle(color: AppColors.secondaryTextColor),
        ),
        const SizedBox(height: 24),
        
        const Text(
          'محتويات التقرير:',
          style: TextStyle(
            color: AppColors.textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        _buildOptionItem(
          'معلومات الملف',
          'اسم الملف، الحجم، تاريخ التعديل، المسار، إلخ.',
          true,
        ),
        
        _buildOptionItem(
          'نتائج الفحص الأمني',
          'نتائج الفحص الأمني الداخلي للملف.',
          widget.securityScanResult != null,
        ),
        
        _buildOptionItem(
          'نتائج فحص VirusTotal',
          'نتائج فحص الملف باستخدام VirusTotal.',
          widget.virusTotalResult != null,
        ),
        
        _buildOptionItem(
          'سجل التعديلات',
          'قائمة بالتعديلات التي تمت على الملف.',
          Provider.of<EnhancedFileService>(context).modificationHistory.isNotEmpty,
        ),
        
        const Spacer(),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _exportReport,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('إنشاء التقرير'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
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
            'تم إنشاء التقرير بنجاح!',
            style: TextStyle(
              color: AppColors.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تم حفظ التقرير في:',
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
                onPressed: () => _shareReport(_exportedFilePath!),
                icon: const Icon(Icons.share),
                label: const Text('مشاركة التقرير'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('العودة'),
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
            'حدث خطأ أثناء إنشاء التقرير',
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
            onPressed: _exportReport,
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
  
  Widget _buildOptionItem(String title, String description, bool isAvailable) {
    return Opacity(
      opacity: isAvailable ? 1.0 : 0.5,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isAvailable ? AppColors.mediumPurple : Colors.grey,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isAvailable ? Icons.check_circle : Icons.cancel,
              color: isAvailable ? Colors.green : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
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
      ),
    );
  }
  
  Future<void> _exportReport() async {
    setState(() {
      _isExporting = true;
      _errorMessage = null;
      _exportedFilePath = null;
    });
    
    try {
      final filePath = await ReportExportService.exportFileReport(
        context: context,
        file: widget.file,
        securityScanResult: widget.securityScanResult,
        virusTotalResult: widget.virusTotalResult,
      );
      
      setState(() {
        _exportedFilePath = filePath;
        _isExporting = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ أثناء إنشاء التقرير: $e';
        _isExporting = false;
      });
    }
  }
  
  Future<void> _shareReport(String filePath) async {
    try {
      await ReportExportService.shareReport(filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء مشاركة التقرير: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
