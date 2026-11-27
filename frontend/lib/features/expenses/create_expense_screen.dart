// Trách nhiệm file: Xây dựng màn hình create expense screen và điều phối tương tác người dùng với trạng thái nghiệp vụ.

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/api/api_client.dart';
import '../../core/network/network_error.dart';
import '../../core/state/app_sync.dart';
import '../../data/repositories/auth_repository.dart';
import '../settlements/group_settlement_screen.dart';
import 'ocr/receipt_scan.dart';

/// ----------------------------------------------------------------------------
/// DỮ LIỆU MẪU BAN ĐẦU CHO MÀN HÌNH TẠO KHOẢN CHI
/// ----------------------------------------------------------------------------
class GroupMemberItem {
  final String id;
  final String name;
  final String avatarUrl;
  double amount;
  double percentage;
  double weight;
  bool isSelected;

  GroupMemberItem({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.amount = 0.0,
    this.percentage = 0.0,
    this.weight = 1.0,
    this.isSelected = true,
  });
}

class ExpenseItemDetail {
  String id;
  String name;
  double price;
  int quantity;
  double? unitPrice;
  List<String> assignedMemberIds;

  ExpenseItemDetail({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.unitPrice,
    required this.assignedMemberIds,
  });
}

enum SplitMode { equal, amount, percent, weight, item }

/// ----------------------------------------------------------------------------
/// MÀN HÌNH TẠO KHOẢN CHI CHI TIẾT (CREATE EXPENSE SCREEN)
/// Chuyển động mượt mà, đầy đủ các chế độ chia tiền & chuẩn Design Tokens
/// ----------------------------------------------------------------------------
class CreateExpenseScreen extends ConsumerStatefulWidget {
  final int? groupId;
  final bool isActive;
  const CreateExpenseScreen({super.key, this.groupId, this.isActive = true});

  @override
  ConsumerState<CreateExpenseScreen> createState() =>
      _CreateExpenseScreenState();
}

