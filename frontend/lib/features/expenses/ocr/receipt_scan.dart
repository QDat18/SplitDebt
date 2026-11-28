import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/network_error.dart';
import 'receipt_data.dart';
import 'receipt_print.dart';
import 'receipt_qr_camera.dart';
import 'receipt_ocr_native.dart'
    if (dart.library.js_interop) 'receipt_ocr_web.dart'
    as ocr;
export 'receipt_data.dart' show ReceiptDraft, ReceiptLine;

Future<ReceiptDraft?> scanReceipt(
  BuildContext context, {
  bool qr = false,
}) async {
  if (qr) {
    final raw = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const ReceiptQrScanner()));
    if (raw == null || !context.mounted) return null;
    try {
      final data = parseReceiptQr(raw);
      return await showDialog<ReceiptDraft>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _ReceiptReview(data: data, source: 'QR'),
      );
    } on FormatException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
      return null;
    }
  }
  final choice = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.document_scanner_outlined,
                color: Theme.of(ctx).colorScheme.primary,
              ),
              title: const Text('Thêm hóa đơn từ ảnh'),
              subtitle: const Text(
                'Chụp đủ hóa đơn, giữ máy thẳng và tránh bóng, lóa. Bạn sẽ kiểm tra dữ liệu trước khi sử dụng.',
              ),
            ),
            if (!kIsWeb &&
                (defaultTargetPlatform == TargetPlatform.android ||
                    defaultTargetPlatform == TargetPlatform.iOS))
              ListTile(
                minVerticalPadding: 16,
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Chụp hóa đơn'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ListTile(
              minVerticalPadding: 16,
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn ảnh hóa đơn'),
              subtitle: const Text('Ảnh rõ nét, tối đa 8 MB'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    ),
  );
  if (choice == null || !context.mounted) return null;
  try {
    // Preserve tall receipts; reducing every photograph to a 2800px square made
    // small price digits on long supermarket receipts unreadable.
    final file = await ImagePicker().pickImage(
      source: choice,
      maxWidth: 4096,
      maxHeight: 8192,
      imageQuality: 95,
    );
    if (file == null || !context.mounted) return null;
    if (await file.length() > 8 * 1024 * 1024) {
      throw const FormatException(
        'Ảnh vượt quá 8 MB. Hãy chọn ảnh nhẹ hơn hoặc chụp lại gần hóa đơn.',
      );
    }
    final bytes = await file.readAsBytes();
    if (!context.mounted) return null;
    return await showDialog<ReceiptDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _ReceiptReview(bytes: bytes, path: file.path, source: 'Ảnh hóa đơn'),
    );
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is FormatException
                ? error.message
                : 'Chưa mở được ảnh. Hãy cấp quyền camera hoặc thư viện ảnh rồi thử lại.',
          ),
        ),
      );
    }
    return null;
  }
}

Future<ReceiptDraft?> reviewReceipt(BuildContext context, ReceiptDraft draft) =>
    showDialog<ReceiptDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ReceiptReview(
        source: draft.source,
        data: {
          'total': draft.total,
          'date': draft.date.toIso8601String().substring(0, 10),
          'merchant': draft.merchant,
          'items': draft.items
              .map(
                (i) => {
                  'name': i.name,
                  'quantity': i.quantity,
                  'unitPrice': i.unitPrice,
                  'amount': i.amount,
                },
              )
              .toList(),
        },
      ),
    );

class _EditableLine {
  final name = TextEditingController(),
      quantity = TextEditingController(),
      unit = TextEditingController();
  _EditableLine(Map? data) {
    name.text = data?['name']?.toString() ?? '';
    quantity.text = data?['quantity']?.toString() ?? '';
    unit.text = data?['unitPrice']?.toString() ?? '';
  }
  int get amount =>
      (int.tryParse(quantity.text) ?? 0) * (int.tryParse(unit.text) ?? 0);
  ReceiptLine get value => ReceiptLine(
    name.text.trim(),
    int.parse(quantity.text),
    int.parse(unit.text),
  );
  void dispose() {
    name.dispose();
    quantity.dispose();
    unit.dispose();
  }
}

class _ReceiptReview extends StatefulWidget {
  final Uint8List? bytes;
  final String? path;
  final Map<String, dynamic>? data;
  final String source;
  const _ReceiptReview({
    this.bytes,
    this.path,
    this.data,
    required this.source,
  });
  @override
  State<_ReceiptReview> createState() => _ReceiptReviewState();
}

