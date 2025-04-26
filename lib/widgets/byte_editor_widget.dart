import 'package:flutter/material.dart';
import 'package:by_hex/constants/app_colors.dart';
import 'package:by_hex/services/file_service.dart';
import 'package:provider/provider.dart';
import 'package:by_hex/screens/hex_editor_screen.dart';
import 'package:by_hex/screens/file_compare_screen.dart';

class ByteEditorWidget extends StatefulWidget {
  final int offset;
  final int value;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(int) onValueChanged;

  const ByteEditorWidget({
    super.key,
    required this.offset,
    required this.value,
    required this.isSelected,
    required this.onTap,
    required this.onValueChanged,
  });

  @override
  State<ByteEditorWidget> createState() => _ByteEditorWidgetState();
}

class _ByteEditorWidgetState extends State<ByteEditorWidget> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatHex(widget.value));
  }

  @override
  void didUpdateWidget(ByteEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_isEditing) {
      _controller.text = _formatHex(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatHex(int value) {
    return value.toRadixString(16).padLeft(2, '0').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onTap();
        if (widget.isSelected && !_isEditing) {
          setState(() {
            _isEditing = true;
          });
          // تأخير قصير للسماح بتحديث واجهة المستخدم قبل التركيز
          Future.delayed(const Duration(milliseconds: 50), () {
            FocusScope.of(context).requestFocus(FocusNode());
          });
        }
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: widget.isSelected
              ? AppColors.selectedByteColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: widget.isSelected
                ? AppColors.deepPurple
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: _isEditing && widget.isSelected
            ? TextField(
                controller: _controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.text,
                maxLength: 2,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (value) {
                  try {
                    final intValue = int.parse(value, radix: 16);
                    if (intValue >= 0 && intValue <= 255) {
                      widget.onValueChanged(intValue);
                    }
                  } catch (e) {
                    // إذا كان الإدخال غير صالح، أعد تعيين القيمة
                    _controller.text = _formatHex(widget.value);
                  }
                  setState(() {
                    _isEditing = false;
                  });
                },
                onTapOutside: (_) {
                  setState(() {
                    _isEditing = false;
                    _controller.text = _formatHex(widget.value);
                  });
                },
              )
            : Center(
                child: Text(
                  _formatHex(widget.value),
                  style: TextStyle(
                    color: AppColors.hexValueColor,
                    fontFamily: 'monospace',
                    fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
      ),
    );
  }
}
