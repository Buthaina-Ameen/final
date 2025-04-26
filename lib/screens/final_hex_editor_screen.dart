import 'package:flutter/material.dart';
import 'package:by_hex/constants/app_colors.dart';
import 'package:by_hex/services/enhanced_file_service.dart';
import 'package:by_hex/services/enhanced_hex_editor_service.dart';
import 'package:by_hex/services/bookmark_service.dart';
import 'package:by_hex/services/report_export_service.dart';
import 'package:by_hex/services/security_service.dart';
import 'package:by_hex/services/virus_total_service.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class FinalHexEditorScreen extends StatefulWidget {
  const FinalHexEditorScreen({super.key});

  @override
  State<FinalHexEditorScreen> createState() => _FinalHexEditorScreenState();
}

class _FinalHexEditorScreenState extends State<FinalHexEditorScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isHexSearch = true;
  
  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final fileService = Provider.of<EnhancedFileService>(context);
    final hexEditorService = Provider.of<EnhancedHexEditorService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hex Editor'),
        backgroundColor: AppColors.appBarColor,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // قائمة الإعدادات
            },
          ),
        ],
      ),
      body: Container(
        color: AppColors.backgroundColor,
        child: Column(
          children: [
            if (fileService.currentFile == null)
              _buildEmptyState()
            else
              _buildFileHeader(fileService),
            
            Expanded(
              child: fileService.fileBytes == null
                  ? const SizedBox()
                  : _buildHexEditor(fileService, hexEditorService),
            ),
          ],
        ),
      ),
      bottomNavigationBar: fileService.fileBytes != null
          ? _buildBottomBar(fileService, hexEditorService)
          : null,
    );
  }
  
  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: ElevatedButton(
          onPressed: _openFile,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.buttonColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'Open or Create File',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFileHeader(EnhancedFileService fileService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AppColors.darkGray,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'الملف: ${fileService.currentFile?.name ?? ""}',
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontSize: 16,
                  ),
                ),
              ),
              if (fileService.securityMessage != null)
                GestureDetector(
                  onTap: () => _showSecurityStatusDialog(fileService),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: fileService.isInfected 
                          ? Colors.red.withOpacity(0.2) 
                          : Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: fileService.isInfected ? Colors.red : Colors.green,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          fileService.isInfected ? Icons.warning : Icons.check_circle,
                          color: fileService.isInfected ? Colors.red : Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          fileService.isInfected ? 'ملف ضار' : 'ملف آمن',
                          style: TextStyle(
                            color: fileService.isInfected ? Colors.red : Colors.green,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (fileService.currentFile != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'الحجم: ${_formatFileSize(fileService.currentFile!.size)}',
                style: TextStyle(
                  color: AppColors.secondaryTextColor,
                  fontSize: 12,
                ),
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
  
  Widget _buildHexEditor(EnhancedFileService fileService, EnhancedHexEditorService hexEditorService) {
    final bytes = fileService.fileBytes!;
    final bytesPerRow = hexEditorService.bytesPerRow;
    final rowCount = (bytes.length / bytesPerRow).ceil();
    
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: rowCount,
        itemBuilder: (context, rowIndex) {
          final startOffset = rowIndex * bytesPerRow;
          final endOffset = (startOffset + bytesPerRow) > bytes.length
              ? bytes.length
              : startOffset + bytesPerRow;
          final rowBytes = bytes.sublist(startOffset, endOffset);
          
          return _buildHexRow(
            rowIndex,
            startOffset,
            rowBytes,
            hexEditorService,
            fileService,
          );
        },
      ),
    );
  }
  
  Widget _buildHexRow(
    int rowIndex,
    int startOffset,
    List<int> rowBytes,
    EnhancedHexEditorService hexEditorService,
    EnhancedFileService fileService,
  ) {
    final bookmarkService = Provider.of<BookmarkService>(context);
    final hasCurrentFile = fileService.currentFile != null;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      color: rowIndex % 2 == 0 ? AppColors.darkGray : AppColors.darkGrayLight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عرض قيم Hex
          Expanded(
            flex: 3,
            child: Wrap(
              spacing: 8,
              children: List.generate(rowBytes.length, (index) {
                final byteOffset = startOffset + index;
                final byte = rowBytes[index];
                final isSelected = hexEditorService.selectedOffset == byteOffset;
                final isSearchResult = hexEditorService.searchResults.contains(byteOffset);
                final isBookmarked = hasCurrentFile && 
                    bookmarkService.hasBookmarkAt(fileService.currentFile!.path, byteOffset);
                
                return GestureDetector(
                  onTap: () {
                    hexEditorService.selectByte(byteOffset);
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.selectedByteColor
                          : isBookmarked
                              ? AppColors.deepPurple.withOpacity(0.2)
                              : isSearchResult
                                  ? AppColors.mediumPurple.withOpacity(0.3)
                                  : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: isBookmarked
                          ? Border.all(color: AppColors.deepPurple, width: 1)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        hexEditorService.byteToHex(byte),
                        style: TextStyle(
                          color: isBookmarked 
                              ? AppColors.deepPurple
                              : AppColors.hexValueColor,
                          fontFamily: 'monospace',
                          fontWeight: isSelected || isBookmarked ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          // عرض قيم ASCII/UTF-8
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                rowBytes.map((byte) => hexEditorService.byteToAscii(byte)).join(''),
                style: TextStyle(
                  color: AppColors.asciiValueColor,
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),
          ),
          
          // عرض الإزاحة
          SizedBox(
            width: 100,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '${startOffset.toRadixString(16).padLeft(8, '0').toUpperCase()}',
                style: TextStyle(
                  color: AppColors.offsetColor,
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomBar(EnhancedFileService fileService, EnhancedHexEditorService hexEditorService) {
    final bookmarkService = Provider.of<BookmarkService>(context);
    final hasCurrentFile = fileService.currentFile != null;
    final hasSelectedByte = hexEditorService.selectedOffset != null;
    
    return Container(
      height: 56,
      color: AppColors.bottomBarColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.black87),
            onPressed: () {
              _showSearchDialog(hexEditorService, fileService);
            },
          ),
          IconButton(
            icon: Icon(
              Icons.bookmark,
              color: hasCurrentFile && hasSelectedByte && 
                    bookmarkService.hasBookmarkAt(
                      fileService.currentFile!.path,
                      hexEditorService.selectedOffset!
                    )
                  ? AppColors.deepPurple
                  : Colors.black87,
            ),
            onPressed: hasCurrentFile && hasSelectedByte
                ? () => _handleBookmarkAction(fileService, hexEditorService, bookmarkService)
                : null,
          ),
          IconButton(
            icon: Icon(Icons.bookmark_border, color: Colors.black87),
            onPressed: hasCurrentFile
                ? () => _showBookmarksScreen(fileService, hexEditorService, bookmarkService)
                : null,
          ),
          IconButton(
            icon: Icon(Icons.description, color: Colors.black87),
            onPressed: hasCurrentFile
                ? () => _showExportReportDialog(fileService)
                : null,
            tooltip: 'تصدير تقرير',
          ),
          IconButton(
            icon: Icon(Icons.more_horiz, color: Colors.black87),
            onPressed: () {
              _showMoreOptionsDialog(hexEditorService);
            },
          ),
          IconButton(
            icon: Icon(Icons.arrow_upward, color: Colors.black87),
            onPressed: () {
              _scrollToPosition(0);
            },
          ),
          IconButton(
            icon: Icon(Icons.arrow_downward, color: Colors.black87),
            onPressed: () {
              if (fileService.fileBytes != null) {
                final bytesPerRow = hexEditorService.bytesPerRow;
                final rowCount = (fileService.fileBytes!.length / bytesPerRow).ceil();
                _scrollToPosition(rowCount - 1);
              }
            },
          ),
        ],
      ),
    );
  }
  
  void _scrollToPosition(int rowIndex) {
    final itemHeight = 28.0; // تقدير تقريبي لارتفاع الصف
    _scrollController.animateTo(
      rowIndex * itemHeight,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  // التعامل مع إضافة أو حذف الإشارة المرجعية
  void _handleBookmarkAction(
    EnhancedFileService fileService,
    EnhancedHexEditorService hexEditorService,
    BookmarkService bookmarkService,
  ) async {
    if (fileService.currentFile == null || hexEditorService.selectedOffset == null) {
      return;
    }
    
    final filePath = fileService.currentFile!.path;
    final offset = hexEditorService.selectedOffset!;
    
    // التحقق مما إذا كانت هناك إشارة مرجعية موجودة بالفعل
    final hasBookmark = bookmarkService.hasBookmarkAt(filePath, offset);
    
    if (hasBookmark) {
      // عرض خيارات للإشارة المرجعية الموجودة
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('إدارة الإشارة المرجعية'),
          content: const Text('ماذا تريد أن تفعل بهذه الإشارة المرجعية؟'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                bookmarkService.removeBookmark(filePath, offset);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف الإشارة المرجعية')),
                );
              },
              child: const Text('حذف'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showAddBookmarkDialog(filePath, offset, bookmarkService);
              },
              child: const Text('تعديل'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
          ],
        ),
      );
    } else {
      // إضافة إشارة مرجعية جديدة
      _showAddBookmarkDialog(filePath, offset, bookmarkService);
    }
  }
  
  // عرض مربع حوار إضافة إشارة مرجعية
  void _showAddBookmarkDialog(
    String filePath,
    int offset,
    BookmarkService bookmarkService,
  ) async {
    final existingBookmark = bookmarkService.hasBookmarkAt(filePath, offset)
        ? bookmarkService.getBookmarksForFile(filePath).firstWhere(
              (bookmark) => bookmark.offset == offset,
            )
        : null;
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AddBookmarkDialog(
        filePath: filePath,
        offset: offset,
        existingBookmark: existingBookmark,
      ),
    );
    
    if (result != null) {
      bookmarkService.addBookmark(
        filePath,
        offset,
        result['name']!,
        result['description']!,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existingBookmark != null
                  ? 'تم تحديث الإشارة المرجعية'
                  : 'تمت إضافة الإشارة المرجعية',
            ),
          ),
        );
      }
    }
  }
  
  // عرض شاشة الإشارات المرجعية
  void _showBookmarksScreen(
    EnhancedFileService fileService,
    EnhancedHexEditorService hexEditorService,
    BookmarkService bookmarkService,
  ) async {
    if (fileService.currentFile == null) return;
    
    final selectedBookmark = await Navigator.push<Bookmark>(
      context,
      MaterialPageRoute(
        builder: (context) => const BookmarksScreen(),
      ),
    );
    
    if (selectedBookmark != null && mounted) {
      // التحقق مما إذا كانت الإشارة المرجعية تنتمي للملف الحالي
      if (selectedBookmark.filePath == fileService.currentFile!.path) {
        // الانتقال إلى موقع الإشارة المرجعية
        hexEditorService.selectByte(selectedBookmark.offset);
        
        // حساب رقم الصف وتمرير التمرير إليه
        final bytesPerRow = hexEditorService.bytesPerRow;
        final rowIndex = (selectedBookmark.offset / bytesPerRow).floor();
        _scrollToPosition(rowIndex);
      } else {
        // عرض رسالة خطأ إذا كانت الإشارة المرجعية لملف آخر
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('هذه الإشارة المرجعية تنتمي لملف آخر. يرجى فتح الملف المناسب أولاً.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  // عرض مربع حوار تصدير التقرير
  void _showExportReportDialog(EnhancedFileService fileService) async {
    if (fileService.currentFile == null) return;
    
    final securityService = Provider.of<SecurityService>(context, listen: false);
    final virusTotalService = Provider.of<VirusTotalService>(context, listen: false);
    
    // الحصول على نتائج الفحص الأمني إذا كانت متوفرة
    SecurityScanResult? securityScanResult;
    if (fileService.isInfected != null) {
      securityScanResult = await securityService.scanFile(File(fileService.currentFile!.path));
    }
    
    // الحصول على نتائج فحص VirusTotal إذا كانت متوفرة
    VirusTotalService.VirusTotalResult? virusTotalResult;
    if (virusTotalService.apiKey.isNotEmpty && 
        virusTotalService.apiKey != 'YOUR_VIRUSTOTAL_API_KEY' &&
        fileService.currentFile!.size < 32 * 1024 * 1024) {
      try {
        virusTotalResult = await virusTotalService.scanFile(File(fileService.currentFile!.path));
      } catch (e) {
        debugPrint('Error scanning with VirusTotal: $e');
      }
    }
    
    if (!mounted) return;
    
    // عرض مربع حوار لتخصيص التقرير
    bool includeSecurityScan = securityScanResult != null;
    bool includeVirusTotal = virusTotalResult != null;
    bool includeModifications = fileService.modificationHistory.isNotEmpty;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('تصدير تقرير'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('اختر محتويات التقرير:'),
              const SizedBox(height: 10),
              
              CheckboxListTile(
                title: const Text('معلومات الملف الأساسية'),
                value: true,
                onChanged: null, // دائماً مضمنة
                activeColor: AppColors.deepPurple,
              ),
              
              if (securityScanResult != null)
                CheckboxListTile(
                  title: const Text('نتائج الفحص الأمني'),
                  value: includeSecurityScan,
                  onChanged: (value) {
                    setState(() {
                      includeSecurityScan = value!;
                    });
                  },
                  activeColor: AppColors.deepPurple,
                ),
              
              if (virusTotalResult != null)
                CheckboxListTile(
                  title: const Text('نتائج فحص VirusTotal'),
                  value: includeVirusTotal,
                  onChanged: (value) {
                    setState(() {
                      includeVirusTotal = value!;
                    });
                  },
                  activeColor: AppColors.deepPurple,
                ),
              
              if (fileService.modificationHistory.isNotEmpty)
                CheckboxListTile(
                  title: const Text('سجل التعديلات'),
                  value: includeModifications,
                  onChanged: (value) {
                    setState(() {
                      includeModifications = value!;
                    });
                  },
                  activeColor: AppColors.deepPurple,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                
                // عرض مؤشر التقدم
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('جاري إنشاء التقرير...'),
                      ],
                    ),
                  ),
                );
                
                try {
                  // تصدير التقرير
                  final reportPath = await ReportExportService.exportFileReport(
                    context: context,
                    file: File(fileService.currentFile!.path),
                    securityScanResult: includeSecurityScan ? securityScanResult : null,
                    virusTotalResult: includeVirusTotal ? virusTotalResult : null,
                    includeModifications: includeModifications,
                  );
                  
                  if (mounted) {
                    // إغلاق مؤشر التقدم
                    Navigator.pop(context);
                    
                    // عرض مربع حوار النجاح
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('تم إنشاء التقرير بنجاح'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('تم حفظ التقرير في:'),
                            const SizedBox(height: 8),
                            Text(
                              reportPath,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('إغلاق'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ReportExportService.shareReport(reportPath);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.deepPurple,
                            ),
                            child: const Text('مشاركة التقرير'),
                          ),
                        ],
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    // إغلاق مؤشر التقدم
                    Navigator.pop(context);
                    
                    // عرض رسالة الخطأ
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('حدث خطأ أثناء إنشاء التقرير: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepPurple,
              ),
              child: const Text('تصدير'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _openFile() async {
    final fileService = Provider.of<EnhancedFileService>(context, listen: false);
    final result = await fileService.openLocalFile(context: context);
    
    if (result && mounted) {
      // عرض رسالة نجاح فتح الملف
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم فتح الملف: ${fileService.currentFile?.name}'),
          duration: const Duration(seconds: 2),
        ),
      );
      
      // عرض حالة الفحص الأمني إذا كانت متوفرة
      if (fileService.securityMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSecurityStatusDialog(fileService);
        });
      }
    }
  }
  
  void _showSecurityStatusDialog(EnhancedFileService fileService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          fileService.isInfected ? 'تحذير أمني' : 'الملف آمن',
          style: TextStyle(
            color: fileService.isInfected ? Colors.red : Colors.green,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              fileService.isInfected ? Icons.warning : Icons.check_circle,
              color: fileService.isInfected ? Colors.red : Colors.green,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              fileService.securityMessage ?? 'تم فحص الملف',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }
  
  void _showSearchDialog(EnhancedHexEditorService hexEditorService, EnhancedFileService fileService) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Search',
            style: TextStyle(color: Colors.black87),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search Start Address',
                  border: UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('DEC', style: TextStyle(color: Colors.black87)),
                  Radio<bool>(
                    value: false,
                    groupValue: _isHexSearch,
                    activeColor: AppColors.deepPurple,
                    onChanged: (value) {
                      setState(() {
                        _isHexSearch = value!;
                      });
                    },
                  ),
                  const SizedBox(width: 16),
                  const Text('HEX', style: TextStyle(color: Colors.black87)),
                  Radio<bool>(
                    value: true,
                    groupValue: _isHexSearch,
                    activeColor: AppColors.deepPurple,
                    onChanged: (value) {
                      setState(() {
                        _isHexSearch = value!;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.deepPurple,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_searchController.text.isNotEmpty) {
                  if (_isHexSearch) {
                    hexEditorService.searchHex(_searchController.text, fileService);
                  } else {
                    hexEditorService.searchText(_searchController.text, fileService);
                  }
                  
                  Navigator.of(context).pop();
                  
                  if (hexEditorService.searchResults.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No results found')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Found ${hexEditorService.searchResults.length} results',
                        ),
                        action: SnackBarAction(
                          label: 'Next',
                          onPressed: () {
                            hexEditorService.nextSearchResult();
                          },
                        ),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepPurple,
              ),
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }
  
  void _showMoreOptionsDialog(EnhancedHexEditorService hexEditorService) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'More',
            style: TextStyle(color: Colors.black87),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _scrollToPosition(0);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(color: AppColors.deepPurple),
                  ),
                ),
                child: const Text('File to Start of File'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  final fileService = Provider.of<EnhancedFileService>(context, listen: false);
                  if (fileService.fileBytes != null) {
                    final bytesPerRow = hexEditorService.bytesPerRow;
                    final rowCount = (fileService.fileBytes!.length / bytesPerRow).ceil();
                    _scrollToPosition(rowCount - 1);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(color: AppColors.deepPurple),
                  ),
                ),
                child: const Text('File to End of File'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.deepPurple,
              ),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