class _ReceiptReviewState extends State<_ReceiptReview> {
  final _total = TextEditingController(), _merchant = TextEditingController();
  final _form = GlobalKey<FormState>();
  CancelToken _cancel = CancelToken();
  final _lines = <_EditableLine>[], _retired = <_EditableLine>[];
  final _detected = <int?>[];
  final _money = NumberFormat.decimalPattern('vi_VN');
  DateTime? _date;
  int? _tax, _discount, _surcharge;
  String? _error;
  String _raw = '', _progress = '', _notice = '';
  List<String> _warnings = [];
  bool _busy = false, _ready = false, _printing = false, _reviewed = false;
  int _generation = 0;
  final _candidates = <Map<String, dynamic>>[];
  bool get _locked => _busy || _printing;

  bool _uncertain(Map<String, dynamic> data) {
    final total = data['total'], items = data['items'];
    if (total is! num ||
        total <= 0 ||
        data['date'] == null ||
        items is! List ||
        items.isEmpty ||
        (data['warnings'] as List? ?? []).isNotEmpty) {
      return true;
    }
    num sum = 0;
    for (final item in items) {
      if (item is! Map) return true;
      final q = item['quantity'], u = item['unitPrice'], a = item['amount'];
      if (q is! num ||
          u is! num ||
          a is! num ||
          q <= 0 ||
          u <= 0 ||
          q * u != a) {
        return true;
      }
      sum += a;
    }
    return sum != total;
  }

  Map<String, dynamic> _result(Map<String, dynamic> candidate) =>
      Map<String, dynamic>.from(candidate['result'] as Map);
  bool _current(int generation) => mounted && generation == _generation;

  Future<List<Map<String, dynamic>>> _advanced(String mode) async {
    final response = await dioClient.post(
      '/v1/receipts/advanced',
      data: FormData.fromMap({
        'image': MultipartFile.fromBytes(
          widget.bytes!,
          filename: 'receipt.jpg',
        ),
        'mode': mode,
      }),
      options: Options(
        receiveTimeout: const Duration(seconds: 160),
        sendTimeout: const Duration(seconds: 30),
      ),
      cancelToken: _cancel,
    );
    return (response.data['data'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> _chooseCandidate() async {
    if (_locked || _candidates.isEmpty) return;
    final chosen = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đối chiếu kết quả'),
        scrollable: true,
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Chọn kết quả gần với hóa đơn gốc nhất. Dữ liệu bạn đang chỉnh sửa sẽ được thay bằng kết quả đã chọn.',
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < _candidates.length; i++)
                Card(
                  child: ListTile(
                    title: Text('Lần nhận dạng ${i + 1}'),
                    subtitle: Text(
                      'Tổng: ${_result(_candidates[i])['total'] == null ? 'Chưa rõ' : '${_money.format(_result(_candidates[i])['total'])} đ'} · ${(_result(_candidates[i])['items'] as List? ?? []).length} dòng\n${_uncertain(_result(_candidates[i])) ? 'Có thông tin cần kiểm tra' : 'Tổng dòng hàng khớp tổng thanh toán'}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pop(ctx, i),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Giữ dữ liệu hiện tại'),
          ),
        ],
      ),
    );
    if (!mounted || chosen == null) return;
    setState(() {
      _apply(_result(_candidates[chosen]));
      _error = null;
    });
  }

  void _stopEnhancing() {
    _generation++;
    _cancel.cancel('User chose to review the available result.');
    _cancel = CancelToken();
    setState(() {
      _busy = false;
      _notice =
          'Đã dừng nhận dạng bổ sung. Bạn có thể kiểm tra và sửa dữ liệu đã đọc được.';
    });
  }

