import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import 'expense_detail_screen.dart';

/// ----------------------------------------------------------------------------
/// DỮ LIỆU MẪU BAN ĐẦU CHO MÀN HÌNH TẠO KHOẢN CHI
/// ----------------------------------------------------------------------------
class CategoryItem {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

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
  List<String> assignedMemberIds;

  ExpenseItemDetail({
    required this.id,
    required this.name,
    required this.price,
    required this.assignedMemberIds,
  });
}

enum SplitMode { equal, amount, percent, weight, item }

/// ----------------------------------------------------------------------------
/// MÀN HÌNH TẠO KHOẢN CHI CHI TIẾT (CREATE EXPENSE SCREEN)
/// Chuyển động mượt mà, đầy đủ các chế độ chia tiền & chuẩn Design Tokens
/// ----------------------------------------------------------------------------
class CreateExpenseScreen extends ConsumerStatefulWidget {
  const CreateExpenseScreen({super.key});

  @override
  ConsumerState<CreateExpenseScreen> createState() => _CreateExpenseScreenState();
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
  final Map<String, TextEditingController> _percentControllers = {};

  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  // Danh mục khoản chi
  final List<CategoryItem> _categories = const [
    CategoryItem(id: 'food', name: 'Ăn uống', icon: Icons.restaurant_rounded, color: Color(0xFFFF7675)),
    CategoryItem(id: 'transport', name: 'Di chuyển', icon: Icons.directions_car_rounded, color: Color(0xFF74B9FF)),
    CategoryItem(id: 'shopping', name: 'Mua sắm', icon: Icons.shopping_bag_rounded, color: Color(0xFFA29BFE)),
    CategoryItem(id: 'entertainment', name: 'Giải trí', icon: Icons.local_activity_rounded, color: Color(0xFFFD79A8)),
    CategoryItem(id: 'stay', name: 'Khách sạn', icon: Icons.hotel_rounded, color: Color(0xFF55E6C1)),
    CategoryItem(id: 'other', name: 'Khác', icon: Icons.more_horiz_rounded, color: Color(0xFFB2BEC3)),
  ];

  late CategoryItem _selectedCategory;

  // Danh sách thành viên nhóm mẫu
  late List<GroupMemberItem> _members;
  late String _payerId;

  // Chế độ chia tiền
  SplitMode _splitMode = SplitMode.equal;

  // Danh sách item nếu dùng chế độ chia theo Món (SplitMode.item)
  List<ExpenseItemDetail> _items = [];

  // Ảnh hóa đơn đính kèm (giả lập)
  bool _hasReceipt = false;
  bool _isOcrScanning = false;


