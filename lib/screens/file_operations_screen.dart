import 'package:flutter/material.dart';
import 'package:by_hex/constants/app_colors.dart';
import 'package:by_hex/services/enhanced_file_service.dart';
import 'package:by_hex/services/enhanced_hex_editor_service.dart';
import 'package:by_hex/screens/file_compare_screen.dart';
import 'package:by_hex/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

class FileOperationsScreen extends StatefulWidget {
  const FileOperationsScreen({super.key});

  @override
  State<FileOperationsScreen> createState() => _FileOperationsScreenState();
}

class _FileOperationsScreenState extends State<FileOperationsScreen> {
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadRecentFiles();
  }
  
  Future<void> _loadRecentFiles() async {
    setState(() {
      _isLoading = true;
    });
    
    final fileService = Provider.of<EnhancedFileService>(context, listen: false);
    await fileService.loadRecentFiles();
    
    setState(() {
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final fileService = Provider.of<EnhancedFileService>(context);
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الملفات'),
        backgroundColor: AppColors.appBarColor,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecentFiles,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authService.signOut();
            },
          ),
        ],
      ),
      body: Container(
        color: AppColors.backgroundColor,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.mediumPurple),
                ),
              )
            : Column(
                children: [
                  _buildLocalFileOperations(fileService),
                  const Divider(color: AppColors.mediumGray),
                  _buildCloudFilesList(fileService),
                ],
              ),
      ),
    );
  }
  
  Widget _buildLocalFileOperations(EnhancedFileService fileService) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'العمليات المحلية',
            style: TextStyle(
              color: AppColors.lightPurple,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOperationButton(
                icon: Icons.folder_open,
                label: 'فتح ملف',
                onPressed: () async {
                  final result = await fileService.openLocalFile();
                  if (result && mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
              _buildOperationButton(
                icon: Icons.create_new_folder,
                label: 'إنشاء ملف جديد',
                onPressed: () async {
                  final result = await fileService.createNewFile();
                  if (result && mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
              _buildOperationButton(
                icon: Icons.compare,
                label: 'مقارنة ملفين',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FileCompareScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildCloudFilesList(EnhancedFileService fileService) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'الملفات السحابية',
                  style: TextStyle(
                    color: AppColors.lightPurple,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (fileService.currentFile != null)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('تحميل الملف الحالي'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mediumPurple,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final result = await fileService.uploadCurrentFile();
                      if (result && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم تحميل الملف بنجاح')),
                        );
                        _loadRecentFiles();
                      }
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: fileService.recentFiles.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد ملفات سحابية',
                      style: TextStyle(color: AppColors.secondaryTextColor),
                    ),
                  )
                : ListView.builder(
                    itemCount: fileService.recentFiles.length,
                    itemBuilder: (context, index) {
                      final file = fileService.recentFiles[index];
                      return ListTile(
                        leading: const Icon(
                          Icons.insert_drive_file,
                          color: AppColors.lightPurple,
                        ),
                        title: Text(
                          file.name,
                          style: const TextStyle(color: AppColors.textColor),
                        ),
                        subtitle: Text(
                          'الحجم: ${_formatFileSize(file.size)} - آخر تعديل: ${_formatDate(file.lastModified)}',
                          style: const TextStyle(color: AppColors.secondaryTextColor),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.cloud_download, color: AppColors.mediumPurple),
                              onPressed: () async {
                                final result = await fileService.downloadCloudFile(file);
                                if (result && mounted) {
                                  Navigator.pop(context);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () {
                                // حذف الملف من السحابة
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOperationButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.mediumPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: onPressed,
    );
  }
  
  String _formatFileSize(int sizeInBytes) {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes بايت';
    } else if (sizeInBytes < 1024 * 1024) {
      final sizeInKB = (sizeInBytes / 1024).toStringAsFixed(1);
      return '$sizeInKB كيلوبايت';
    } else {
      final sizeInMB = (sizeInBytes / (1024 * 1024)).toStringAsFixed(1);
      return '$sizeInMB ميجابايت';
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}