  Future<void> _requestStructure() async {
    if (_locked || widget.bytes == null) return;
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _progress = 'Đang đọc kỹ bố cục và các cột trên hóa đơn…';
      _notice = '';
    });
    try {
      final alternatives = await _advanced('structure');
      if (!_current(generation)) return;
      setState(() {
        _candidates.removeWhere(
          (c) => alternatives.any((a) => a['source'] == c['source']),
        );
        _candidates.addAll(alternatives);
        _notice = alternatives.isEmpty
            ? 'Chưa tìm được kết quả bổ sung. Bạn có thể sửa dữ liệu hoặc chọn ảnh rõ hơn.'
            : 'Đã có kết quả bổ sung. Chọn Đối chiếu kết quả để xem.';
        if (!_ready && alternatives.isNotEmpty) {
          _apply(_result(alternatives.first));
          _error = null;
        }
      });
    } catch (_) {
      if (_current(generation)) {
        setState(
          () => _notice =
              'Chưa đọc được bố cục nâng cao. Hãy kiểm tra dữ liệu hiện có hoặc thử ảnh rõ hơn.',
        );
      }
    } finally {
      if (_current(generation)) setState(() => _busy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      _apply(widget.data!);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scan();
      });
    }
  }

  void _apply(Map<String, dynamic> data) {
    _retired.addAll(_lines);
    _lines.clear();
    _detected.clear();
    _total.text = data['total']?.toString() ?? '';
    final merchant = data['merchant']?.toString() ?? '';
    _merchant.text = merchant.length > 160
        ? merchant.substring(0, 160)
        : merchant;
    final rawDate = data['date']?.toString() ?? '';
    final d = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(rawDate)
        ? DateTime.tryParse(rawDate)
        : null;
    _date =
        d != null &&
            d.year >= 2000 &&
            d.year <= DateTime.now().year + 1 &&
            DateFormat('yyyy-MM-dd').format(d) == rawDate
        ? d
        : null;
    _raw = data['text']?.toString() ?? '';
    _tax = (data['tax'] as num?)?.toInt();
    _discount = (data['discount'] as num?)?.toInt();
    _surcharge = ((data['surcharge'] ?? data['serviceFee']) as num?)?.toInt();
    _warnings = (data['warnings'] as List? ?? [])
        .map((e) => e.toString())
        .toSet()
        .toList();
    for (final item in (data['items'] as List? ?? []).whereType<Map>().take(
      100,
    )) {
      _lines.add(_EditableLine(item));
      _detected.add((item['amount'] as num?)?.toInt());
    }
    _reviewed = false;
    _ready = true;
  }

  void _addCandidate(String source, Map<String, dynamic> data) {
    _candidates.add({'source': source, 'result': data});
    if (!_ready) setState(() => _apply(data));
  }

  Future<void> _scan() async {
    if (_locked || widget.bytes == null || widget.path == null) return;
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _ready = false;
      _error = null;
      _notice = '';
      _progress = 'Đang đọc chữ và số trên hóa đơn…';
      _candidates.clear();
    });
    try {
      try {
        final recognized = await ocr
            .recognizeReceipt(widget.bytes!, widget.path!)
            .timeout(const Duration(seconds: 90));
        if (!_current(generation)) return;
        Map<String, dynamic> payload;
        try {
          final decoded = jsonDecode(recognized);
          payload = decoded is Map
              ? Map<String, dynamic>.from(decoded)
              : {'text': recognized, 'words': <Object>[]};
        } on FormatException {
          payload = {'text': recognized, 'words': <Object>[]};
        }
        final text = payload['text']?.toString() ?? '';
        if (text.trim().isEmpty || text.length > 24000) {
          throw const FormatException('Không đọc được chữ.');
        }
        final response = await dioClient.post(
          '/v1/receipts/parse',
          data: payload,
          cancelToken: _cancel,
        );
        if (!_current(generation)) return;
        _addCandidate(
          'device',
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      } on DioException catch (error) {
        if (!_current(generation)) return;
        if (error.response == null ||
            [401, 403, 404].contains(error.response?.statusCode)) {
          setState(() => _error = networkErrorMessage(error));
          return;
        }
      } catch (_) {
        if (!_current(generation)) return;
      }
      if (_candidates.isEmpty || _uncertain(_result(_candidates.first))) {
        setState(() => _progress = 'Đang kiểm tra lại ảnh và các cột số tiền…');
        try {
          final response = await dioClient.post(
            '/v1/receipts/scan',
            data: FormData.fromMap({
              'image': MultipartFile.fromBytes(
                widget.bytes!,
                filename: 'receipt.jpg',
              ),
            }),
            options: Options(
              receiveTimeout: const Duration(seconds: 55),
              sendTimeout: const Duration(seconds: 30),
            ),
            cancelToken: _cancel,
          );
          if (!_current(generation)) return;
          _addCandidate(
            'photo',
            Map<String, dynamic>.from(response.data['data'] as Map),
          );
        } catch (_) {
          if (!_current(generation)) return;
        }
        if (_candidates.isEmpty ||
            _candidates.every((candidate) => _uncertain(_result(candidate)))) {
          setState(
            () => _progress = 'Đang nhận dạng bổ sung cho phần chưa rõ…',
          );
          try {
            final alternatives = await _advanced('ocr');
            if (!_current(generation)) return;
            for (final candidate in alternatives) {
              _addCandidate(candidate['source'].toString(), _result(candidate));
            }
          } catch (_) {
            if (!_current(generation)) return;
            _notice =
                'Chưa nhận dạng được thêm. Bạn có thể kiểm tra dữ liệu đã đọc hoặc nhập tay.';
          }
        }
      }
      if (!_current(generation)) return;
      if (_candidates.isEmpty) {
        setState(
          () => _error =
              'Chưa đọc được hóa đơn. Thử ảnh rõ hơn, đủ sáng hoặc nhập thông tin thủ công.',
        );
        return;
      }
      final preferred = _candidates.firstWhere(
        (c) => !_uncertain(_result(c)),
        orElse: () => _candidates.first,
      );
      setState(() {
        _apply(_result(preferred));
        if (_candidates.length > 1) {
          final selected = _result(preferred);
          final differs = _candidates.any((c) {
            final r = _result(c);
            return r['total'] != selected['total'] ||
                r['date'] != selected['date'] ||
                jsonEncode(r['items']) != jsonEncode(selected['items']);
          });
          if (differs) {
            _notice =
                'Các lần nhận dạng có thông tin khác nhau. Hãy đối chiếu kết quả với ảnh gốc trước khi xác nhận.';
          }
        }
      });
    } catch (_) {
      if (_current(generation)) {
        setState(
          () =>
              _error = 'Chưa đọc được hóa đơn. Hãy thử lại hoặc nhập thủ công.',
        );
      }
    } finally {
      if (_current(generation)) setState(() => _busy = false);
    }
  }

  void _manualEntry() {
    if (_busy) _stopEnhancing();
    setState(() {
      _apply({'items': <Object>[], 'warnings': <String>[]});
      _error = null;
      _notice = 'Nhập thông tin đúng theo hóa đơn gốc.';
    });
  }

  @override
  void dispose() {
    _generation++;
    _cancel.cancel();
    _total.dispose();
    _merchant.dispose();
    for (final line in [..._lines, ..._retired]) {
      line.dispose();
    }
    super.dispose();
  }

  String? _positive(String? text, int max) {
    final n = int.tryParse(text ?? '');
    return n == null || n <= 0 || n > max
        ? 'Nhập số lớn hơn 0, tối đa ${_money.format(max)}'
        : null;
  }

  ReceiptDraft? _draft() {
    if (!_ready || _form.currentState?.validate() != true) return null;
    if (_date == null) {
      setState(() => _error = 'Hãy chọn ngày chi trên hóa đơn.');
      return null;
    }
    if (_lines.any((l) => l.amount > 999999999999)) {
      setState(
        () => _error = 'Thành tiền một dòng vượt giới hạn. Hãy kiểm tra lại.',
      );
      return null;
    }
    final total = int.parse(_total.text);
    if (_lines.isNotEmpty &&
        _lines.fold<int>(0, (sum, line) => sum + line.amount) != total) {
      setState(
        () => _error =
            'Tổng dòng hàng chưa khớp tổng thanh toán. Hãy sửa chi tiết hoặc chọn Chỉ dùng tổng tiền.',
      );
      return null;
    }
    if (!_reviewed) {
      setState(
        () => _error = 'Hãy đánh dấu đã đối chiếu thông tin với hóa đơn gốc.',
      );
      return null;
    }
    return ReceiptDraft(
      total,
      _lines.map((l) => l.value).toList(),
      _date!,
      _merchant.text.trim(),
      widget.source,
    );
  }

  Future<void> _zoomOriginal() async {
    final bytes = widget.bytes;
    if (bytes == null) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Ảnh hóa đơn gốc'),
            leading: IconButton(
              tooltip: 'Đóng ảnh',
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
          body: InteractiveViewer(
            minScale: .5,
            maxScale: 6,
            child: Center(child: Image.memory(bytes, fit: BoxFit.contain)),
          ),
        ),
      ),
    );
  }

  Future<void> _useTotalOnly() async {
    final total = int.tryParse(_total.text), date = _date;
    if (total == null || total <= 0 || total > 999999999999 || date == null) {
      setState(
        () => _error =
            'Kiểm tra tổng thanh toán và chọn ngày chi trước khi tiếp tục.',
      );
      return;
    }
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chỉ dùng tổng tiền?'),
        scrollable: true,
        content: Text(
          'Ngày chi: ${DateFormat('dd/MM/yyyy').format(date)}\nTổng thanh toán: ${_money.format(total)} đ\n\nXác nhận hai thông tin này đúng với hóa đơn gốc. Chi tiết hàng hóa sẽ được bỏ qua.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Kiểm tra lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận tổng tiền'),
          ),
        ],
      ),
    );
    if (mounted && accepted == true) {
      Navigator.pop(
        context,
        ReceiptDraft(total, [], date, _merchant.text.trim(), widget.source),
      );
    }
  }

  Future<void> _print() async {
    final draft = _draft();
    if (draft == null) return;
    setState(() => _printing = true);
    try {
      await printReceipt(draft);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'Chưa mở được bản in. Hãy kiểm tra kết nối rồi thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  Widget _banner(String text, {bool error = false, bool success = false}) {
    final colors = Theme.of(context).colorScheme;
    final background = error
        ? colors.errorContainer
        : success
        ? colors.secondaryContainer
        : colors.surfaceContainerHighest;
    final foreground = error
        ? colors.onErrorContainer
        : success
        ? colors.onSecondaryContainer
        : colors.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                error
                    ? Icons.info_outline
                    : success
                    ? Icons.check_circle_outline
                    : Icons.lightbulb_outline,
                color: foreground,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(text, style: TextStyle(color: foreground)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photo({bool wide = false}) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      mainAxisSize: wide ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Ảnh gốc',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              TextButton.icon(
                onPressed: _zoomOriginal,
                icon: const Icon(Icons.zoom_in),
                label: const Text('Phóng to'),
              ),
            ],
          ),
        ),
        if (wide)
          Expanded(
            child: InteractiveViewer(
              minScale: .5,
              maxScale: 5,
              child: Center(
                child: Image.memory(
                  widget.bytes!,
                  cacheWidth: 1400,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Text('Chưa xem được ảnh.'),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 180,
            width: double.infinity,
            child: InkWell(
              onTap: _zoomOriginal,
              child: Image.memory(
                widget.bytes!,
                cacheWidth: 1000,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Center(child: Text('Chưa xem được ảnh.')),
              ),
            ),
          ),
        const SizedBox(height: 12),
      ],
    ),
  );

  Widget _formContent() {
    final subtotal = _lines.fold<int>(0, (sum, line) => sum + line.amount),
        total = int.tryParse(_total.text) ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_notice.isNotEmpty) _banner(_notice),
        if (_error != null) _banner(_error!, error: true),
        if (!_ready && !_busy) ...[
          const SizedBox(height: 16),
          const Icon(Icons.receipt_long_outlined, size: 52),
          const SizedBox(height: 12),
          const Text(
            'Bạn có thể chọn ảnh khác hoặc nhập thông tin hóa đơn.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _scan,
            icon: const Icon(Icons.refresh),
            label: const Text('Nhận dạng lại'),
          ),
          TextButton(
            onPressed: _manualEntry,
            child: const Text('Nhập thông tin thủ công'),
          ),
        ],
        if (_ready) ...[
          if (_warnings.isNotEmpty)
            Material(
              color: Colors.transparent,
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                initiallyExpanded: true,
                leading: Icon(
                  Icons.fact_check_outlined,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text('${_warnings.length} điểm cần đối chiếu'),
                children: [for (final warning in _warnings) _banner(warning)],
              ),
            ),
          Text(
            'Thông tin hóa đơn',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _merchant,
            enabled: !_locked,
            maxLength: 160,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Cửa hàng / đơn vị bán',
              prefixIcon: Icon(Icons.storefront_outlined),
              counterText: '',
            ),
            onChanged: (_) => setState(() => _reviewed = false),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _locked
                ? null
                : () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _date ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
                    );
                    if (mounted && date != null) {
                      setState(() {
                        _date = date;
                        _reviewed = false;
                      });
                    }
                  },
            icon: const Icon(Icons.calendar_today_outlined),
            label: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _date == null
                    ? 'Chọn ngày chi trên hóa đơn'
                    : 'Ngày chi: ${DateFormat('dd/MM/yyyy').format(_date!)}',
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _total,
            enabled: !_locked,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
            ],
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            decoration: const InputDecoration(
              labelText: 'Tổng thanh toán',
              suffixText: 'VND',
              helperText: 'Số tiền cuối cùng trên hóa đơn',
            ),
            validator: (value) => _positive(value, 999999999999),
            onChanged: (_) => setState(() => _reviewed = false),
          ),
          if (_tax != null || _discount != null || _surcharge != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                children: [
                  if (_tax != null)
                    _adjustmentRow('Thuế', '${_money.format(_tax)} đ'),
                  if (_discount != null)
                    _adjustmentRow(
                      'Giảm giá',
                      '-${_money.format(_discount!.abs())} đ',
                    ),
                  if (_surcharge != null)
                    _adjustmentRow('Phụ phí', '${_money.format(_surcharge)} đ'),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Chi tiết hàng hóa',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Kiểm tra tên hàng, số lượng và đơn giá. Bỏ qua chi tiết nếu bạn chỉ cần chia tổng tiền.',
          ),
          const SizedBox(height: 12),
          if (_lines.isEmpty)
            _banner(
              'Chưa có dòng hàng. Bạn có thể thêm chi tiết hoặc sử dụng tổng thanh toán.',
            ),
          for (var i = 0; i < _lines.length; i++) _lineEditor(i),
          OutlinedButton.icon(
            onPressed: _locked || _lines.length >= 100
                ? null
                : () => setState(() {
                    _lines.add(_EditableLine(null));
                    _detected.add(null);
                    _reviewed = false;
                  }),
            icon: const Icon(Icons.add),
            label: const Text('Thêm dòng hàng'),
          ),
          const SizedBox(height: 16),
          if (_lines.isNotEmpty) ...[
            _banner(
              subtotal == total && total > 0
                  ? 'Tổng ${_lines.length} dòng hàng khớp tổng thanh toán: ${_money.format(total)} đ.'
                  : 'Tổng dòng hàng: ${_money.format(subtotal)} đ\nChênh lệch: ${_money.format(total - subtotal)} đ. Kiểm tra thuế, phụ phí, giảm giá hoặc số đọc sai. Chỉ dùng tổng tiền nếu chưa đối chiếu được chi tiết.',
              error: subtotal != total,
              success: subtotal == total && total > 0,
            ),
            OutlinedButton.icon(
              onPressed: _locked ? null : _useTotalOnly,
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Chỉ dùng tổng tiền'),
            ),
            const SizedBox(height: 12),
          ],
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            child: CheckboxListTile(
              value: _reviewed,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              onChanged: _locked
                  ? null
                  : (value) => setState(() {
                      _reviewed = value ?? false;
                      _error = null;
                    }),
              title: const Text('Tôi đã đối chiếu thông tin với hóa đơn gốc'),
              subtitle: const Text(
                'Ngày chi, các dòng hàng và tổng thanh toán đều chính xác.',
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ),
          if (widget.bytes != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  if (_candidates.length > 1)
                    TextButton.icon(
                      onPressed: _locked ? null : _chooseCandidate,
                      icon: const Icon(Icons.compare_arrows),
                      label: const Text('Đối chiếu kết quả'),
                    ),
                  TextButton.icon(
                    onPressed: _locked ? null : _requestStructure,
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: const Text('Đọc kỹ bố cục'),
                  ),
                ],
              ),
            ),
          if (_raw.isNotEmpty)
            Material(
              color: Colors.transparent,
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Văn bản đã nhận dạng'),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SelectableText(_raw),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context),
        colors = Theme.of(context).colorScheme;
    final fullscreen = media.size.width < 600;
    return Dialog(
      insetPadding: fullscreen ? EdgeInsets.zero : const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(fullscreen ? 0 : 24),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 1180,
        height: fullscreen ? media.size.height : media.size.height * .92,
        child: Scaffold(
          backgroundColor: colors.surface,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Kiểm tra hóa đơn'),
            leading: IconButton(
              tooltip: 'Đóng',
              onPressed: _printing ? null : () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
            actions: [
              if (_ready)
                IconButton(
                  tooltip: _printing ? 'Đang mở bản in' : 'In hoặc lưu PDF',
                  onPressed: _locked ? null : _print,
                  icon: _printing
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.print_outlined),
                ),
            ],
          ),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                if (_busy)
                  Semantics(
                    liveRegion: true,
                    child: Container(
                      color: colors.primaryContainer,
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _progress,
                            style: TextStyle(
                              color: colors.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const LinearProgressIndicator(),
                          const SizedBox(height: 8),
                          Text(
                            'Ảnh mờ hoặc hóa đơn dài có thể cần thêm thời gian.',
                            style: TextStyle(color: colors.onPrimaryContainer),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: _ready ? _stopEnhancing : _manualEntry,
                              child: Text(
                                _ready
                                    ? 'Dừng và kiểm tra dữ liệu đã đọc'
                                    : 'Chuyển sang nhập thủ công',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide =
                          constraints.maxWidth >= 840 && widget.bytes != null;
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: fullscreen ? 16 : 24,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (wide) ...[
                              Expanded(
                                flex: 4,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 16,
                                    bottom: 16,
                                  ),
                                  child: _photo(wide: true),
                                ),
                              ),
                              const SizedBox(width: 24),
                            ],
                            Expanded(
                              flex: 5,
                              child: Form(
                                key: _form,
                                child: SingleChildScrollView(
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  padding: const EdgeInsets.only(
                                    top: 16,
                                    bottom: 24,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (!wide && widget.bytes != null) ...[
                                        _photo(),
                                        const SizedBox(height: 16),
                                      ],
                                      _formContent(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _ready
              ? SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border(
                        top: BorderSide(color: colors.outlineVariant),
                      ),
                    ),
                    child: FilledButton.icon(
                      onPressed: _locked
                          ? null
                          : () {
                              final draft = _draft();
                              if (draft != null) Navigator.pop(context, draft);
                            },
                      icon: const Icon(Icons.check),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('Sử dụng hóa đơn'),
                      ),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _adjustmentRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13.5,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );

  Widget _lineEditor(int i) {
    final line = _lines[i], detected = _detected[i];
    final hasMismatch = detected != null && detected != line.amount;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: ObjectKey(line),
      margin: const EdgeInsets.only(bottom: 12),
      shape: hasMismatch
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: scheme.error, width: 1.2),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Dòng ${i + 1}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Xóa dòng ${i + 1}',
                  onPressed: _locked
                      ? null
                      : () => setState(() {
                          _retired.add(_lines.removeAt(i));
                          _detected.removeAt(i);
                          _reviewed = false;
                        }),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            TextFormField(
              controller: line.name,
              enabled: !_locked,
              maxLength: 160,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Tên hàng',
                counterText: '',
              ),
              onChanged: (_) => setState(() => _reviewed = false),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Nhập tên hàng' : null,
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final quantity = TextFormField(
                  controller: line.quantity,
                  enabled: !_locked,
                  decoration: const InputDecoration(labelText: 'Số lượng'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  validator: (value) => _positive(value, 999),
                  onChanged: (_) => setState(() => _reviewed = false),
                );
                final unit = TextFormField(
                  controller: line.unit,
                  enabled: !_locked,
                  decoration: const InputDecoration(
                    labelText: 'Đơn giá',
                    suffixText: 'VND',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                  ],
                  validator: (value) => _positive(value, 999999999999),
                  onChanged: (_) => setState(() => _reviewed = false),
                );
                return constraints.maxWidth < 320 ||
                        MediaQuery.textScalerOf(context).scale(1) > 1.3
                    ? Column(
                        children: [quantity, const SizedBox(height: 14), unit],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: quantity),
                          const SizedBox(width: 12),
                          Expanded(flex: 2, child: unit),
                        ],
                      );
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Thành tiền: ${_money.format(line.amount)} đ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (detected != null && detected != line.amount)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Ảnh đọc được: ${_money.format(detected)} đ. Hãy kiểm tra số lượng và đơn giá.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (detected != null &&
                detected > 0 &&
                line.quantity.text.isEmpty &&
                line.unit.text.isEmpty)
              TextButton.icon(
                onPressed: _locked
                    ? null
                    : () => setState(() {
                        line.quantity.text = '1';
                        line.unit.text = '$detected';
                        _reviewed = false;
                      }),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Xác nhận đây là một dòng gộp'),
              ),
          ],
        ),
      ),
    );
  }
}