class _CreateExpenseScreenState extends ConsumerState<CreateExpenseScreen>
    with SingleTickerProviderStateMixin {
  // Controller hiệu ứng chuyển động xuất hiện màn hình
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Controllers cho các ô nhập dữ liệu
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showValidation = false;
  final Map<String, TextEditingController> _percentControllers = {};

  final currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  List<Map<String, dynamic>> _categories = [];
  int? _categoryId;
  Future<void> _loadCategories() async {
    try {
      final raw = await ApiClient.get('/v1/categories') as List;
      if (mounted)
        setState(
          () => _categories = raw
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
        );
    } catch (_) {
      /* category is optional; expense entry remains available */
    }
  }

  // Danh sách thành viên nhóm mẫu
  late List<GroupMemberItem> _members;
  String _payerId = '';
  DateTime _expenseDate = DateTime.now();
  int? _groupId;
  List<Map<String, dynamic>> _groups = [];
  bool _loadingMembers = true;
  bool _saving = false;
  Object? _loadError;

  // Chế độ chia tiền
  SplitMode _splitMode = SplitMode.equal;

  // Danh sách item nếu dùng chế độ chia theo Món (SplitMode.item)
  List<ExpenseItemDetail> _items = [];

  // Ảnh hóa đơn đính kèm (giả lập)
  bool _scanMode = false;
  ReceiptDraft? _receipt;
  bool _isOcrScanning = false;

  @override
  void initState() {
    super.initState();

    _loadCategories();

    _members = [];
    _loadGroups();

    // Animation khởi tạo
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _animController.forward();
    _recalculateSplit();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _loadingMembers = true;
      _loadError = null;
    });
    try {
      final groups = (await ApiClient.get('/groups') as List)
          .map((g) => Map<String, dynamic>.from(g as Map))
          .toList();
      if (!mounted) return;
      _groups = groups;
      final preferred = _groupId ?? widget.groupId;
      _groupId = groups.any((g) => g['id'] == preferred)
          ? preferred
          : (groups.isEmpty ? null : (groups.first['id'] as num).toInt());
      if (_groupId != null) {
        await _loadMembers();
      } else {
        setState(() => _loadingMembers = false);
      }
    } catch (error) {
      if (mounted)
        setState(() {
          _loadError = error;
          _loadingMembers = false;
        });
    }
  }

  @override
  void didUpdateWidget(covariant CreateExpenseScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _loadGroups();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _loadingMembers = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        AuthRepository().getCurrentUserId(),
        ApiClient.get('/groups/$_groupId/members'),
      ]);
      final currentId = results[0] as int;
      final data = results[1] as List;
      if (!mounted) return;
      for (final controller in _percentControllers.values) {
        controller.dispose();
      }
      _percentControllers.clear();
      _members = data
          .map(
            (m) => GroupMemberItem(
              id: m['userId'].toString(),
              name: m['fullName']?.toString() ?? 'Thành viên',
              avatarUrl: m['avatarUrl']?.toString() ?? '',
            ),
          )
          .toList();
      _payerId = _members.any((m) => m.id == '$currentId')
          ? '$currentId'
          : (_members.isEmpty ? '' : _members.first.id);
      _items = [];
      if (_scanMode && _receipt != null) _populateReceiptItems(_receipt!);
      _initPercentControllers();
      _recalculateSplit();
      setState(() => _loadingMembers = false);
    } catch (error) {
      if (mounted)
        setState(() {
          _loadError = error;
          _loadingMembers = false;
        });
    }
  }

  Future<void> _saveExpense() async {
    if (_saving || _groupId == null || (_scanMode && _receipt == null)) return;
    setState(() => _showValidation = true);
    if (_formKey.currentState?.validate() != true) return;
    if (_splitMode == SplitMode.item) _syncItemParticipants();
    final selected = _members.where((m) => m.isSelected).toList();
    if (_titleController.text.trim().isEmpty ||
        _totalAmount <= 0 ||
        selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nhập tên, số tiền và chọn người tham gia.'),
        ),
      );
      return;
    }
    if (!_members.any((member) => member.id == _payerId)) {
      _showMessage('Chọn người đã thanh toán khoản chi.');
      return;
    }
    if (_splitMode == SplitMode.amount &&
        ((selected.fold<double>(0, (sum, member) => sum + member.amount) -
                        _totalAmount)
                    .abs() >
                0.01 ||
            selected.any(
              (member) => !member.amount.isFinite || member.amount <= 0,
            ))) {
      _showMessage('Tổng số tiền của các thành viên phải bằng tổng khoản chi.');
      return;
    }
    if (_splitMode == SplitMode.percent &&
        (selected.fold<int>(
                  0,
                  (sum, member) => sum + (member.percentage * 100).round(),
                ) !=
                10000 ||
            selected.any(
              (member) =>
                  !member.percentage.isFinite ||
                  member.percentage <= 0 ||
                  member.percentage > 100,
            ))) {
      _showMessage(
        'Mỗi người cần phần chia lớn hơn 0 và tổng phần trăm phải bằng 100%.',
      );
      return;
    }
    if (_splitMode == SplitMode.item &&
        (_items.isEmpty ||
            _items.any(
              (item) => item.assignedMemberIds.isEmpty || item.price <= 0,
            ) ||
            (_items.fold<double>(0, (sum, item) => sum + item.price) -
                        _totalAmount)
                    .abs() >
                0.01)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mỗi món cần người chia; tổng các món phải bằng tổng khoản chi.',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiClient.post('/v1/expenses', {
        'groupId': _groupId,
        'payerId': int.parse(_payerId),
        'title': _titleController.text.trim(),
        if (_categoryId != null) 'categoryId': _categoryId,
        'description': _noteController.text.trim(),
        'totalAmount': _totalAmount,
        'expenseDate': DateFormat('yyyy-MM-dd').format(_expenseDate),
        'splitType': _splitMode.name.toUpperCase(),
        'participants': selected
            .map(
              (m) => {
                'userId': int.parse(m.id),
                'amount': m.amount,
                'percentage': m.percentage,
                'weight': m.weight,
              },
            )
            .toList(),
        if (_splitMode == SplitMode.item)
          'items': _items
              .map(
                (item) => {
                  'itemName': item.name,
                  'quantity': item.quantity,
                  'unitPrice': item.unitPrice ?? item.price,
                  'participants': item.assignedMemberIds
                      .map((id) => {'userId': int.parse(id)})
                      .toList(),
                },
              )
              .toList(),
      });
      if (!mounted) return;
      notifyDataChanged();
      _titleController.clear();
      _amountController.clear();
      _noteController.clear();
      _items.clear();
      _categoryId = null;
      _receipt = null;
      _scanMode = false;
      _splitMode = SplitMode.equal;
      _expenseDate = DateTime.now();
      _showValidation = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu khoản chi vào nhóm.')),
      );
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GroupSettlementScreen(groupId: _groupId),
        ),
      );
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _friendlyError(Object error) => error is DioException
      ? networkErrorMessage(error)
      : 'Chưa thể xử lý dữ liệu. Vui lòng thử lại.';

  @override
  void dispose() {
    _animController.dispose();
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    for (var ctrl in _percentControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  // --- HÀM TÍNH TOÁN VÀ CẬP NHẬT CHẾ ĐỘ CHIA TIỀN ---
  double get _totalAmount {
    final cleanStr = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(cleanStr) ?? 0.0;
  }

  String _formatPercent(double p) {
    if (p == p.roundToDouble()) {
      return p.toInt().toString();
    }
    return p.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');
  }

  void _initPercentControllers() {
    for (var m in _members) {
      _percentControllers[m.id] = TextEditingController(
        text: m.isSelected && m.percentage > 0
            ? _formatPercent(m.percentage)
            : (m.isSelected ? '0' : ''),
      );
    }
  }

  void _syncPercentControllers({String? excludeId}) {
    for (var m in _members) {
      if (m.id == excludeId) continue;
      final ctrl = _percentControllers[m.id];
      if (ctrl != null) {
        final formatted = m.isSelected ? _formatPercent(m.percentage) : '';
        if (ctrl.text != formatted) {
          ctrl.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
      }
    }
  }

  void _splitEquallyPercent() {
    HapticFeedback.selectionClick();
    final selected = _members.where((m) => m.isSelected).toList();
    if (selected.isEmpty) return;

    final count = selected.length;
    final basePct = double.parse((100.0 / count).toStringAsFixed(2));
    double runningSum = 0.0;

    for (int i = 0; i < count; i++) {
      if (i == count - 1) {
        selected[i].percentage = double.parse(
          (100.0 - runningSum).toStringAsFixed(2),
        );
      } else {
        selected[i].percentage = basePct;
        runningSum += basePct;
      }
    }

    for (var m in _members) {
      if (m.isSelected) {
        m.amount = (_totalAmount * m.percentage) / 100.0;
      } else {
        m.percentage = 0.0;
        m.amount = 0.0;
      }
    }
    _syncPercentControllers();
    setState(() {});
  }

  void _autoBalancePercent([GroupMemberItem? target]) {
    HapticFeedback.lightImpact();
    final selected = _members.where((m) => m.isSelected).toList();
    if (selected.isEmpty) return;

    final targetMember = target ?? selected.last;
    final sumOthers = selected
        .where((m) => m.id != targetMember.id)
        .fold(0.0, (s, m) => s + m.percentage);
    final remaining = (100.0 - sumOthers).clamp(0.0, 100.0);
    final roundedRemaining = double.parse(remaining.toStringAsFixed(2));

    targetMember.percentage = roundedRemaining;
    for (var m in _members) {
      m.amount = (_totalAmount * m.percentage) / 100.0;
    }
    _syncPercentControllers();
    setState(() {});
  }

  void _onPercentChanged(GroupMemberItem editedMember, String value) {
    final cleanVal = value.replaceAll(',', '.').trim();
    final valNum = double.tryParse(cleanVal) ?? 0.0;
    editedMember.percentage = valNum;

    final selectedMembers = _members.where((m) => m.isSelected).toList();
    if (selectedMembers.length > 1) {
      // Tự động tính phần % cho người cuối cùng khi nhập các người trước
      final targetMember = (selectedMembers.last.id == editedMember.id)
          ? (selectedMembers.length >= 2
                ? selectedMembers[selectedMembers.length - 2]
                : null)
          : selectedMembers.last;

      if (targetMember != null && targetMember.id != editedMember.id) {
        final sumOthers = selectedMembers
            .where((m) => m.id != targetMember.id)
            .fold(0.0, (s, m) => s + m.percentage);
        final remaining = 100.0 - sumOthers;
        if (remaining >= 0) {
          final roundedRemaining = double.parse(remaining.toStringAsFixed(2));
          targetMember.percentage = roundedRemaining;
          final targetCtrl = _percentControllers[targetMember.id];
          if (targetCtrl != null) {
            final formatted = _formatPercent(roundedRemaining);
            targetCtrl.value = TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            );
          }
        }
      }
    }

    for (var m in _members) {
      m.amount = (_totalAmount * m.percentage) / 100.0;
    }
    setState(() {});
  }

  void _recalculateSplit() {
    final selectedMembers = _members.where((m) => m.isSelected).toList();
    final selectedCount = selectedMembers.length;
    if (selectedCount == 0 || _totalAmount <= 0) {
      for (final m in _members) {
        m.amount = 0;
      }
      return;
    }

    if (_splitMode == SplitMode.equal) {
      final base = (_totalAmount / selectedCount).floorToDouble();
      final remainder = _totalAmount.round() % selectedCount;
      var index = 0;
      for (var m in _members) {
        if (m.isSelected) {
          m.amount = base + (index < remainder ? 1 : 0);
          index++;
          m.percentage = 100.0 / selectedCount;
        } else {
          m.amount = 0.0;
          m.percentage = 0.0;
        }
      }
    } else if (_splitMode == SplitMode.percent) {
      final totalPct = selectedMembers.fold(0.0, (s, m) => s + m.percentage);
      if (totalPct == 0.0) {
        final defaultPct = double.parse(
          (100.0 / selectedCount).toStringAsFixed(2),
        );
        double runningSum = 0.0;
        for (int i = 0; i < selectedCount; i++) {
          if (i == selectedCount - 1) {
            selectedMembers[i].percentage = double.parse(
              (100.0 - runningSum).toStringAsFixed(2),
            );
          } else {
            selectedMembers[i].percentage = defaultPct;
            runningSum += defaultPct;
          }
        }
      }
      for (var m in _members) {
        if (m.isSelected) {
          m.amount = (_totalAmount * m.percentage) / 100.0;
        } else {
          m.percentage = 0.0;
          m.amount = 0.0;
        }
      }
      _syncPercentControllers();
    } else if (_splitMode == SplitMode.weight) {
      final totalWeight = _members
          .where((m) => m.isSelected)
          .fold(0.0, (sum, m) => sum + m.weight);
      for (var m in _members) {
        if (m.isSelected && totalWeight > 0) {
          m.amount = (_totalAmount * m.weight) / totalWeight;
          m.percentage = (m.weight / totalWeight) * 100.0;
        } else {
          m.amount = 0;
          m.percentage = 0;
        }
      }
    }
  }

  // Cộng nhanh số tiền (+50k, +100k...)
  void _addQuickAmount(double value) {
    HapticFeedback.lightImpact();
    final current = _totalAmount;
    final updated = (current + value).clamp(0, 999999999999);
    _amountController.text = updated.round().toString();
    setState(() {
      _recalculateSplit();
    });
  }

  bool get _receiptItemsMatch =>
      _receipt != null &&
      _receipt!.items.isNotEmpty &&
      _receipt!.subtotal == _receipt!.total;

  void _populateReceiptItems(ReceiptDraft result) {
    final selected = _members
        .where((m) => m.isSelected)
        .map((m) => m.id)
        .toList();
    _items = result.subtotal == result.total
        ? result.items
              .asMap()
              .entries
              .map(
                (e) => ExpenseItemDetail(
                  id: 'ocr-${e.key}',
                  name: e.value.name,
                  price: e.value.amount.toDouble(),
                  quantity: e.value.quantity,
                  unitPrice: e.value.unitPrice.toDouble(),
                  assignedMemberIds: List.of(selected),
                ),
              )
              .toList()
        : [];
    if (_splitMode == SplitMode.item && _items.isEmpty)
      _splitMode = SplitMode.equal;
  }

  Future<void> _changeEntryMode(bool scan) async {
    if (_scanMode == scan || _saving || _isOcrScanning) return;
    setState(() {
      _scanMode = scan;
      // Keep typed values when switching entry methods. Only an accepted scan
      // replaces amounts and items; cancelling the scanner leaves the draft.
      if (!scan) _receipt = null;
    });
  }

  Future<void> _scanReceiptOCR({bool qr = false, bool review = false}) async {
    if (_isOcrScanning || _saving) return;
    setState(() => _isOcrScanning = true);
    try {
      final result = review && _receipt != null
          ? await reviewReceipt(context, _receipt!)
          : await scanReceipt(context, qr: qr);
      if (!mounted || result == null) return;
      setState(() {
        final previousTitle = _receipt?.merchant;
        final autoTitle =
            _titleController.text.trim().isEmpty ||
            _titleController.text == previousTitle ||
            _titleController.text == 'Chi tiêu theo hóa đơn';
        _receipt = result;
        _amountController.text = result.total.toString();
        _expenseDate = result.date;
        if (autoTitle)
          _titleController.text = result.merchant.isEmpty
              ? 'Chi tiêu theo hóa đơn'
              : result.merchant.substring(
                  0,
                  result.merchant.length > 160 ? 160 : result.merchant.length,
                );
        _populateReceiptItems(result);
        _splitMode = _items.isEmpty ? SplitMode.equal : SplitMode.item;
        _recalculateSplit();
      });
    } on FormatException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted)
        _showMessage(
          'Không mở được hóa đơn. Hãy thử lại hoặc chọn nhập thủ công.',
        );
    } finally {
      if (mounted) setState(() => _isOcrScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingMembers) {
      return Scaffold(
        appBar: _buildAppBar(context),
        body: const Center(
          child: CircularProgressIndicator(
            semanticsLabel: 'Đang tải nhóm và thành viên',
          ),
        ),
      );
    }
    if (_loadError != null || _members.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(context),
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _loadError != null
                          ? Icons.cloud_off_outlined
                          : Icons.group_add_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _loadError != null
                          ? 'Chưa tải được nhóm'
                          : 'Thêm nhóm để bắt đầu',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _loadError != null
                          ? _friendlyError(_loadError!)
                          : 'Tạo nhóm và thêm thành viên trong mục Nhóm, sau đó quay lại để ghi khoản chi.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _loadGroups,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tải lại nhóm'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final content = Form(
      key: _formKey,
      autovalidateMode: _showValidation
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<int>(
                        value: _groupId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Nhóm chi tiêu',
                          prefixIcon: Icon(Icons.group_outlined),
                        ),
                        items: _groups
                            .map(
                              (g) => DropdownMenuItem<int>(
                                value: (g['id'] as num).toInt(),
                                child: Text(
                                  g['name'].toString(),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (_saving || _isOcrScanning)
                            ? null
                            : (id) {
                                _groupId = id;
                                _loadMembers();
                              },
                      ),
                      const SizedBox(height: 12),
                      _buildEntryOptions(),
                      if (_scanMode) ...[
                        _buildReceiptSection(),
                        const SizedBox(height: 20),
                      ],
                      if (!_scanMode || _receipt != null)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final details = _buildSection(
                              number: '1',
                              title: 'Thông tin khoản chi',
                              description:
                                  'Số tiền, ngày chi và người đã thanh toán.',
                              child: _buildExpenseFields(),
                            );
                            final split = _buildSection(
                              number: '2',
                              title: 'Chọn cách chia tiền',
                              description:
                                  'Kiểm tra thành viên và phần chia trước khi lưu.',
                              child: _buildSplitModeSection(),
                            );
                            if (constraints.maxWidth < 900) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  details,
                                  const SizedBox(height: 20),
                                  split,
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: details),
                                const SizedBox(width: 24),
                                Expanded(child: split),
                              ],
                            );
                          },
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _buildStickySubmitBar(),
        ],
      ),
    );
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SafeArea(
        top: false,
        bottom: false,
        child: reduceMotion
            ? content
            : FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(position: _slideAnim, child: content),
              ),
      ),
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    required String description,
    required Widget child,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  child: Text(number),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(description, style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextFormField(
        controller: _titleController,
        maxLength: 200,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(
          labelText: 'Tên khoản chi',
          hintText: 'Ví dụ: Ăn tối cùng nhóm',
        ),
        validator: (value) => (value ?? '').trim().isEmpty
            ? 'Nhập tên để dễ tìm lại khoản chi.'
            : null,
      ),
      const SizedBox(height: 16),
      if (!_scanMode) ...[_buildAmountInputCard(), const SizedBox(height: 20)],
      _buildPayerSelectorCard(),
      const SizedBox(height: 20),
      if (_categories.isNotEmpty) ...[
        _buildTitleAndCategoryCard(),
        const SizedBox(height: 20),
      ],
      TextField(
        controller: _noteController,
        maxLines: 3,
        maxLength: 1000,
        decoration: const InputDecoration(
          labelText: 'Ghi chú (không bắt buộc)',
          hintText: 'Thêm thông tin cho các thành viên',
        ),
      ),
    ],
  );

  TextStyle _type(TextStyle style) =>
      style.copyWith(color: Theme.of(context).colorScheme.onSurface);

  // --- APP BAR VỚI BADGE NHÓM DU LỊCH ---
  PreferredSizeWidget _buildAppBar(BuildContext context) =>
      AppBar(title: Text(tr(context, 'Thêm khoản chi', 'Add expense')));

  // --- CARD Ô NHẬP TỔNG SỐ TIỀN & PHÍM NGHỆ THUẬT ---
  Widget _buildAmountInputCard() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextFormField(
        controller: _amountController,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(12),
        ],
        onChanged: (_) => setState(_recalculateSplit),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
        decoration: const InputDecoration(
          labelText: 'Tổng số tiền',
          hintText: '0',
          suffixText: 'VND',
        ),
        validator: (value) =>
            (int.tryParse(value ?? '') ?? 0) <= 0 ||
                (int.tryParse(value ?? '') ?? 0) > 999999999999
            ? 'Nhập số tiền lớn hơn 0 đồng.'
            : null,
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildQuickAmountChip('+50.000 đ', 50000),
          _buildQuickAmountChip('+100.000 đ', 100000),
        ],
      ),
    ],
  );

  Widget _buildQuickAmountChip(String label, double amount) => ActionChip(
    label: Text(label),
    tooltip: 'Cộng thêm ${currencyFormatter.format(amount)}',
    onPressed: _saving ? null : () => _addQuickAmount(amount),
  );

  // --- CARD TIÊU ĐỀ KHOẢN CHI & DANH MỤC HORIZONTAL SCROLL ---
  Widget _buildTitleAndCategoryCard() => DropdownButtonFormField<int>(
    value: _categoryId,
    isExpanded: true,
    decoration: const InputDecoration(labelText: 'Danh mục (không bắt buộc)'),
    items: [
      const DropdownMenuItem<int>(value: null, child: Text('Không phân loại')),
      ..._categories.map(
        (c) => DropdownMenuItem<int>(
          value: (c['id'] as num).toInt(),
          child: Text(c['name'].toString(), overflow: TextOverflow.ellipsis),
        ),
      ),
    ],
    onChanged: _saving ? null : (value) => setState(() => _categoryId = value),
  );

  // --- KHU VỰC AI SCAN HÓA ĐƠN OCR ---
  Widget _buildEntryOptions() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cách thêm khoản chi',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              avatar: const Icon(Icons.edit_outlined),
              label: const Text('Nhập thủ công'),
              selected: !_scanMode,
              onSelected: (_saving || _isOcrScanning)
                  ? null
                  : (_) => _changeEntryMode(false),
            ),
            ChoiceChip(
              avatar: const Icon(Icons.document_scanner_outlined),
              label: const Text('Quét hóa đơn'),
              selected: _scanMode,
              onSelected: (_saving || _isOcrScanning)
                  ? null
                  : (_) => _changeEntryMode(true),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildReceiptSection() {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  _receipt == null
                      ? Icons.document_scanner_outlined
                      : Icons.fact_check_outlined,
                  color: scheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _receipt == null
                        ? 'Thêm từ hóa đơn'
                        : 'Hóa đơn đã đối chiếu',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _receipt == null
                  ? 'Chụp hoặc chọn ảnh rõ toàn bộ hóa đơn. Bạn có thể chỉnh kết quả trước khi dùng.'
                  : 'Kiểm tra người trả và chọn các thành viên cùng chia khoản chi.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: (_isOcrScanning || _saving)
                      ? null
                      : () => _scanReceiptOCR(),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(
                    _receipt == null ? 'Chụp / chọn ảnh' : 'Quét ảnh khác',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: (_isOcrScanning || _saving)
                      ? null
                      : () => _scanReceiptOCR(qr: true),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Quét mã QR'),
                ),
              ],
            ),
            if (_isOcrScanning) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(
                semanticsLabel: 'Đang xử lý hóa đơn',
              ),
            ],
            if (_receipt != null) ...[
              const Divider(height: 32),
              Text(
                currencyFormatter.format(_receipt!.total),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${DateFormat('dd/MM/yyyy').format(_receipt!.date)} • ${_receipt!.items.length} dòng hàng',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              if (!_receiptItemsMatch && _receipt!.items.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildNotice(
                  Icons.info_outline,
                  'Tổng tiền hàng khác tổng thanh toán. Hãy chia theo tổng tiền hoặc sửa các dòng hàng cho khớp.',
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: (_isOcrScanning || _saving)
                      ? null
                      : () => _scanReceiptOCR(review: true),
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Xem và chỉnh hóa đơn'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotice(IconData icon, String message) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayerSelectorCard() => LayoutBuilder(
    builder: (context, constraints) {
      final payer = DropdownButtonFormField<String>(
        value: _payerId,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Người đã thanh toán',
          prefixIcon: Icon(Icons.person_outline),
        ),
        items: _members
            .map(
              (m) => DropdownMenuItem(
                value: m.id,
                child: Text(m.name, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: _saving
            ? null
            : (value) {
                if (value != null) setState(() => _payerId = value);
              },
      );
      final date = OutlinedButton.icon(
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 56)),
        onPressed: (_scanMode || _saving)
            ? null
            : () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _expenseDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null && mounted)
                  setState(() => _expenseDate = picked);
              },
        icon: const Icon(Icons.calendar_today_outlined),
        label: Text(
          'Ngày chi: ${DateFormat('dd/MM/yyyy').format(_expenseDate)}',
          textAlign: TextAlign.center,
        ),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          payer,
          const SizedBox(height: 16),
          if (_scanMode)
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Ngày trên hóa đơn'),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(DateFormat('dd/MM/yyyy').format(_expenseDate)),
                  ),
                ],
              ),
            )
          else
            date,
        ],
      );
    },
  );

  // --- PHẦN CHỌN CHẾ ĐỘ CHIA TIỀN (5 MODES) VỚI TAB CHUYỂN ĐỘNG ---
  Widget _buildSplitModeSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        tr(context, 'Chia cho', 'Split with'),
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 4,
        runSpacing: 6,
        children: [
          _buildSplitTabItem(
            'Chia đều',
            SplitMode.equal,
            Icons.pie_chart_outline,
          ),
          _buildSplitTabItem(
            'Số tiền',
            SplitMode.amount,
            Icons.payments_outlined,
          ),
          _buildSplitTabItem('%', SplitMode.percent, Icons.percent),
          _buildSplitTabItem('Hệ số', SplitMode.weight, Icons.balance),
          if (!_scanMode || _receiptItemsMatch)
            _buildSplitTabItem('Theo món', SplitMode.item, Icons.restaurant),
        ],
      ),
      const SizedBox(height: 14),
      _buildActiveSplitContent(),
    ],
  );

  Widget _buildSplitTabItem(
    String label,
    SplitMode mode,
    IconData icon,
  ) => ChoiceChip(
    label: Text(label),
    selected: _splitMode == mode,
    showCheckmark: false,
    onSelected: (_) => setState(() {
      _splitMode = mode;
      if (mode == SplitMode.item) _syncItemParticipants();
      if (mode == SplitMode.amount) {
        final selected = _members.where((member) => member.isSelected).toList();
        var allocated = 0.0;
        for (var i = 0; i < selected.length; i++) {
          final remaining = (_totalAmount - allocated).clamp(0.0, _totalAmount);
          selected[i].amount = i == selected.length - 1
              ? remaining
              : selected[i].amount.roundToDouble().clamp(0.0, remaining);
          allocated += selected[i].amount;
        }
      }
      _recalculateSplit();
    }),
    selectedColor: Theme.of(context).colorScheme.primaryContainer,
    backgroundColor: Theme.of(context).colorScheme.surface,
    padding: const EdgeInsets.symmetric(horizontal: 3),
  );

  Widget _buildActiveSplitContent() {
    switch (_splitMode) {
      case SplitMode.equal:
        return _buildEqualSplitContent();
      case SplitMode.amount:
        return _buildAmountSplitContent();
      case SplitMode.percent:
        return _buildPercentSplitContent();
      case SplitMode.weight:
        return _buildWeightSplitContent();
      case SplitMode.item:
        return _buildItemSplitContent();
    }
  }

  // 1. Chia đều (EQUAL)
  Widget _buildEqualSplitContent() {
    final selectedMembers = _members.where((m) => m.isSelected).toList();
    final perPerson = selectedMembers.isNotEmpty
        ? _totalAmount / selectedMembers.length
        : 0.0;

    return Container(
      key: const ValueKey('equal_split'),
      padding: const EdgeInsets.all(AppDimensions.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppDimensions.radius20,
        boxShadow: AppDimensions.shadowSm,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Tự động chia đều cho ${selectedMembers.length} người',
                  style: _type(AppTypography.bodySmall).copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${currencyFormatter.format(perPerson)} /người',
                  textAlign: TextAlign.end,
                  style: _type(AppTypography.title).copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.n100),
          ..._members.map((m) {
            return Material(
              color: Colors.transparent,
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.p500,
                shape: RoundedRectangleBorder(
                  borderRadius: AppDimensions.radius12,
                ),
                secondary: CircleAvatar(
                  radius: 16,
                  backgroundImage: m.avatarUrl.isEmpty
                      ? null
                      : NetworkImage(m.avatarUrl),
                ),
                title: Text(
                  m.name,
                  style: _type(
                    AppTypography.bodyMedium,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  m.isSelected
                      ? currencyFormatter.format(m.amount)
                      : 'Không tham gia',
                  style: _type(AppTypography.caption).copyWith(
                    color: m.isSelected ? AppColors.p600 : AppColors.n400,
                  ),
                ),
                value: m.isSelected,
                onChanged: (val) {
                  setState(() {
                    m.isSelected = val ?? false;
                    _recalculateSplit();
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  // 2. Chia theo Số tiền cụ thể (AMOUNT)
  Widget _buildMemberSelection(GroupMemberItem member) => Material(
    color: Colors.transparent,
    child: CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      value: member.isSelected,
      title: Text(member.name),
      subtitle: Text(
        member.isSelected
            ? currencyFormatter.format(member.amount)
            : 'Không tham gia',
      ),
      onChanged: (selected) => setState(() {
        member.isSelected = selected ?? false;
        if (!member.isSelected) {
          member.amount = 0;
          member.percentage = 0;
          _percentControllers[member.id]?.text = '0';
        }
        _recalculateSplit();
      }),
    ),
  );

  Widget _buildSplitPanel({
    required String keyName,
    required List<Widget> children,
  }) => Container(
    key: ValueKey(keyName),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: AppDimensions.radius12,
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );

  Widget _buildAmountSplitContent() {
    final sum = _members
        .where((member) => member.isSelected)
        .fold<double>(0, (sum, member) => sum + member.amount);
    final difference = _totalAmount - sum;
    return _buildSplitPanel(
      keyName: 'amount_split',
      children: [
        _buildNotice(
          difference.abs() < .01
              ? Icons.check_circle_outline
              : Icons.info_outline,
          difference.abs() < .01
              ? 'Tổng phần chia đã khớp khoản chi.'
              : difference > 0
              ? 'Cần chia thêm ${currencyFormatter.format(difference)}.'
              : 'Đã chia vượt ${currencyFormatter.format(-difference)}.',
        ),
        for (final member in _members) ...[
          _buildMemberSelection(member),
          if (member.isSelected)
            TextFormField(
              key: ValueKey('amount-${member.id}'),
              initialValue: member.amount > 0
                  ? member.amount.round().toString()
                  : '',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
              ],
              decoration: InputDecoration(
                labelText: 'Phần của ${member.name}',
                suffixText: 'VND',
              ),
              onChanged: (value) =>
                  setState(() => member.amount = double.tryParse(value) ?? 0),
            ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildPercentSplitContent() {
    final total = _members
        .where((member) => member.isSelected)
        .fold<double>(0, (sum, member) => sum + member.percentage);
    final remaining = 100 - total;
    return _buildSplitPanel(
      keyName: 'percent_split',
      children: [
        _buildNotice(
          (total - 100).abs() < .05
              ? Icons.check_circle_outline
              : Icons.info_outline,
          'Tổng phần chia: ${_formatPercent(total)}%. ${remaining.abs() < .05 ? 'Đã đủ 100%.' : 'Điều chỉnh để tổng bằng 100%.'}',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _splitEquallyPercent,
              icon: const Icon(Icons.pie_chart_outline),
              label: const Text('Chia đều %'),
            ),
            OutlinedButton.icon(
              onPressed: remaining > .05 ? () => _autoBalancePercent() : null,
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Bù cho người cuối'),
            ),
          ],
        ),
        for (final member in _members) ...[
          _buildMemberSelection(member),
          if (member.isSelected)
            TextFormField(
              controller: _percentControllers[member.id],
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Phần của ${member.name}',
                suffixText: '%',
              ),
              onChanged: (value) => _onPercentChanged(member, value),
            ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildWeightSplitContent() => _buildSplitPanel(
    keyName: 'weight_split',
    children: [
      _buildNotice(
        Icons.balance_outlined,
        'Hệ số càng lớn thì phần chia càng nhiều. Ví dụ: 2× nhận gấp đôi 1×.',
      ),
      for (final member in _members) ...[
        _buildMemberSelection(member),
        if (member.isSelected)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              IconButton.outlined(
                tooltip: 'Giảm hệ số của ${member.name}',
                icon: const Icon(Icons.remove),
                onPressed: member.weight <= .5
                    ? null
                    : () => setState(() {
                        member.weight -= .5;
                        _recalculateSplit();
                      }),
              ),
              Text(
                '${member.weight}×',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton.outlined(
                tooltip: 'Tăng hệ số của ${member.name}',
                icon: const Icon(Icons.add),
                onPressed: () => setState(() {
                  member.weight += .5;
                  _recalculateSplit();
                }),
              ),
            ],
          ),
        const Divider(height: 24),
      ],
    ],
  );

  // 5. Chia theo Món ăn / Món hàng (ITEM)
  void _syncItemParticipants() {
    for (final member in _members) {
      member.isSelected = _items.any(
        (item) => item.assignedMemberIds.contains(member.id),
      );
    }
  }

  Widget _buildItemSplitContent() => _buildSplitPanel(
    keyName: 'item_split',
    children: [
      Text(
        'Danh sách món (${_items.length})',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (!_scanMode)
            OutlinedButton.icon(
              onPressed: () => _addNewItemDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Thêm món'),
            ),
          if (!_scanMode && _items.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _amountController.text = _items
                    .fold<double>(0, (sum, item) => sum + item.price)
                    .round()
                    .toString();
                _recalculateSplit();
              }),
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Dùng tổng các món'),
            ),
        ],
      ),
      if (_items.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text('Thêm món hoặc quét hóa đơn để chia từng dòng hàng.'),
        ),
      for (final item in _items)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(item.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                currencyFormatter.format(item.price),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (!_scanMode)
                Wrap(
                  children: [
                    TextButton.icon(
                      onPressed: () => _addNewItemDialog(item),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Sửa món'),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _items.remove(item);
                        _syncItemParticipants();
                      }),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Xóa món'),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Text(
                'Ai cùng chia món này?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _members
                    .map(
                      (member) => FilterChip(
                        label: Text(member.name),
                        selected: item.assignedMemberIds.contains(member.id),
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            item.assignedMemberIds.add(member.id);
                          } else {
                            item.assignedMemberIds.remove(member.id);
                          }
                          _syncItemParticipants();
                        }),
                      ),
                    )
                    .toList(),
              ),
              const Divider(height: 24),
            ],
          ),
        ),
    ],
  );

  // Dialog Thêm món ăn mới thủ công
  Future<void> _addNewItemDialog([ExpenseItemDetail? existing]) async {
    final result =
        await showDialog<({String name, int quantity, double unitPrice})>(
          context: context,
          builder: (_) => _ExpenseItemEditor(
            name: existing?.name ?? '',
            quantity: existing?.quantity ?? 1,
            unitPrice: existing?.unitPrice ?? existing?.price,
          ),
        );
    if (!mounted || result == null) return;
    setState(() {
      if (existing == null) {
        _items.add(
          ExpenseItemDetail(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            name: result.name,
            price: result.quantity * result.unitPrice,
            quantity: result.quantity,
            unitPrice: result.unitPrice,
            assignedMemberIds: _members
                .where((member) => member.isSelected)
                .map((member) => member.id)
                .toList(),
          ),
        );
      } else {
        existing.name = result.name;
        existing.price = result.quantity * result.unitPrice;
        existing.quantity = result.quantity;
        existing.unitPrice = result.unitPrice;
      }
    });
  }

  // --- thanh NÚT LƯU KHOẢN CHI DƯỚI CÙNG (STICKY SUBMIT BAR) ---
  Widget _buildStickySubmitBar() {
    final scheme = Theme.of(context).colorScheme;
    final canSave =
        !_saving && !_isOcrScanning && (!_scanMode || _receipt != null);
    final selectedCount = _members.where((member) => member.isSelected).length;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final summary = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currencyFormatter.format(_totalAmount),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _scanMode && _receipt == null
                            ? 'Quét và kiểm tra hóa đơn để tiếp tục'
                            : '$selectedCount thành viên tham gia',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  );
                  final button = FilledButton.icon(
                    onPressed: canSave ? _saveExpense : null,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      _saving
                          ? tr(context, 'Đang lưu...', 'Saving...')
                          : tr(context, 'Lưu khoản chi', 'Save expense'),
                    ),
                  );
                  if (constraints.maxWidth < 480 ||
                      MediaQuery.textScalerOf(context).scale(14) > 20) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [summary, const SizedBox(height: 10), button],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: summary),
                      const SizedBox(width: 16),
                      button,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpenseItemEditor extends StatefulWidget {
  const _ExpenseItemEditor({
    required this.name,
    required this.quantity,
    this.unitPrice,
  });
  final String name;
  final int quantity;
  final double? unitPrice;

  @override
  State<_ExpenseItemEditor> createState() => _ExpenseItemEditorState();
}

class _ExpenseItemEditorState extends State<_ExpenseItemEditor> {
  late final _name = TextEditingController(text: widget.name);
  late final _quantity = TextEditingController(
    text: widget.quantity.toString(),
  );
  late final _unit = TextEditingController(
    text: widget.unitPrice?.round().toString() ?? '',
  );
  final _form = GlobalKey<FormState>();

  int get _lineTotal =>
      (int.tryParse(_quantity.text) ?? 0) * (int.tryParse(_unit.text) ?? 0);

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _unit.dispose();
    super.dispose();
  }

  void _submit() {
    if (_form.currentState?.validate() == true) {
      Navigator.pop(context, (
        name: _name.text.trim(),
        quantity: int.parse(_quantity.text),
        unitPrice: double.parse(_unit.text),
      ));
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: Text(widget.unitPrice == null ? 'Thêm món' : 'Sửa món'),
    content: SizedBox(
      width: 420,
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _name,
              maxLength: 160,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Tên món'),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Nhập tên món.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantity,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: const InputDecoration(labelText: 'Số lượng'),
              onChanged: (_) => setState(() {}),
              validator: (value) => (int.tryParse(value ?? '') ?? 0) <= 0
                  ? 'Số lượng phải lớn hơn 0.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _unit,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
              ],
              decoration: const InputDecoration(
                labelText: 'Đơn giá',
                suffixText: 'VND',
              ),
              onChanged: (_) => setState(() {}),
              onFieldSubmitted: (_) => _submit(),
              validator: (value) => (int.tryParse(value ?? '') ?? 0) <= 0
                  ? 'Nhập đơn giá lớn hơn 0.'
                  : _lineTotal > 999999999999
                  ? 'Thành tiền vượt giới hạn. Kiểm tra số lượng và đơn giá.'
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              'Thành tiền: ${NumberFormat.decimalPattern('vi_VN').format(_lineTotal)} đ',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Lưu món')),
    ],
  );
}
