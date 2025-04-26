import 'package:flutter/material.dart';
import 'package:by_hex/constants/app_colors.dart';
import 'package:by_hex/services/hex_editor_service.dart';
import 'package:by_hex/services/file_service.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

class UpdatedHexEditorScreen extends StatefulWidget {
  const UpdatedHexEditorScreen({super.key});

  @override
  State<UpdatedHexEditorScreen> createState() => _UpdatedHexEditorScreenState();
}

class _UpdatedHexEditorScreenState extends State<UpdatedHexEditorScreen> {
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
        title: const Text('By Hex'),
        backgroundColor: const Color(0xFFE1BEE7), // لون بنفسجي فاتح
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
      body: Column(
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
      bottomNavigationBar: fileService.fileBytes != null
          ? _buildBottomBar(fileService, hexEditorService)
          : null,
    );
  }
  
  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _openFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBA68C8),
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
          ],
        ),
      ),
    );
  }
  
  Widget _buildFileHeader(FileService fileService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.black,
      child: Text(
        'File: ${fileService.currentFile?.name ?? ""}',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 16,
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
      padding: const EdgeInsets.symmetric(vertical: 2),
      color: Colors.black,
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
                              ? AppColors.mediumPurple.withOpacity(0.3)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        hexEditorService.byteToHex(byte),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
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
                  color: Colors.white70,
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
                style: const TextStyle(
                  color: Colors.grey,
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
  
  Widget _buildBottomBar(FileService fileService, HexEditorService hexEditorService) {
    return Container(
      height: 56,
      color: const Color(0xFF7B1FA2), // لون بنفسجي غامق
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              _showSearchDialog(hexEditorService, fileService);
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.white),
            onPressed: () {
              _showMoreOptionsDialog(hexEditorService);
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_upward, color: Colors.white),
            onPressed: () {
              _scrollToPosition(0);
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_downward, color: Colors.white),
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
  
  Future<void> _openFile() async {
    final fileService = Provider.of<FileService>(context, listen: false);
    final result = await fileService.openLocalFile();
    
    if (result && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم فتح الملف: ${fileService.currentFile?.name}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  void _showSearchDialog(HexEditorService hexEditorService, FileService fileService) {
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
                    activeColor: const Color(0xFF7B1FA2),
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
                    activeColor: const Color(0xFF7B1FA2),
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
                foregroundColor: const Color(0xFF7B1FA2),
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
                backgroundColor: const Color(0xFF7B1FA2),
              ),
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }
  
  void _showMoreOptionsDialog(HexEditorService hexEditorService) {
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
                  foregroundColor: const Color(0xFF7B1FA2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: const BorderSide(color: Color(0xFF7B1FA2)),
                  ),
                ),
                child: const Text('File to Start of File'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  final fileService = Provider.of<FileService>(context, listen: false);
                  if (fileService.fileBytes != null) {
                    final bytesPerRow = hexEditorService.bytesPerRow;
                    final rowCount = (fileService.fileBytes!.length / bytesPerRow).ceil();
                    _scrollToPosition(rowCount - 1);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF7B1FA2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: const BorderSide(color: Color(0xFF7B1FA2)),
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
                foregroundColor: const Color(0xFF7B1FA2),
              ),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
