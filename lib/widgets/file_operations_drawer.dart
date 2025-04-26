import 'package:flutter/material.dart';
import 'package:by_hex/constants/app_colors.dart';
import 'package:by_hex/services/file_service.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

class FileOperationsDrawer extends StatelessWidget {
  final VoidCallback onFileOpened;
  final VoidCallback onFileCreated;
  final VoidCallback onFileSaved;
  final VoidCallback onCompareFilesSelected;
  final VoidCallback onLogoutSelected;

  const FileOperationsDrawer({
    super.key,
    required this.onFileOpened,
    required this.onFileCreated,
    required this.onFileSaved,
    required this.onCompareFilesSelected,
    required this.onLogoutSelected,
  });

  @override
  Widget build(BuildContext context) {
    final fileService = Provider.of<FileService>(context);
    
    return Drawer(
      backgroundColor: AppColors.darkGrayLight,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.darkGray,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'By Hex',
                  style: TextStyle(
                    color: AppColors.lightPurple,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  fileService.currentFile?.name ?? 'لم يتم فتح أي ملف',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (fileService.currentFile != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'الحجم: ${fileService.currentFile!.size} بايت',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fileService.isModified ? 'تم التعديل' : 'لم يتم التعديل',
                    style: TextStyle(
                      color: fileService.isModified ? AppColors.modifiedByteColor : Colors.white70,
                      fontSize: 12,
                      fontWeight: fileService.isModified ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.folder_open,
            title: 'فتح ملف',
            onTap: () {
              Navigator.pop(context);
              onFileOpened();
            },
          ),
          _buildDrawerItem(
            icon: Icons.create_new_folder,
            title: 'إنشاء ملف جديد',
            onTap: () {
              Navigator.pop(context);
              onFileCreated();
            },
          ),
          _buildDrawerItem(
            icon: Icons.save,
            title: 'حفظ الملف',
            onTap: fileService.currentFile != null ? () {
              Navigator.pop(context);
              onFileSaved();
            } : null,
          ),
          const Divider(color: Colors.grey),
          _buildDrawerItem(
            icon: Icons.cloud_upload,
            title: 'تحميل إلى السحابة',
            onTap: fileService.currentFile != null ? () async {
              Navigator.pop(context);
              final result = await fileService.uploadCurrentFile();
              if (result && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تحميل الملف بنجاح')),
                );
              }
            } : null,
          ),
          _buildDrawerItem(
            icon: Icons.cloud_download,
            title: 'تنزيل من السحابة',
            onTap: () {
              Navigator.pop(context);
              _showCloudFilesDialog(context, fileService);
            },
          ),
          const Divider(color: Colors.grey),
          _buildDrawerItem(
            icon: Icons.compare,
            title: 'مقارنة ملفين',
            onTap: () {
              Navigator.pop(context);
              onCompareFilesSelected();
            },
          ),
          const Divider(color: Colors.grey),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'تسجيل الخروج',
            onTap: () {
              Navigator.pop(context);
              onLogoutSelected();
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.lightPurple),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      onTap: onTap,
      enabled: onTap != null,
    );
  }
  
  Future<void> _showCloudFilesDialog(BuildContext context, FileService fileService) async {
    await fileService.loadRecentFiles();
    
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: AppColors.darkGrayLight,
            title: const Text(
              'الملفات السحابية',
              style: TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: fileService.recentFiles.isEmpty
                  ? const Center(
                      child: Text(
                        'لا توجد ملفات',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: fileService.recentFiles.length,
                      itemBuilder: (context, index) {
                        final file = fileService.recentFiles[index];
                        return ListTile(
                          title: Text(
                            file.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            'الحجم: ${file.size} بايت',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          leading: const Icon(
                            Icons.insert_drive_file,
                            color: AppColors.lightPurple,
                          ),
                          onTap: () {
                            // تنفيذ تنزيل الملف من السحابة
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'إلغاء',
                  style: TextStyle(color: AppColors.lightPurple),
                ),
              ),
            ],
          );
        },
      );
    }
  }
}
