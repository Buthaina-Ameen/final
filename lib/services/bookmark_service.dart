import 'package:flutter/material.dart';
import 'package:by_hex/constants/app_colors.dart';
import 'package:provider/provider.dart';
import 'dart:io';

class BookmarkService extends ChangeNotifier {
  // قائمة الإشارات المرجعية
  final List<Bookmark> _bookmarks = [];
  List<Bookmark> get bookmarks => List.unmodifiable(_bookmarks);
  
  // إضافة إشارة مرجعية جديدة
  void addBookmark(String filePath, int offset, String name, String description) {
    // التحقق من عدم وجود إشارة مرجعية بنفس المسار والموقع
    final existingIndex = _bookmarks.indexWhere(
      (bookmark) => bookmark.filePath == filePath && bookmark.offset == offset
    );
    
    if (existingIndex != -1) {
      // تحديث الإشارة المرجعية الموجودة
      _bookmarks[existingIndex] = Bookmark(
        filePath: filePath,
        offset: offset,
        name: name,
        description: description,
        createdAt: _bookmarks[existingIndex].createdAt,
      );
    } else {
      // إضافة إشارة مرجعية جديدة
      _bookmarks.add(Bookmark(
        filePath: filePath,
        offset: offset,
        name: name,
        description: description,
        createdAt: DateTime.now(),
      ));
    }
    
    notifyListeners();
  }
  
  // حذف إشارة مرجعية
  void removeBookmark(String filePath, int offset) {
    _bookmarks.removeWhere(
      (bookmark) => bookmark.filePath == filePath && bookmark.offset == offset
    );
    notifyListeners();
  }
  
  // الحصول على إشارات مرجعية لملف معين
  List<Bookmark> getBookmarksForFile(String filePath) {
    return _bookmarks.where((bookmark) => bookmark.filePath == filePath).toList();
  }
  
  // التحقق من وجود إشارة مرجعية في موقع معين
  bool hasBookmarkAt(String filePath, int offset) {
    return _bookmarks.any(
      (bookmark) => bookmark.filePath == filePath && bookmark.offset == offset
    );
  }
  
  // الانتقال إلى الإشارة المرجعية التالية في الملف
  Bookmark? getNextBookmark(String filePath, int currentOffset) {
    final fileBookmarks = getBookmarksForFile(filePath);
    if (fileBookmarks.isEmpty) return null;
    
    // ترتيب الإشارات المرجعية حسب الموقع
    fileBookmarks.sort((a, b) => a.offset.compareTo(b.offset));
    
    // البحث عن الإشارة المرجعية التالية
    for (final bookmark in fileBookmarks) {
      if (bookmark.offset > currentOffset) {
        return bookmark;
      }
    }
    
    // إذا لم يتم العثور على إشارة مرجعية تالية، العودة إلى الأولى
    return fileBookmarks.first;
  }
  
  // الانتقال إلى الإشارة المرجعية السابقة في الملف
  Bookmark? getPreviousBookmark(String filePath, int currentOffset) {
    final fileBookmarks = getBookmarksForFile(filePath);
    if (fileBookmarks.isEmpty) return null;
    
    // ترتيب الإشارات المرجعية حسب الموقع بترتيب تنازلي
    fileBookmarks.sort((a, b) => b.offset.compareTo(a.offset));
    
    // البحث عن الإشارة المرجعية السابقة
    for (final bookmark in fileBookmarks) {
      if (bookmark.offset < currentOffset) {
        return bookmark;
      }
    }
    
    // إذا لم يتم العثور على إشارة مرجعية سابقة، العودة إلى الأخيرة
    return fileBookmarks.first;
  }
}

// نموذج الإشارة المرجعية
class Bookmark {
  final String filePath;
  final int offset;
  final String name;
  final String description;
  final DateTime createdAt;
  
  Bookmark({
    required this.filePath,
    required this.offset,
    required this.name,
    required this.description,
    required this.createdAt,
  });
  
