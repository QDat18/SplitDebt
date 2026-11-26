// Trách nhiệm file: Màn hình debug (chỉ hiện khi kDebugMode) giúp quét thử ML Kit trên hoá đơn thật và sao chép các dòng rows.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import 'receipt_scanner.dart';

class ReceiptOcrLabScreen extends StatefulWidget {
  const ReceiptOcrLabScreen({super.key});

  @override
  State<ReceiptOcrLabScreen> createState() => _ReceiptOcrLabScreenState();
}

class _ReceiptOcrLabScreenState extends State<ReceiptOcrLabScreen> {
  final _scanner = ReceiptScanner();
  List<String> _rows = const [];
  bool _scanning = false;
  String? _status;

  Future<void> _scan(ImageSource source) async {
    setState(() {
      _scanning = true;
      _status = null;
    });
    try {
      final rows = await _scanner.scan(source);
      if (!mounted) return;
      if (rows == null) {
        setState(() => _scanning = false);
        return;
      }
      for (var i = 0; i < rows.length; i++) {
        debugPrint('[OCR_LAB] $i: ${rows[i]}');
      }
      setState(() {
        _rows = rows;
        _scanning = false;
        _status = rows.isEmpty
            ? 'Không đọc được chữ nào trên ảnh.'
            : 'Đã đọc ${rows.length} dòng.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _status = 'Lỗi quét: $e';
      });
    }
  }

  Future<void> _copyRows() async {
    if (_rows.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _rows.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép các dòng OCR.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(kDebugMode, 'ReceiptOcrLabScreen chỉ dùng trong chế độ debug.');
    return Scaffold(
      backgroundColor: AppColors.n100,
      appBar: AppBar(
        title: const Text('OCR Lab (Debug)'),
        backgroundColor: AppColors.n100,
        elevation: 0,
        actions: [
          if (_rows.isNotEmpty)
            TextButton.icon(
              onPressed: _copyRows,
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Sao chép'),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _scanning ? null : () => _scan(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Chụp ảnh'),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.s12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          _scanning ? null : () => _scan(ImageSource.gallery),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.p500,
                        foregroundColor: AppColors.n0,
                      ),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Chọn ảnh'),
                    ),
                  ),
                ],
              ),
              if (_scanning) ...[
                const SizedBox(height: AppDimensions.s16),
                const Center(child: CircularProgressIndicator.adaptive()),
              ],
              if (_status != null) ...[
                const SizedBox(height: AppDimensions.s12),
                Text(
                  _status!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.n600),
                ),
              ],
              const SizedBox(height: AppDimensions.s12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.s12),
                  decoration: BoxDecoration(
                    color: AppColors.n0,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _rows.isEmpty
                      ? const Center(
                          child: Text(
                            'Chụp hoặc chọn ảnh hoá đơn để xem kết quả từng dòng.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _rows.length,
                          itemBuilder: (_, idx) => SelectableText(
                            '${idx + 1}. ${_rows[idx]}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
