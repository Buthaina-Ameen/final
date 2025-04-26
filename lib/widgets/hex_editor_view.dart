import 'package:flutter/material.dart';
import 'package:by_hex/constants/app_colors.dart';
import 'package:by_hex/services/file_service.dart';
import 'package:by_hex/services/hex_editor_service.dart';
import 'package:provider/provider.dart';
import 'package:by_hex/widgets/byte_editor_widget.dart';

class HexEditorView extends StatefulWidget {
  const HexEditorView({super.key});

  @override
  State<HexEditorView> createState() => _HexEditorViewState();
}

class _HexEditorViewState extends State<HexEditorView> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final fileService = Provider.of<FileService>(context);
    final hexEditorService = Provider.of<HexEditorService>(context);
    
    if (fileService.fileBytes == null) {
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
              spacing: 8,
              runSpacing: 8,
              children: List.generate(rowBytes.length, (index) {
                final byteOffset = startOffset + index;
                final byte = rowBytes[index];
                final isSelected = hexEditorService.selectedOffset == byteOffset;
                final isSearchResult = hexEditorService.searchResults.contains(byteOffset);
                
                return Container(
                  decoration: BoxDecoration(
                    color: isSearchResult && !isSelected
                        ? AppColors.mediumPurple.withOpacity(0.3)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ByteEditorWidget(
                    offset: byteOffset,
                    value: byte,
                    isSelected: isSelected,
                    onTap: () {
                      hexEditorService.selectByte(byteOffset);
                    },
                    onValueChanged: (newValue) {
                      hexEditorService.updateSelectedByte(newValue, fileService);
                    },
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
}
