import 'package:flutter/material.dart';
import 'package:by_hex/constants/app_colors.dart';
import 'package:by_hex/services/enhanced_file_service.dart';
import 'package:by_hex/services/enhanced_hex_editor_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

class FileCompareScreen extends StatefulWidget {
  const FileCompareScreen({super.key});

  @override
  State<FileCompareScreen> createState() => _FileCompareScreenState();
}

class _FileCompareScreenState extends State<FileCompareScreen> {
  FileModel? _file1;
  FileModel? _file2;
  List<int>? _file1Bytes;
  List<int>? _file2Bytes;
  List<int> _differences = [];
  bool _isComparing = false;
  int _currentDiffIndex = -1;
  
  final ScrollController _scrollController1 = ScrollController();
  final ScrollController _scrollController2 = ScrollController();
  
  @override
  void dispose() {
    _scrollController1.dispose();
    _scrollController2.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final hexEditorService = Provider.of<EnhancedHexEditorService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('مقارنة الملفات'),
        backgroundColor: AppColors.appBarColor,
        foregroundColor: Colors.black87,
      ),
      body: Container(
        color: AppColors.backgroundColor,
        child: Column(
          children: [
            _buildFileSelectionArea(),
            if (_file1 != null && _file2 != null)
              _buildCompareButton(),
            
            if (_isComparing && _differences.isNotEmpty)
              _buildDifferenceNavigation(),
            
            Expanded(
              child: _file1Bytes != null && _file2Bytes != null
                  ? _buildComparisonView(hexEditorService)
                  : const Center(
                      child: Text(
                        'اختر ملفين للمقارنة',
                        style: TextStyle(color: AppColors.textColor),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFileSelectionArea() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildFileSelector(
              label: 'الملف الأول',
              file: _file1,
              onSelect: _selectFile1,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildFileSelector(
              label: 'الملف الثاني',
              file: _file2,
              onSelect: _selectFile2,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFileSelector({
    required String label,
    required FileModel? file,
    required VoidCallback onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.lightPurple,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.mediumGray),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  file?.name ?? 'لم يتم اختيار ملف',
                  style: TextStyle(
                    color: file != null
                        ? AppColors.textColor
                        : AppColors.secondaryTextColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.folder_open, color: AppColors.mediumPurple),
                onPressed: onSelect,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildCompareButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.compare_arrows),
        label: const Text('مقارنة الملفين'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mediumPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        onPressed: _compareFiles,
      ),
    );
  }
  
  Widget _buildDifferenceNavigation() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: AppColors.darkGrayLight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'تم العثور على ${_differences.length} اختلاف',
            style: const TextStyle(color: AppColors.textColor),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.arrow_upward, color: AppColors.mediumPurple),
            onPressed: _currentDiffIndex > 0
                ? () => _navigateToDifference(_currentDiffIndex - 1)
                : null,
          ),
          Text(
            _currentDiffIndex >= 0
                ? '${_currentDiffIndex + 1} / ${_differences.length}'
                : '',
            style: const TextStyle(color: AppColors.textColor),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_downward, color: AppColors.mediumPurple),
            onPressed: _currentDiffIndex < _differences.length - 1
                ? () => _navigateToDifference(_currentDiffIndex + 1)
                : null,
          ),
        ],
      ),
    );
  }
  
  Widget _buildComparisonView(EnhancedHexEditorService hexEditorService) {
    final bytesPerRow = hexEditorService.bytesPerRow;
    final rowCount1 = (_file1Bytes!.length / bytesPerRow).ceil();
    final rowCount2 = (_file2Bytes!.length / bytesPerRow).ceil();
    
    return Row(
      children: [
        // الملف الأول
        Expanded(
          child: Scrollbar(
            controller: _scrollController1,
            thumbVisibility: true,
            child: ListView.builder(
              controller: _scrollController1,
              itemCount: rowCount1,
              itemBuilder: (context, rowIndex) {
                final startOffset = rowIndex * bytesPerRow;
                final endOffset = (startOffset + bytesPerRow) > _file1Bytes!.length
                    ? _file1Bytes!.length
                    : startOffset + bytesPerRow;
                final rowBytes = _file1Bytes!.sublist(startOffset, endOffset);
                
                return _buildHexRow(
                  rowIndex,
                  startOffset,
                  rowBytes,
                  hexEditorService,
                  isDifferent: _isComparing
                      ? _checkRowForDifferences(startOffset, rowBytes, 1)
                      : false,
                );
              },
            ),
          ),
        ),
        
        // خط فاصل
        Container(
          width: 1,
          color: AppColors.mediumGray,
        ),
        
        // الملف الثاني
        Expanded(
          child: Scrollbar(
            controller: _scrollController2,
            thumbVisibility: true,
            child: ListView.builder(
              controller: _scrollController2,
              itemCount: rowCount2,
              itemBuilder: (context, rowIndex) {
                final startOffset = rowIndex * bytesPerRow;
                final endOffset = (startOffset + bytesPerRow) > _file2Bytes!.length
                    ? _file2Bytes!.length
                    : startOffset + bytesPerRow;
                final rowBytes = _file2Bytes!.sublist(startOffset, endOffset);
                
                return _buildHexRow(
                  rowIndex,
                  startOffset,
                  rowBytes,
                  hexEditorService,
                  isDifferent: _isComparing
                      ? _checkRowForDifferences(startOffset, rowBytes, 2)
                      : false,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildHexRow(
    int rowIndex,
    int startOffset,
    List<int> rowBytes,
    EnhancedHexEditorService hexEditorService, {
    bool isDifferent = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      color: isDifferent
          ? AppColors.deepPurple.withOpacity(0.2)
          : rowIndex % 2 == 0
              ? AppColors.darkGray
              : AppColors.darkGrayLight,
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
                final isDiffByte = _isComparing && _differences.contains(byteOffset);
                
                return Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isDiffByte
                        ? AppColors.modifiedByteColor.withOpacity(0.5)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      hexEditorService.byteToHex(byte),
                      style: TextStyle(
                        color: isDiffByte ? Colors.white : AppColors.hexValueColor,
                        fontFamily: 'monospace',
                        fontWeight: isDiffByte ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
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
            width: 80,
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
  
  Future<void> _selectFile1() async {
    final fileService = Provider.of<EnhancedFileService>(context, listen: false);
    final result = await fileService.openLocalFile();
    
    if (result) {
      setState(() {
        _file1 = fileService.currentFile;
        _file1Bytes = List.from(fileService.fileBytes!);
        _isComparing = false;
        _differences = [];
      });
    }
  }
  
  Future<void> _selectFile2() async {
    final fileService = Provider.of<EnhancedFileService>(context, listen: false);
    final result = await fileService.openLocalFile();
    
    if (result) {
      setState(() {
        _file2 = fileService.currentFile;
        _file2Bytes = List.from(fileService.fileBytes!);
        _isComparing = false;
        _differences = [];
      });
    }
  }
  
  void _compareFiles() {
    if (_file1Bytes == null || _file2Bytes == null) return;
    
    setState(() {
      _isComparing = true;
      _differences = [];
      _currentDiffIndex = -1;
    });
    
    // مقارنة البايتات
    final minLength = _file1Bytes!.length < _file2Bytes!.length
        ? _file1Bytes!.length
        : _file2Bytes!.length;
    
    for (int i = 0; i < minLength; i++) {
      if (_file1Bytes![i] != _file2Bytes![i]) {
        _differences.add(i);
      }
    }
    
    // إذا كان أحد الملفين أطول من الآخر، اعتبر البايتات الإضافية اختلافات
    if (_file1Bytes!.length != _file2Bytes!.length) {
      final maxLength = _file1Bytes!.length > _file2Bytes!.length
          ? _file1Bytes!.length
          : _file2Bytes!.length;
      
      for (int i = minLength; i < maxLength; i++) {
        _differences.add(i);
      }
    }
    
    if (_differences.isNotEmpty) {
      _navigateToDifference(0);
    }
  }
  
  bool _checkRowForDifferences(int startOffset, List<int> rowBytes, int fileIndex) {
    for (int i = 0; i < rowBytes.length; i++) {
      final byteOffset = startOffset + i;
      if (_differences.contains(byteOffset)) {
        return true;
      }
    }
    return false;
  }
  
  void _navigateToDifference(int diffIndex) {
    if (diffIndex < 0 || diffIndex >= _differences.length) return;
    
    setState(() {
      _currentDiffIndex = diffIndex;
    });
    
    final hexEditorService = Provider.of<EnhancedHexEditorService>(context, listen: false);
    final bytesPerRow = hexEditorService.bytesPerRow;
    final offset = _differences[diffIndex];
    final rowIndex = (offset / bytesPerRow).floor();
    
    final itemHeight = 28.0; // تقدير تقريبي لارتفاع الصف
    _scrollController1.animateTo(
      rowIndex * itemHeight,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    _scrollController2.animateTo(
      rowIndex * itemHeight,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
