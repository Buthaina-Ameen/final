import 'package:flutter/material.dart';
import 'package:by_hex/constants/app_colors.dart';
import 'package:by_hex/services/whatsapp_service.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

class WhatsAppScanHistoryScreen extends StatelessWidget {
  const WhatsAppScanHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل فحص ملفات واتساب'),
        backgroundColor: AppColors.darkGrayLight,
      ),
      body: Consumer<WhatsAppService>(
        builder: (context, whatsappService, _) {
          final scannedFiles = whatsappService.scannedFiles;
          
          if (scannedFiles.isEmpty) {
            return _buildEmptyState();
          }
          
          return Container(
            color: AppColors.backgroundColor,
            child: ListView.builder(
              itemCount: scannedFiles.length,
              itemBuilder: (context, index) {
                final file = scannedFiles[scannedFiles.length - 1 - index]; // عرض الأحدث أولاً
                return _buildFileCard(context, file);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Provider.of<WhatsAppService>(context, listen: false).clearScanHistory();
        },
        backgroundColor: AppColors.mediumPurple,
        child: const Icon(Icons.delete_sweep),
        tooltip: 'مسح السجل',
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Container(
      color: AppColors.backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: AppColors.lightPurple.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد ملفات تم فحصها',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ستظهر هنا الملفات التي تم فحصها من واتساب',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFileCard(BuildContext context, WhatsAppService.ScannedFile file) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final formattedDate = dateFormat.format(file.scanTime);
    
    // تحديد أيقونة الملف بناءً على نوعه
    IconData fileIcon;
    if (file.type.startsWith('image/')) {
      fileIcon = Icons.image;
    } else if (file.type.startsWith('application/pdf')) {
      fileIcon = Icons.picture_as_pdf;
    } else if (file.type.startsWith('application/')) {
      fileIcon = Icons.insert_drive_file;
    } else if (file.type.startsWith('audio/')) {
      fileIcon = Icons.audio_file;
    } else if (file.type.startsWith('video/')) {
      fileIcon = Icons.video_file;
    } else {
      fileIcon = Icons.insert_drive_file;
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.darkGray,
      elevation: 3,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: file.isClean ? Colors.green : Colors.red,
          child: Icon(
            file.isClean ? Icons.check : Icons.warning,
            color: Colors.white,
          ),
        ),
        title: Text(
          file.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${file.source} • $formattedDate',
          style: const TextStyle(
            color: Colors.white70,
          ),
        ),
        trailing: Icon(
          fileIcon,
          color: AppColors.lightPurple,
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        childrenPadding: const EdgeInsets.all(16),
        children: [
          Text(
            'المسار: ${file.path}',
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            'النوع: ${file.type}',
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            'الحالة: ${file.isClean ? 'آمن' : 'تم اكتشاف تهديد'}',
            style: TextStyle(
              color: file.isClean ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (!file.isClean && file.threats != null && file.threats!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'التهديدات المكتشفة:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                ...file.threats!.map((threat) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${threat.description} (خطورة: ${threat.severity}/10)',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                )),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (File(file.path).existsSync())
                TextButton.icon(
                  icon: const Icon(Icons.visibility, color: AppColors.lightPurple),
                  label: const Text(
                    'فتح الملف',
                    style: TextStyle(color: AppColors.lightPurple),
                  ),
                  onPressed: () {
                    // يمكن إضافة وظيفة فتح الملف هنا
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
