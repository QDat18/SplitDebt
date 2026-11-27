import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'receipt_data.dart';
import 'receipt_ocr_native.dart'
    if (dart.library.js_interop) 'receipt_ocr_web.dart'
    as ocr;

class ReceiptQrScanner extends StatefulWidget {
  const ReceiptQrScanner({super.key});
  @override
  State<ReceiptQrScanner> createState() => _ReceiptQrScannerState();
}

class _ReceiptQrScannerState extends State<ReceiptQrScanner>
    with WidgetsBindingObserver {
  final _controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _done = false, _importing = false, _dialogOpen = false;
  String? _message, _lastRejected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.hasCameraPermission || _done) return;
    if (state == AppLifecycleState.resumed && !_dialogOpen && !_importing) {
      unawaited(_restart());
    } else if (state == AppLifecycleState.inactive) {
      unawaited(_stopCamera());
    }
  }

  Future<void> _stopCamera() async {
    try {
      await _controller.stop();
    } catch (_) {
      // Image import and pasted content remain available if camera cleanup fails.
    }
  }

  Future<void> _restart() async {
    try {
      await _controller.start();
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Chưa mở được camera. Hãy cấp quyền camera hoặc chọn ảnh QR.',
        );
      }
    }
  }

  bool _accept(String raw) {
    if (!mounted || _done) return false;
    try {
      parseReceiptQr(raw);
      _done = true;
      unawaited(_stopCamera());
      Navigator.pop(context, raw);
      return true;
    } on FormatException catch (error) {
      if (raw != _lastRejected || _message == null) {
        _lastRejected = raw;
        setState(() => _message = error.message);
      }
      return false;
    }
  }

  Future<void> _pickImage() async {
    if (_importing || _done) return;
    setState(() {
      _importing = true;
      _message = null;
    });
    try {
      await _stopCamera();
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 4096,
        maxHeight: 4096,
        imageQuality: 100,
      );
      if (file == null || !mounted) return;
      if (await file.length() > 8 * 1024 * 1024) {
        throw const FormatException('Chọn ảnh QR nhỏ hơn 8 MB.');
      }
      if (!mounted) return;
      final values = <String>[];
      if (kIsWeb) {
        final value = await ocr.decodeReceiptQrImage(await file.readAsBytes());
        if (value != null) values.add(value);
      } else {
        final capture = await _controller.analyzeImage(
          file.path,
          formats: [BarcodeFormat.qrCode],
        );
        values.addAll(
          capture?.barcodes.map((b) => b.rawValue).whereType<String>() ??
              <String>[],
        );
      }
      if (!mounted) return;
      for (final value in values) {
        if (_accept(value)) return;
      }
      if (values.isEmpty) {
        setState(
          () => _message =
              'Chưa tìm thấy QR trong ảnh. Chọn ảnh rõ nét, đầy đủ bốn góc của mã.',
        );
      }
    } on FormatException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Chưa đọc được ảnh QR. Thử ảnh khác hoặc dán nội dung QR.',
        );
      }
    } finally {
      if (mounted && !_done) {
        setState(() => _importing = false);
        await _restart();
      }
    }
  }

  Future<void> _paste() async {
    if (_done || _importing) return;
    _dialogOpen = true;
    await _stopCamera();
    if (!mounted) return;
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dán nội dung QR'),
        scrollable: true,
        content: SizedBox(
          width: 480,
          child: TextField(
            controller: controller,
            autofocus: true,
            minLines: 3,
            maxLines: 8,
            maxLength: 24000,
            decoration: const InputDecoration(
              labelText: 'Nội dung mã QR',
              hintText: 'Dán dữ liệu bạn đã sao chép từ mã QR',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Kiểm tra QR'),
          ),
        ],
      ),
    );
    // The dialog's closing animation may still reference its controller.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.dispose();
    if (!mounted) return;
    _dialogOpen = false;
    if (value != null && _accept(value)) return;
    await _restart();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Quét QR hóa đơn')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                children: [
                  Text(
                    'Đặt trọn mã QR vào khung',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Giữ máy ổn định, tránh lóa sáng. Bạn cũng có thể chọn ảnh QR có sẵn.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: MobileScanner(
                    controller: _controller,
                    fit: BoxFit.contain,
                    onDetect: (capture) {
                      if (_done || _importing || _dialogOpen) return;
                      // Try all visible QR codes: a payment QR may sit beside an invoice QR.
                      for (final barcode in capture.barcodes) {
                        final raw = barcode.rawValue;
                        if (raw != null && raw.isNotEmpty && _accept(raw)) {
                          return;
                        }
                      }
                    },
                    placeholderBuilder: (_, __) => const ColoredBox(
                      color: Color(0xFF111827),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                    errorBuilder: (_, error, __) => ColoredBox(
                      color: colors.surfaceContainerHighest,
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.no_photography_outlined,
                                size: 48,
                                color: colors.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Chưa truy cập được camera',
                                style: Theme.of(context).textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Cho phép camera trong cài đặt ứng dụng hoặc trình duyệt. Nếu camera đang bận, hãy đóng ứng dụng khác rồi thử lại.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: _restart,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Thử mở camera'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    overlayBuilder: (_, constraints) => IgnorePointer(
                      child: Center(
                        child: Container(
                          width: constraints.maxWidth * .72,
                          height: constraints.maxHeight * .72,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 3),
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Semantics(
                  liveRegion: true,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _message!,
                      style: TextStyle(color: colors.onErrorContainer),
                    ),
                  ),
                ),
              ),
            if (_importing)
              const Padding(
                padding: EdgeInsets.all(12),
                child: LinearProgressIndicator(),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: _importing ? null : _pickImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Chọn ảnh QR'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _importing ? null : _paste,
                    icon: const Icon(Icons.content_paste),
                    label: const Text('Dán nội dung'),
                  ),
                  ValueListenableBuilder<MobileScannerState>(
                    valueListenable: _controller,
                    builder: (_, value, __) => IconButton.filledTonal(
                      tooltip: value.torchState == TorchState.on
                          ? 'Tắt đèn pin'
                          : 'Bật đèn pin',
                      onPressed:
                          value.torchState == TorchState.unavailable ||
                              _importing
                          ? null
                          : () async {
                              try {
                                await _controller.toggleTorch();
                              } catch (_) {
                                if (mounted) {
                                  setState(
                                    () => _message =
                                        'Thiết bị này chưa hỗ trợ đèn pin.',
                                  );
                                }
                              }
                            },
                      icon: Icon(
                        value.torchState == TorchState.on
                            ? Icons.flash_on
                            : Icons.flash_off,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
