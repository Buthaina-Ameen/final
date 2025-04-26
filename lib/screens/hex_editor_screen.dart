import 'package:flutter/material.dart';
import 'package:by_hex/constants/app_colors.dart';
import 'package:by_hex/services/hex_editor_service.dart';
import 'package:by_hex/services/file_service.dart';
import 'package:provider/provider.dart';

class HexEditorScreen extends StatefulWidget {
  const HexEditorScreen({super.key});

  @override
  State<HexEditorScreen> createState() => _HexEditorScreenState();
}

class _HexEditorScreenState extends State<HexEditorScreen> {
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
    final fileService = Provider.of<FileService>(context);
    final hexEditorService = Provider.of<HexEditorService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(fileService.currentFile?.name ?? 'محرر Hex'),
        backgroundColor: AppColors.darkGrayLight,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog(context, hexEditorService, fileService);
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: fileService.isModified ? () async {
              final result = await fileService.saveCurrentFile();
              if (result && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حفظ الملف بنجاح')),
                );
              }
            } : null,
          ),
        ],
      ),
      body: fileService.fileBytes == null
          ? _buildEmptyState()
          : _buildHexEditor(fileService, hexEditorService),
      bottomNavigationBar: fileService.fileBytes != null
          ? _buildStatusBar(fileService, hexEditorService)
          : null,
    );
  }
  
  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'لم يتم فتح أي ملف',
        style: TextStyle(
          fontSize: 18,
          color: Colors.white70,
        ),
      ),
    );
  }
  
  Widget _buildHexEditor(FileService fileService, HexEditorService hexEditorService) {
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
    HexEditorService hexEditorService,
    FileService fileService,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      color: rowIndex % 2 == 0 ? AppColors.darkGray : AppColors.darkGrayLight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عرض الإزاحة
          SizedBox(
            width: 100,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '0x${startOffset.toRadixString(16).padLeft(8, '0').toUpperCase()}',
                style: const TextStyle(
                  color: AppColors.offsetColor,
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),
          ),
          
          // عرض قيم Hex
          Expanded(
            flex: 3,
            child: Wrap(
              spacing: 12,
              children: List.generate(rowBytes.length, (index) {
                final byteOffset = startOffset + index;
                final byte = rowBytes[index];
                final isSelected = hexEditorService.selectedOffset == byteOffset;
                final isSearchResult = hexEditorService.searchResults.contains(byteOffset);
                
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
                          : isSearchResult
                              ? AppColors.mediumPurple.withOpacity(0.5)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        hexEditorService.byteToHex(byte),
                        style: TextStyle(
                          color: fileService.isModified && fileService.currentFile != null
                              ? AppColors.modifiedByteColor
                              : AppColors.hexValueColor,
                          fontFamily: 'monospace',
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                style: const TextStyle(
                  color: AppColors.asciiValueColor,
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
  
  Widget _buildStatusBar(FileService fileService, HexEditorService hexEditorService) {
    final selectedOffset = hexEditorService.selectedOffset;
    final selectedByte = selectedOffset != null && fileService.fileBytes != null && selectedOffset < fileService.fileBytes!.length
        ? fileService.fileBytes![selectedOffset]
        : null;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.darkGrayLight,
      child: Row(
        children: [
          // عرض معلومات الملف
          Text(
            'الحجم: ${fileService.currentFile?.size ?? 0} بايت',
            style: const TextStyle(color: Colors.white70),
          ),
          const Spacer(),
          
          // عرض معلومات البايت المحدد
          if (selectedOffset != null && selectedByte != null)
            Text(
              'الإزاحة: 0x${selectedOffset.toRadixString(16).toUpperCase()} | '
              'القيمة: ${hexEditorService.byteToHex(selectedByte)} | '
              'ASCII: ${hexEditorService.byteToAscii(selectedByte)}',
              style: const TextStyle(color: Colors.white70),
            ),
        ],
      ),
    );
  }
  
  void _showSearchDialog(
    BuildContext context,
    HexEditorService hexEditorService,
    FileService fileService,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.darkGrayLight,
          title: const Text(
            'بحث',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'أدخل قيمة البحث',
                  labelStyle: TextStyle(color: AppColors.lightPurple),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.mediumPurple),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.deepPurple, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text(
                        'Hex',
                        style: TextStyle(color: Colors.white),
                      ),
                      value: true,
                      groupValue: _isHexSearch,
                      activeColor: AppColors.mediumPurple,
                      onChanged: (value) {
                        setState(() {
                          _isHexSearch = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text(
                        'نص',
                        style: TextStyle(color: Colors.white),
                      ),
                      value: false,
                      groupValue: _isHexSearch,
                      activeColor: AppColors.mediumPurple,
                      onChanged: (value) {
                        setState(() {
                          _isHexSearch = value!;
                        });
                      },
                    ),
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
              child: const Text(
                'إلغاء',
                style: TextStyle(color: AppColors.lightPurple),
              ),
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
                      const SnackBar(content: Text('لم يتم العثور على نتائج')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم العثور على ${hexEditorService.searchResults.length} نتيجة',
                        ),
                        action: SnackBarAction(
                          label: 'التالي',
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
                backgroundColor: AppColors.mediumPurple,
              ),
              child: const Text('بحث'),
            ),
          ],
        );
      },
    );
  }
}