  @override
  void initState() {
    super.initState();

    _selectedCategory = _categories.first;

    // Khởi tạo thành viên nhóm mẫu
    _members = [
      GroupMemberItem(id: 'u1', name: 'Đạt (Tôi)', avatarUrl: 'https://i.pravatar.cc/150?img=11', isSelected: true),
      GroupMemberItem(id: 'u2', name: 'Hoàng (Dev 1)', avatarUrl: 'https://i.pravatar.cc/150?img=12', isSelected: true),
      GroupMemberItem(id: 'u3', name: 'Minh (Dev 3)', avatarUrl: 'https://i.pravatar.cc/150?img=13', isSelected: true),
      GroupMemberItem(id: 'u4', name: 'Trang (Dev 4)', avatarUrl: 'https://i.pravatar.cc/150?img=5', isSelected: true),
    ];
    _payerId = _members.first.id;

    _initPercentControllers();

    // Animation khởi tạo
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();
    _recalculateSplit();
  }

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
    return p.toStringAsFixed(1);
  }

  void _initPercentControllers() {
    for (var m in _members) {
      _percentControllers[m.id] = TextEditingController(
        text: m.isSelected && m.percentage > 0 ? _formatPercent(m.percentage) : (m.isSelected ? '0' : ''),
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
    final basePct = double.parse((100.0 / count).toStringAsFixed(1));
    double runningSum = 0.0;

    for (int i = 0; i < count; i++) {
      if (i == count - 1) {
        selected[i].percentage = double.parse((100.0 - runningSum).toStringAsFixed(1));
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
    final roundedRemaining = double.parse(remaining.toStringAsFixed(1));

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
          ? (selectedMembers.length >= 2 ? selectedMembers[selectedMembers.length - 2] : null)
          : selectedMembers.last;

      if (targetMember != null && targetMember.id != editedMember.id) {
        final sumOthers = selectedMembers
            .where((m) => m.id != targetMember.id)
            .fold(0.0, (s, m) => s + m.percentage);
        final remaining = 100.0 - sumOthers;
        if (remaining >= 0) {
          final roundedRemaining = double.parse(remaining.toStringAsFixed(1));
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
    if (selectedCount == 0 || _totalAmount <= 0) return;

    if (_splitMode == SplitMode.equal) {
      final perPerson = _totalAmount / selectedCount;
      for (var m in _members) {
        if (m.isSelected) {
          m.amount = perPerson;
          m.percentage = 100.0 / selectedCount;
        } else {
          m.amount = 0.0;
          m.percentage = 0.0;
        }
      }
    } else if (_splitMode == SplitMode.percent) {
      final totalPct = selectedMembers.fold(0.0, (s, m) => s + m.percentage);
      if (totalPct == 0.0) {
        final defaultPct = double.parse((100.0 / selectedCount).toStringAsFixed(1));
        double runningSum = 0.0;
        for (int i = 0; i < selectedCount; i++) {
          if (i == selectedCount - 1) {
            selectedMembers[i].percentage = double.parse((100.0 - runningSum).toStringAsFixed(1));
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
      final totalWeight = _members.where((m) => m.isSelected).fold(0.0, (sum, m) => sum + m.weight);
      for (var m in _members) {
        if (m.isSelected && totalWeight > 0) {
          m.amount = (_totalAmount * m.weight) / totalWeight;
          m.percentage = (m.weight / totalWeight) * 100.0;
        }
      }
    }
  }

  // Cộng nhanh số tiền (+50k, +100k...)
  void _addQuickAmount(double value) {
    HapticFeedback.lightImpact();
    final current = _totalAmount;
    final updated = current + value;
    _amountController.text = currencyFormatter.format(updated).replaceAll('₫', '').trim();
    setState(() {
      _recalculateSplit();
    });
  }

  // Giả lập AI OCR Scan Hóa đơn
  Future<void> _scanReceiptOCR() async {
    setState(() {
      _isOcrScanning = true;
    });

    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      _isOcrScanning = false;
      _hasReceipt = true;
      _titleController.text = 'Ăn lẩu nướng Gogi House';
      _amountController.text = '680.000';
      _selectedCategory = _categories[0]; // Ăn uống
      _items = [
        ExpenseItemDetail(id: 'i1', name: 'Buffet Thịt Nướng Premium', price: 500000, assignedMemberIds: ['u1', 'u2', 'u3', 'u4']),
        ExpenseItemDetail(id: 'i2', name: 'Nước ngọt & Bia', price: 120000, assignedMemberIds: ['u1', 'u2']),
        ExpenseItemDetail(id: 'i3', name: 'Món tráng miệng', price: 60000, assignedMemberIds: ['u3', 'u4']),
      ];
      _splitMode = SplitMode.item;
      _recalculateSplit();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
              SizedBox(width: AppDimensions.s8),
              Text('AI đã trích xuất hóa đơn 680.000₫ thành công!'),
            ],
          ),
          backgroundColor: AppColors.p700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 95, left: 16, right: 16),
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: AppDimensions.radius12),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.n50,
      appBar: _buildAppBar(context),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.s20, vertical: AppDimensions.s12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- 1. NHÓM VÀ TỔNG SỐ TIỀN ---
                      _buildAmountInputCard(),
                      const SizedBox(height: AppDimensions.s20),

                      // --- 2. TÊN KHOẢN CHI & DANH MỤC ---
                      _buildTitleAndCategoryCard(),
                      const SizedBox(height: AppDimensions.s20),

                      // --- 3. AI SCAN HÓA ĐƠN RECEIPT ---
                      _buildReceiptSection(),
                      const SizedBox(height: AppDimensions.s20),

                      // --- 4. NGƯỜI TRẢ TIỀN (PAYER) ---
                      _buildPayerSelectorCard(),
                      const SizedBox(height: AppDimensions.s20),

                      // --- 5. CHẾ ĐỘ CHIA TIỀN (SPLIT MODES) ---
                      _buildSplitModeSection(),
                      const SizedBox(height: AppDimensions.s24),
                    ],
                  ),
                ),
              ),

              // --- 6. NÚT LƯU KHOẢN CHI THỦ CÔNG / SUBMIT ---
              _buildStickySubmitBar(),
            ],
          ),
        ),
      ),
    );
  }

  // --- APP BAR VỚI BADGE NHÓM DU LỊCH ---
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.n50,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.n0,
            shape: BoxShape.circle,
            boxShadow: AppDimensions.shadowSm,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.n800),
        ),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Column(
        children: [
          Text('Tạo khoản chi mới', style: AppTypography.title.copyWith(fontSize: 16)),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.p50,
              borderRadius: AppDimensions.radius8,
              border: Border.all(color: AppColors.p200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.groups_rounded, size: 12, color: AppColors.p500),
                const SizedBox(width: 4),
                Text('Du Lịch Hà Giang', style: AppTypography.caption.copyWith(color: AppColors.p700, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.n700),
          onPressed: () {},
        ),
      ],
    );
  }

  // --- CARD Ô NHẬP TỔNG SỐ TIỀN & PHÍM NGHỆ THUẬT ---
  Widget _buildAmountInputCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.s20),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppDimensions.radius24,
        boxShadow: AppDimensions.shadowMd,
        border: Border.all(color: AppColors.p100.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text('TỔNG SỐ TIỀN', style: AppTypography.caption.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700, color: AppColors.n500)),
          const SizedBox(height: AppDimensions.s8),

          // Ô nhập số tiền lớn
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: IntrinsicWidth(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: AppTypography.display.copyWith(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: AppColors.p500,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(color: AppColors.n300),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) {
                      setState(() {
                        _recalculateSplit();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text('₫', style: AppTypography.h2.copyWith(color: AppColors.p500, fontWeight: FontWeight.w700)),
            ],
          ),

          const SizedBox(height: AppDimensions.s16),

          // Chips cộng nhanh tiền
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildQuickAmountChip('+50K', 50000),
                _buildQuickAmountChip('+100K', 100000),
                _buildQuickAmountChip('+200K', 200000),
                _buildQuickAmountChip('+500K', 500000),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountChip(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(right: AppDimensions.s8),
      child: InkWell(
        onTap: () => _addQuickAmount(amount),
        borderRadius: AppDimensions.radius12,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.p50,
            borderRadius: AppDimensions.radius12,
            border: Border.all(color: AppColors.p200),
          ),
          child: Text(label, style: AppTypography.label.copyWith(color: AppColors.p600, fontSize: 13)),
        ),
      ),
    );
  }

  // --- CARD TIÊU ĐỀ KHOẢN CHI & DANH MỤC HORIZONTAL SCROLL ---
  Widget _buildTitleAndCategoryCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.s16),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppDimensions.radius20,
        boxShadow: AppDimensions.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề khoản chi
          TextField(
            controller: _titleController,
            style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Nhập tên khoản chi (Ví dụ: Ăn lẩu nướng)',
              hintStyle: AppTypography.bodyLarge.copyWith(color: AppColors.n400),
              prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.p500),
              border: InputBorder.none,
            ),
          ),

          const Divider(height: 20, color: AppColors.n100),

          // Chọn Danh Mục
          Text('Danh mục', style: AppTypography.label.copyWith(fontSize: 13, color: AppColors.n600)),
          const SizedBox(height: AppDimensions.s12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = cat.id == _selectedCategory.id;
                return Padding(
                  padding: const EdgeInsets.only(right: AppDimensions.s12),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                    borderRadius: AppDimensions.radius16,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? cat.color.withOpacity(0.15) : AppColors.n50,
                        borderRadius: AppDimensions.radius16,
                        border: Border.all(
                          color: isSelected ? cat.color : AppColors.n200,
                          width: isSelected ? 2.0 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(cat.icon, size: 18, color: isSelected ? cat.color : AppColors.n600),
                          const SizedBox(width: 8),
                          Text(
                            cat.name,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? cat.color : AppColors.n700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --- KHU VỰC AI SCAN HÓA ĐƠN OCR ---
  Widget _buildReceiptSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.s16),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppDimensions.radius20,
        boxShadow: AppDimensions.shadowSm,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.p50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.document_scanner_rounded, color: AppColors.p500, size: 20),
              ),
              const SizedBox(width: AppDimensions.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hóa đơn & AI Scan OCR', style: AppTypography.label.copyWith(fontSize: 14)),
                    Text('Quét tự động tên món ăn & số tiền từ ảnh', style: AppTypography.caption),
                  ],
                ),
              ),
              if (_isOcrScanning)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.p500),
                )
              else
                OutlinedButton.icon(
                  onPressed: _scanReceiptOCR,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.p500),
                    shape: RoundedRectangleBorder(borderRadius: AppDimensions.radius12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.auto_awesome, size: 16, color: AppColors.p500),
                  label: Text(_hasReceipt ? 'Quét lại' : 'Quét bill', style: AppTypography.label.copyWith(color: AppColors.p500, fontSize: 13)),
                ),
            ],
          ),
          if (_hasReceipt) ...[
            const SizedBox(height: AppDimensions.s12),
            Container(
              padding: const EdgeInsets.all(AppDimensions.s12),
              decoration: BoxDecoration(
                color: AppColors.successTint,
                borderRadius: AppDimensions.radius12,
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                  const SizedBox(width: AppDimensions.s8),
                  Expanded(
                    child: Text('Đã nhận diện hóa đơn 680.000₫ & tự động bóc tách 3 món ăn!', style: AppTypography.bodySmall.copyWith(color: AppColors.n800, fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: AppColors.n600),
                    onPressed: () {
                      setState(() {
                        _hasReceipt = false;
                      });
                    },
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  // --- CARD CHỌN NGƯỜI TRẢ TIỀN (PAYER) ---
  Widget _buildPayerSelectorCard() {
    final currentPayer = _members.firstWhere((m) => m.id == _payerId);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.s16),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppDimensions.radius20,
        boxShadow: AppDimensions.shadowSm,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(currentPayer.avatarUrl),
          ),
          const SizedBox(width: AppDimensions.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Người ứng tiền trước', style: AppTypography.caption.copyWith(color: AppColors.n500)),
                Text(currentPayer.name, style: AppTypography.title.copyWith(fontSize: 15)),
              ],
            ),
          ),
          DropdownButton<String>(
            value: _payerId,
            underline: const SizedBox(),
            icon: const Icon(Icons.swap_vert_rounded, color: AppColors.p500),
            items: _members.map((m) {
              return DropdownMenuItem<String>(
                value: m.id,
                child: Text(m.name, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _payerId = val;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  // --- PHẦN CHỌN CHẾ ĐỘ CHIA TIỀN (5 MODES) VỚI TAB CHUYỂN ĐỘNG ---
  Widget _buildSplitModeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CHẾ ĐỘ CHIA TIỀN', style: AppTypography.label.copyWith(fontSize: 13, letterSpacing: 0.8, color: AppColors.n600)),
        const SizedBox(height: AppDimensions.s12),

        // Thanh Tab chuyển chế độ chia
        Container(
          decoration: BoxDecoration(
            color: AppColors.n200.withOpacity(0.5),
            borderRadius: AppDimensions.radius16,
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _buildSplitTabItem('Chia đều', SplitMode.equal, Icons.pie_chart_rounded),
              _buildSplitTabItem('Số tiền', SplitMode.amount, Icons.attach_money_rounded),
              _buildSplitTabItem('%', SplitMode.percent, Icons.percent_rounded),
              _buildSplitTabItem('Hệ số', SplitMode.weight, Icons.balance_rounded),
              _buildSplitTabItem('Theo món', SplitMode.item, Icons.fastfood_rounded),
            ],
          ),
        ),

        const SizedBox(height: AppDimensions.s16),

        // Nội dung từng chế độ chia
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _buildActiveSplitContent(),
        ),
      ],
    );
  }

  Widget _buildSplitTabItem(String label, SplitMode mode, IconData icon) {
    final isSelected = _splitMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _splitMode = mode;
            _recalculateSplit();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.n0 : Colors.transparent,
            borderRadius: AppDimensions.radius12,
            boxShadow: isSelected ? AppDimensions.shadowSm : null,
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: isSelected ? AppColors.p500 : AppColors.n600),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.p600 : AppColors.n600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Nội dung render tương ứng với Split Mode đang chọn
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
    final perPerson = selectedMembers.isNotEmpty ? _totalAmount / selectedMembers.length : 0.0;

    return Container(
      key: const ValueKey('equal_split'),
      padding: const EdgeInsets.all(AppDimensions.s16),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppDimensions.radius20,
        boxShadow: AppDimensions.shadowSm,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tự động chia đều cho ${selectedMembers.length} người', style: AppTypography.bodySmall.copyWith(color: AppColors.n600)),
              Text('${currencyFormatter.format(perPerson)} /người', style: AppTypography.title.copyWith(color: AppColors.p600, fontSize: 14)),
            ],
          ),
          const Divider(height: 20, color: AppColors.n100),
          ..._members.map((m) {
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.p500,
              shape: RoundedRectangleBorder(borderRadius: AppDimensions.radius12),
              secondary: CircleAvatar(radius: 16, backgroundImage: NetworkImage(m.avatarUrl)),
              title: Text(m.name, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text(m.isSelected ? currencyFormatter.format(perPerson) : 'Không tham gia',
                  style: AppTypography.caption.copyWith(color: m.isSelected ? AppColors.p600 : AppColors.n400)),
              value: m.isSelected,
              onChanged: (val) {
                setState(() {
                  m.isSelected = val ?? false;
                  _recalculateSplit();
                });
              },
            );
          }),
        ],
      ),
    );
  }

  // 2. Chia theo Số tiền cụ thể (AMOUNT)
  Widget _buildAmountSplitContent() {
    final sum = _members.fold(0.0, (s, m) => s + (m.isSelected ? m.amount : 0.0));
    final diff = _totalAmount - sum;
    final isExact = diff.abs() < 1.0;

    return Container(
      key: const ValueKey('amount_split'),
      padding: const EdgeInsets.all(AppDimensions.s16),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppDimensions.radius20,
        boxShadow: AppDimensions.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner cảnh báo lệch số tiền
          Container(
            padding: const EdgeInsets.all(AppDimensions.s12),
            decoration: BoxDecoration(
              color: isExact ? AppColors.successTint : AppColors.warningTint,
              borderRadius: AppDimensions.radius12,
            ),
            child: Row(
              children: [
                Icon(isExact ? Icons.check_circle_rounded : Icons.warning_rounded,
                    color: isExact ? AppColors.success : AppColors.warning, size: 20),
                const SizedBox(width: AppDimensions.s8),
                Expanded(
                  child: Text(
                    isExact ? 'Tổng số tiền nhập vào vừa đủ 100%!' : 'Còn thiếu: ${currencyFormatter.format(diff)}',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isExact ? AppColors.success : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.s12),
          ..._members.map((m) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.s12),
              child: Row(
                children: [
                  CircleAvatar(radius: 16, backgroundImage: NetworkImage(m.avatarUrl)),
                  const SizedBox(width: AppDimensions.s8),
                  Expanded(child: Text(m.name, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600))),
                  SizedBox(
                    width: 120,
                    height: 40,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.p600),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: '0 ₫',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        fillColor: AppColors.n50,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: AppDimensions.radius12, borderSide: const BorderSide(color: AppColors.n200)),
                      ),
                      onChanged: (val) {
                        final valNum = double.tryParse(val) ?? 0.0;
                        setState(() {
                          m.amount = valNum;
                        });
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 3. Chia theo Phần trăm % (PERCENT)
  Widget _buildPercentSplitContent() {
    final selectedMembers = _members.where((m) => m.isSelected).toList();
    final totalPct = selectedMembers.fold(0.0, (s, m) => s + m.percentage);
    final isExact = (totalPct - 100.0).abs() < 0.05;
    final isOver = totalPct > 100.05;
    final remainingPct = (100.0 - totalPct);

    return Container(
      key: const ValueKey('percent_split'),
      padding: const EdgeInsets.all(AppDimensions.s16),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppDimensions.radius20,
        boxShadow: AppDimensions.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner trạng thái tổng phần trăm
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.s12, vertical: AppDimensions.s8),
            decoration: BoxDecoration(
              color: isExact
                  ? AppColors.successTint
                  : (isOver ? AppColors.errorTint : AppColors.warningTint),
              borderRadius: AppDimensions.radius12,
              border: Border.all(
                color: isExact
                    ? AppColors.success.withOpacity(0.3)
                    : (isOver ? AppColors.error.withOpacity(0.3) : AppColors.warning.withOpacity(0.3)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isExact
                      ? Icons.check_circle_rounded
                      : (isOver ? Icons.warning_rounded : Icons.info_rounded),
                  color: isExact
                      ? AppColors.success
                      : (isOver ? AppColors.error : AppColors.warning),
                  size: 20,
                ),
                const SizedBox(width: AppDimensions.s8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isExact
                            ? 'Tổng phần trăm: 100% (Đạt chuẩn)'
                            : isOver
                                ? 'Tổng phần trăm: ${_formatPercent(totalPct)}% (Vượt quá ${_formatPercent(totalPct - 100)}%)'
                                : 'Tổng phần trăm: ${_formatPercent(totalPct)}% (Còn thiếu ${_formatPercent(remainingPct)}%)',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isExact
                              ? AppColors.success
                              : (isOver ? AppColors.error : AppColors.warning),
                        ),
                      ),
                      Text(
                        isExact
                            ? 'Các phần chia đã khớp hoàn toàn 100%.'
                            : 'Nhập số % cho từng người (tự động tính phần người cuối).',
                        style: AppTypography.caption.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.s12),

          // Thanh công cụ nhanh: Chia đều % và Tự bù 100%
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _splitEquallyPercent,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    side: const BorderSide(color: AppColors.p300),
                    shape: RoundedRectangleBorder(borderRadius: AppDimensions.radius12),
                    backgroundColor: AppColors.p50.withOpacity(0.5),
                  ),
                  icon: const Icon(Icons.pie_chart_outline_rounded, size: 16, color: AppColors.p600),
                  label: Text('Chia đều %', style: AppTypography.label.copyWith(fontSize: 12, color: AppColors.p600)),
                ),
              ),
              const SizedBox(width: AppDimensions.s8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: remainingPct > 0.05 ? () => _autoBalancePercent() : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    side: BorderSide(color: remainingPct > 0.05 ? AppColors.p500 : AppColors.n300),
                    shape: RoundedRectangleBorder(borderRadius: AppDimensions.radius12),
                    backgroundColor: remainingPct > 0.05 ? AppColors.p50 : AppColors.n100.withOpacity(0.3),
                  ),
                  icon: Icon(Icons.auto_fix_high_rounded, size: 16, color: remainingPct > 0.05 ? AppColors.p500 : AppColors.n400),
                  label: Text('Tự bù 100%', style: AppTypography.label.copyWith(fontSize: 12, color: remainingPct > 0.05 ? AppColors.p600 : AppColors.n400)),
                ),
              ),
            ],
          ),

          const Divider(height: 24, color: AppColors.n100),

          // Danh sách từng thành viên
          ..._members.map((m) {
            final ctrl = _percentControllers[m.id];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.s12),
              child: Row(
                children: [
                  Checkbox(
                    value: m.isSelected,
                    activeColor: AppColors.p500,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) {
                      setState(() {
                        m.isSelected = val ?? false;
                        if (!m.isSelected) {
                          m.percentage = 0.0;
                          m.amount = 0.0;
                          _percentControllers[m.id]?.text = '0';
                        }
                        _recalculateSplit();
                      });
                    },
                  ),
                  CircleAvatar(radius: 16, backgroundImage: NetworkImage(m.avatarUrl)),
                  const SizedBox(width: AppDimensions.s8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.name, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                        Text(
                          m.isSelected ? currencyFormatter.format(m.amount) : 'Không tham gia',
                          style: AppTypography.caption.copyWith(
                            color: m.isSelected ? AppColors.p600 : AppColors.n400,
                            fontWeight: m.isSelected ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (m.isSelected) ...[
                    if (remainingPct > 0.1 && (100.0 - totalPct + m.percentage) > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () => _autoBalancePercent(m),
                          borderRadius: AppDimensions.radius8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.p50,
                              borderRadius: AppDimensions.radius8,
                              border: Border.all(color: AppColors.p200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add_rounded, size: 12, color: AppColors.p600),
                                Text('Bù', style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.p600, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    SizedBox(
                      width: 85,
                      height: 42,
                      child: TextField(
                        controller: ctrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.right,
                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.p600, fontSize: 15),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d{0,2}')),
                        ],
                        decoration: InputDecoration(
                          hintText: '0',
                          suffixText: '%',
                          suffixStyle: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.p500),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          fillColor: AppColors.n50,
                          filled: true,
                          border: OutlineInputBorder(borderRadius: AppDimensions.radius12, borderSide: const BorderSide(color: AppColors.n200)),
                          enabledBorder: OutlineInputBorder(borderRadius: AppDimensions.radius12, borderSide: const BorderSide(color: AppColors.n200)),
                          focusedBorder: OutlineInputBorder(borderRadius: AppDimensions.radius12, borderSide: const BorderSide(color: AppColors.p500, width: 1.8)),
                        ),
                        onChanged: (val) => _onPercentChanged(m, val),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 4. Chia theo Tỷ trọng / Hệ số (WEIGHT)
  Widget _buildWeightSplitContent() {
    return Container(
      key: const ValueKey('weight_split'),
      padding: const EdgeInsets.all(AppDimensions.s16),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppDimensions.radius20,
        boxShadow: AppDimensions.shadowSm,
      ),
      child: Column(
        children: _members.map((m) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.s12),
            child: Row(
              children: [
                CircleAvatar(radius: 16, backgroundImage: NetworkImage(m.avatarUrl)),
                const SizedBox(width: AppDimensions.s8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.name, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                      Text(currencyFormatter.format(m.amount), style: AppTypography.caption.copyWith(color: AppColors.p600, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),

                // Bộ tăng giảm Hệ số (+ / -)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.n50,
                    borderRadius: AppDimensions.radius12,
                    border: Border.all(color: AppColors.n200),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 16, color: AppColors.n700),
                        onPressed: () {
                          if (m.weight > 0.5) {
                            setState(() {
                              m.weight -= 0.5;
                              _recalculateSplit();
                            });
                          }
                        },
                      ),
                      Text('${m.weight}x', style: AppTypography.label.copyWith(color: AppColors.p600)),
                      IconButton(
                        icon: const Icon(Icons.add, size: 16, color: AppColors.p600),
                        onPressed: () {
                          setState(() {
                            m.weight += 0.5;
                            _recalculateSplit();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // 5. Chia theo Món ăn / Món hàng (ITEM)
  Widget _buildItemSplitContent() {
    return Container(
      key: const ValueKey('item_split'),
      padding: const EdgeInsets.all(AppDimensions.s16),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppDimensions.radius20,
        boxShadow: AppDimensions.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Danh sách món ăn (${_items.length})', style: AppTypography.label),
              TextButton.icon(
                onPressed: _addNewItemDialog,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: AppColors.p500),
                label: Text('Thêm món', style: AppTypography.label.copyWith(color: AppColors.p500, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s8),
          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('Bấm "Quét bill" hoặc "Thêm món" để chia từng món ăn!', style: AppTypography.caption),
              ),
            )
          else
            ..._items.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: AppDimensions.s12),
                padding: const EdgeInsets.all(AppDimensions.s12),
                decoration: BoxDecoration(
                  color: AppColors.n50,
                  borderRadius: AppDimensions.radius12,
                  border: Border.all(color: AppColors.n200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item.name, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                        Text(currencyFormatter.format(item.price), style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.p600)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: _members.map((m) {
                        final isAssigned = item.assignedMemberIds.contains(m.id);
                        return FilterChip(
                          label: Text(m.name, style: TextStyle(fontSize: 11, color: isAssigned ? AppColors.p700 : AppColors.n600)),
                          selected: isAssigned,
                          selectedColor: AppColors.p100,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                item.assignedMemberIds.add(m.id);
                              } else {
                                item.assignedMemberIds.remove(m.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // Dialog Thêm món ăn mới thủ công
  void _addNewItemDialog() {
    final itemNameCtrl = TextEditingController();
    final itemPriceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppDimensions.radius20),
          title: Text('Thêm món ăn mới', style: AppTypography.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: itemNameCtrl,
                decoration: const InputDecoration(labelText: 'Tên món (Ví dụ: Lẩu thái)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: itemPriceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Giá món (₫)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (itemNameCtrl.text.isNotEmpty && itemPriceCtrl.text.isNotEmpty) {
                  final price = double.tryParse(itemPriceCtrl.text) ?? 0;
                  setState(() {
                    _items.add(ExpenseItemDetail(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: itemNameCtrl.text,
                      price: price,
                      assignedMemberIds: _members.map((m) => m.id).toList(),
                    ));
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );
  }

  // --- thanh NÚT LƯU KHOẢN CHI DƯỚI CÙNG (STICKY SUBMIT BAR) ---
  Widget _buildStickySubmitBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.s20, vertical: AppDimensions.s16),
      decoration: BoxDecoration(
        color: AppColors.n0,
        boxShadow: AppDimensions.shadowLg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.r24)),
      ),
      child: SafeArea(
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                    SizedBox(width: AppDimensions.s8),
                    Text('Đã lưu khoản chi thành công!'),
                  ],
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(bottom: 95, left: 16, right: 16),
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(borderRadius: AppDimensions.radius12),
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ExpenseDetailScreen(
                  expenseData: ExpenseDetailModel(
                    id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
                    title: _titleController.text.isEmpty ? 'Khoản chi mới' : _titleController.text,
                    totalAmount: _totalAmount > 0 ? _totalAmount : 680000,
                    categoryName: _selectedCategory.name,
                    categoryIcon: _selectedCategory.icon,
                    categoryColor: _selectedCategory.color,
                    payerName: _members.firstWhere((m) => m.id == _payerId).name,
                    payerAvatar: _members.firstWhere((m) => m.id == _payerId).avatarUrl,
                    createdAt: DateTime.now(),
                    groupName: 'Du Lịch Hà Giang',
                    splitModeName: _splitMode == SplitMode.equal
                        ? 'Chia đều (EQUAL)'
                        : _splitMode == SplitMode.amount
                            ? 'Số tiền (AMOUNT)'
                            : _splitMode == SplitMode.percent
                                ? 'Phần trăm (PERCENT)'
                                : _splitMode == SplitMode.weight
                                    ? 'Tỷ trọng (WEIGHT)'
                                    : 'Theo món (ITEM)',
                    isSettled: false,
                    receiptUrl: _hasReceipt
                        ? 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=600&q=80'
                        : null,
                    participants: _members.where((m) => m.isSelected).map((m) {
                      return ExpenseParticipantDetail(
                        name: m.name,
                        avatarUrl: m.avatarUrl,
                        amount: m.amount,
                        isPayer: m.id == _payerId,
                      );
                    }).toList(),
                  ),
                ),
              ),
            );
          },
          borderRadius: AppDimensions.radius20,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: AppDimensions.radius20,
              boxShadow: [
                BoxShadow(
                  color: AppColors.p500.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_rounded, color: Colors.white, size: 22),
                const SizedBox(width: AppDimensions.s8),
                Text('LƯU KHOẢN CHI', style: AppTypography.title.copyWith(color: Colors.white, fontSize: 16, letterSpacing: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
