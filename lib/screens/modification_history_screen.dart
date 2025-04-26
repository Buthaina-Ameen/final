import 'package:flutter/material.dart';
import 'package:by_hex/constants/app_colors.dart';
import 'package:by_hex/services/enhanced_file_service.dart';
import 'package:provider/provider.dart';
import 'dart:io';

class ModificationHistoryScreen extends StatelessWidget {
  const ModificationHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fileService = Provider.of<EnhancedFileService>(context);
    final modifications = fileService.modificationHistory;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل التعديلات'),
        backgroundColor: AppColors.appBarColor,
        foregroundColor: Colors.black87,
      ),
      body: Container(
        color: AppColors.backgroundColor,
        child: modifications.isEmpty
            ? const Center(
                child: Text(
                  'لا توجد تعديلات مسجلة',
                  style: TextStyle(color: AppColors.textColor),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: modifications.length,
                itemBuilder: (context, index) {
                  final modification = modifications[index];
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: AppColors.cardColor,
                    child: ListTile(
                      leading: Icon(
                        _getModificationIcon(modification.type),
                        color: AppColors.mediumPurple,
                      ),
                      title: Text(
                        _getModificationTitle(modification.type),
                        style: const TextStyle(color: AppColors.textColor),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الموقع: 0x${modification.offset.toRadixString(16).toUpperCase().padLeft(8, '0')}',
                            style: TextStyle(color: AppColors.secondaryTextColor),
                          ),
                          Text(
                            'الوقت: ${modification.timestamp.toString().substring(0, 19)}',
                            style: TextStyle(color: AppColors.secondaryTextColor),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.undo, color: AppColors.mediumPurple),
                        tooltip: 'التراجع عن التعديل',
                        onPressed: () {
                          _showUndoDialog(context, fileService, modification);
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
  
  IconData _getModificationIcon(ModificationType type) {
    switch (type) {
      case ModificationType.insert:
        return Icons.add_circle_outline;
      case ModificationType.delete:
        return Icons.remove_circle_outline;
      case ModificationType.replace:
        return Icons.edit;
      default:
        return Icons.change_circle_outlined;
    }
  }
  
  String _getModificationTitle(ModificationType type) {
    switch (type) {
      case ModificationType.insert:
        return 'إضافة بايت';
      case ModificationType.delete:
        return 'حذف بايت';
      case ModificationType.replace:
        return 'تعديل بايت';
      default:
        return 'تعديل غير معروف';
    }
  }
  
  void _showUndoDialog(BuildContext context, EnhancedFileService fileService, FileModification modification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('التراجع عن التعديل'),
        content: Text('هل أنت متأكد من التراجع عن هذا التعديل؟ قد يؤثر ذلك على التعديلات اللاحقة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              fileService.undoModification(modification);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم التراجع عن التعديل'),
                  backgroundColor: AppColors.deepPurple,
                ),
              );
            },
            child: const Text('تراجع'),
          ),
        ],
      ),
    );
  }
}

enum ModificationType {
  insert,
  delete,
  replace,
}

class FileModification {
  final ModificationType type;
  final int offset;
  final List<int> oldValue;
  final List<int> newValue;
  final DateTime timestamp;
  
  FileModification({
    required this.type,
    required this.offset,
    required this.oldValue,
    required this.newValue,
    required this.timestamp,
  });
}