  // الحصول على اسم الملف من المسار
  String get fileName {
    return filePath.split('/').last;
  }
  
  // تحويل الموقع إلى تنسيق سداسي عشري
  String get hexOffset {
    return '0x${offset.toRadixString(16).toUpperCase().padLeft(8, '0')}';
  }
}

// شاشة إدارة الإشارات المرجعية
class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bookmarkService = Provider.of<BookmarkService>(context);
    final bookmarks = bookmarkService.bookmarks;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشارات المرجعية'),
        backgroundColor: AppColors.appBarColor,
        foregroundColor: Colors.black87,
      ),
      body: Container(
        color: AppColors.backgroundColor,
        child: bookmarks.isEmpty
            ? const Center(
                child: Text(
                  'لا توجد إشارات مرجعية',
                  style: TextStyle(color: AppColors.textColor),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: bookmarks.length,
                itemBuilder: (context, index) {
                  final bookmark = bookmarks[index];
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: AppColors.cardColor,
                    child: ListTile(
                      leading: const Icon(
                        Icons.bookmark,
                        color: AppColors.mediumPurple,
                      ),
                      title: Text(
                        bookmark.name,
                        style: const TextStyle(color: AppColors.textColor),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الملف: ${bookmark.fileName}',
                            style: TextStyle(color: AppColors.secondaryTextColor),
                          ),
                          Text(
                            'الموقع: ${bookmark.hexOffset}',
                            style: TextStyle(color: AppColors.secondaryTextColor),
                          ),
                          if (bookmark.description.isNotEmpty)
                            Text(
                              'الوصف: ${bookmark.description}',
                              style: TextStyle(color: AppColors.secondaryTextColor),
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'حذف الإشارة المرجعية',
                        onPressed: () {
                          bookmarkService.removeBookmark(bookmark.filePath, bookmark.offset);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم حذف الإشارة المرجعية'),
                              backgroundColor: AppColors.deepPurple,
                            ),
                          );
                        },
                      ),
                      onTap: () {
                        // الانتقال إلى الملف والموقع المحدد
                        // سيتم تنفيذ هذا عند ربط الشاشة بباقي التطبيق
                        Navigator.pop(context, bookmark);
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// مربع حوار إضافة إشارة مرجعية
class AddBookmarkDialog extends StatefulWidget {
  final String filePath;
  final int offset;
  final Bookmark? existingBookmark;
  
  const AddBookmarkDialog({
    Key? key,
    required this.filePath,
    required this.offset,
    this.existingBookmark,
  }) : super(key: key);

  @override
  State<AddBookmarkDialog> createState() => _AddBookmarkDialogState();
}

class _AddBookmarkDialogState extends State<AddBookmarkDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  
  @override
  void initState() {
    super.initState();
    
    // تعبئة البيانات إذا كانت هناك إشارة مرجعية موجودة
    _nameController = TextEditingController(
      text: widget.existingBookmark?.name ?? 'إشارة مرجعية عند ${_formatOffset(widget.offset)}',
    );
    
    _descriptionController = TextEditingController(
      text: widget.existingBookmark?.description ?? '',
    );
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  String _formatOffset(int offset) {
    return '0x${offset.toRadixString(16).toUpperCase().padLeft(8, '0')}';
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existingBookmark != null
            ? 'تعديل الإشارة المرجعية'
            : 'إضافة إشارة مرجعية',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'الاسم',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'الوصف (اختياري)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          Text(
            'الموقع: ${_formatOffset(widget.offset)}',
            style: TextStyle(color: AppColors.secondaryTextColor),
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
            final name = _nameController.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('يرجى إدخال اسم للإشارة المرجعية'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            
            Navigator.pop(
              context,
              {
                'name': name,
                'description': _descriptionController.text.trim(),
              },
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.deepPurple,
            foregroundColor: Colors.white,
          ),
          child: Text(
            widget.existingBookmark != null ? 'تحديث' : 'إضافة',
          ),
        ),
      ],
    );
  }
}
