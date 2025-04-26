import 'package:flutter/material.dart';
import 'package:by_hex/constants/app_colors.dart';
import 'package:by_hex/services/enhanced_file_service.dart';
import 'package:by_hex/services/enhanced_hex_editor_service.dart';
import 'package:by_hex/utils/enhanced_large_file_handler.dart';
import 'package:provider/provider.dart';

class FileModificationTracker extends StatelessWidget {
  final Widget child;
  
  const FileModificationTracker({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fileService = Provider.of<EnhancedFileService>(context);
    final isModified = fileService.isModified;
    final currentFile = fileService.currentFile;
    
    return Stack(
      children: [
        child,
        if (isModified && currentFile != null)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.modifiedByteColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'تم التعديل',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class ModificationHistoryScreen extends StatelessWidget {
  const ModificationHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fileService = Provider.of<EnhancedFileService>(context);
    final hexEditorService = Provider.of<EnhancedHexEditorService>(context);
    
    // الحصول على قائمة التعديلات
    final modifications = fileService.getModifications();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل التعديلات'),
        backgroundColor: AppColors.appBarColor,
        foregroundColor: Colors.black87,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('حفظ التغييرات'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black87,
            ),
            onPressed: () async {
              await fileService.saveChanges();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.cancel),
            label: const Text('تجاهل التغييرات'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black87,
            ),
            onPressed: () {
              fileService.discardChanges();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Container(
        color: AppColors.backgroundColor,
        child: modifications.isEmpty
            ? const Center(
                child: Text(
                  'لا توجد تعديلات',
                  style: TextStyle(color: AppColors.textColor),
                ),
              )
            : ListView.builder(
                itemCount: modifications.length,
                itemBuilder: (context, index) {
                  final modification = modifications[index];
                  final offset = modification.key;
                  final originalValue = modification.value[0];
                  final newValue = modification.value[1];
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.mediumPurple,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      'الإزاحة: 0x${offset.toRadixString(16).toUpperCase().padLeft(8, '0')}',
                      style: const TextStyle(color: AppColors.textColor),
                    ),
                    subtitle: Row(
                      children: [
                        Text(
                          'القيمة الأصلية: ${hexEditorService.byteToHex(originalValue)}',
                          style: TextStyle(color: AppColors.secondaryTextColor),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'القيمة الجديدة: ${hexEditorService.byteToHex(newValue)}',
                          style: TextStyle(color: AppColors.modifiedByteColor),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.undo, color: AppColors.mediumPurple),
                      onPressed: () {
                        fileService.undoModification(offset);
                      },
                    ),
                    onTap: () {
                      // الانتقال إلى موقع التعديل في المحرر
                      hexEditorService.selectByte(offset);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
      ),
    );
  }
}

// إضافة وظائف التعديل إلى خدمة الملفات
extension FileModificationExtension on EnhancedFileService {
  // الحصول على قائمة التعديلات
  List<MapEntry<int, List<int>>> getModifications() {
    if (largeFileHandler != null) {
      return (largeFileHandler as EnhancedLargeFileHandler).getModifications();
    }
    
    // إذا لم يكن هناك مدير ملفات كبيرة، نعيد قائمة فارغة
    return [];
  }
  
  // حفظ التغييرات
  Future<void> saveChanges() async {
    if (largeFileHandler != null) {
      await (largeFileHandler as EnhancedLargeFileHandler).saveChanges();
      notifyListeners();
    }
  }
  
  // تجاهل التغييرات
  void discardChanges() {
    if (largeFileHandler != null) {
      (largeFileHandler as EnhancedLargeFileHandler).discardChanges();
      notifyListeners();
    }
  }
  
  // التراجع عن تعديل محدد
  void undoModification(int offset) {
    if (largeFileHandler != null && fileBytes != null) {
      // الحصول على قائمة التعديلات
      final modifications = (largeFileHandler as EnhancedLargeFileHandler).getModifications();
      
      // البحث عن التعديل المطلوب
      for (final modification in modifications) {
        if (modification.key == offset) {
          // استعادة القيمة الأصلية
          final originalValue = modification.value[0];
          
          // تحديث البايت في الذاكرة
          final index = offset;
          if (index < fileBytes!.length) {
            fileBytes![index] = originalValue;
          }
          
          // إزالة التعديل من المدير
          (largeFileHandler as EnhancedLargeFileHandler).writeByte(offset, originalValue);
          
          break;
        }
      }
      
      notifyListeners();
    }
  }
  
  // التحقق من وجود تعديلات غير محفوظة قبل الإغلاق
  Future<bool> checkUnsavedChanges(BuildContext context) async {
    if (isModified) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تعديلات غير محفوظة'),
          content: const Text('هناك تعديلات غير محفوظة. هل تريد حفظها قبل الإغلاق؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('تجاهل التغييرات'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حفظ التغييرات'),
            ),
          ],
        ),
      );
      
      if (result == true) {
        await saveChanges();
      } else {
        discardChanges();
      }
    }
    
    return true;
  }
}
