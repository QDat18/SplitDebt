import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/premium_ui.dart';
import '../../widgets/design.dart';

class QuickGuideScreen extends StatefulWidget {
  const QuickGuideScreen({super.key, this.markCompleted = true});

  final bool markCompleted;

  @override
  State<QuickGuideScreen> createState() => _QuickGuideScreenState();
}

class _QuickGuideScreenState extends State<QuickGuideScreen> {
  final controller = PageController();
  int page = 0;

  static const _slides = <_GuideSlide>[
    _GuideSlide(
      eyebrow: 'BƯỚC 1 · TRANG CHỦ',
      title: 'Nắm nhanh tình hình của bạn',
      description: 'Trang Tổng quan gom số tiền bạn đang nợ, được nhận và các nhóm gần đây vào một nơi.',
      icon: Icons.space_dashboard_rounded,
      steps: [
        'Xem “Bạn được nhận” và “Bạn đang nợ” theo từng loại tiền.',
        'Chạm một nhóm gần đây để xem khoản chi và công nợ chi tiết.',
        'Biểu tượng chuông mở thông báo về khoản chi và thanh toán.',
      ],
      tip: 'Bạn luôn có thể mở lại hướng dẫn bằng nút ? ở góc trên.',
      preview: _PreviewType.home,
    ),
    _GuideSlide(
      eyebrow: 'BƯỚC 2 · LẬP NHÓM',
      title: 'Tạo nhóm trước khi chia tiền',
      description: 'Mỗi chuyến đi, phòng trọ hoặc nhóm bạn nên có một nhóm riêng để dữ liệu dễ theo dõi.',
      icon: Icons.group_add_rounded,
      steps: [
        'Nhấn “Tạo nhóm” và đặt tên dễ nhận biết.',
        'Chọn tiền tệ của nhóm: VND, USD hoặc EUR.',
        'Chia sẻ mã mời để mọi người tự tham gia hoặc thêm họ bằng email.',
      ],
      tip: 'Chỉ Trưởng nhóm mới có quyền quản lý thành viên và một số cài đặt nhóm.',
      preview: _PreviewType.group,
    ),
    _GuideSlide(
      eyebrow: 'BƯỚC 3 · THÊM KHOẢN CHI',
      title: 'Chọn cách chia phù hợp',
      description: 'SplitDebt hỗ trợ nhiều kiểu chia để sát với tình huống thực tế thay vì ép mọi khoản chi phải chia đều.',
      icon: Icons.receipt_long_rounded,
      steps: [
        'Nhập tổng tiền, người đã trả, ngày và người tham gia.',
        'Chọn Chia đều, Theo số tiền, %, Trọng số hoặc Theo từng món.',
        'Kiểm tra tổng phần chia rồi lưu. Công nợ sẽ được tính lại tự động.',
      ],
      tip: 'Nếu chia theo món, mỗi món cần có tên, số tiền và người sử dụng món đó.',
      preview: _PreviewType.expense,
    ),
    _GuideSlide(
      eyebrow: 'BƯỚC 4 · XÉN NỢ',
      title: 'Quyết toán ít giao dịch hơn',
      description: 'Smart Settlement dùng số dư ròng để đề xuất ai nên trả ai, giảm các khoản nợ chéo không cần thiết.',
      icon: Icons.auto_awesome_rounded,
      steps: [
        'Mở tab Công nợ trong nhóm để xem số dư từng thành viên.',
        'Xem đề xuất Smart Settlement và số tiền cần thanh toán.',
        'Người trả đánh dấu đã thanh toán; người nhận xác nhận đã nhận tiền.',
      ],
      tip: 'SplitDebt chỉ ghi nhận giao dịch ngoài hệ thống, không tự chuyển tiền từ ngân hàng/ví.',
      preview: _PreviewType.settlement,
    ),
  ];

  Future<void> finish() async {
    if (widget.markCompleted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('quick_guide_completed', true);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PremiumBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Đóng hướng dẫn',
                    ),
                    const Spacer(),
                    Text(
                      '${page + 1}/${_slides.length}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: controller,
                  itemCount: _slides.length,
                  onPageChanged: (value) => setState(() => page = value),
                  itemBuilder: (context, index) => _GuidePage(slide: _slides[index]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (i) => AnimatedContainer(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == page ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == page ? AppColors.primary : Theme.of(context).dividerColor,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 17),
                    Row(
                      children: [
                        if (page > 0) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => controller.previousPage(
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeOutCubic,
                              ),
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: const Text('Quay lại'),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          flex: 2,
                          child: BrandButton(
                            label: page == _slides.length - 1 ? 'Hoàn tất hướng dẫn' : 'Tiếp tục',
                            icon: page == _slides.length - 1 ? Icons.check_rounded : Icons.arrow_forward_rounded,
                            onPressed: page == _slides.length - 1
                                ? finish
                                : () => controller.nextPage(
                                      duration: const Duration(milliseconds: 260),
                                      curve: Curves.easeOutCubic,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuidePage extends StatelessWidget {
  const _GuidePage({required this.slide});
  final _GuideSlide slide;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Entrance(
                  child: GlassSurface(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Orb(icon: slide.icon, size: 64),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    slide.eyebrow,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      letterSpacing: 1.7,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(slide.title, style: Theme.of(context).textTheme.headlineSmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(slide.description, style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _MiniPrototype(type: slide.preview),
                const SizedBox(height: 18),
                GlassSurface(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Làm theo 3 bước', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 14),
                      for (var i = 0; i < slide.steps.length; i++) ...[
                        _StepRow(index: i + 1, text: slide.steps[i]),
                        if (i != slide.steps.length - 1) const _StepConnector(),
                      ],
                      const SizedBox(height: 17),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(.07),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withOpacity(.12)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb_rounded, color: AppColors.primary, size: 21),
                            const SizedBox(width: 10),
                            Expanded(child: Text(slide.tip)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.index, required this.text});
  final int index;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withOpacity(.18), blurRadius: 12, offset: const Offset(0, 5)),
              ],
            ),
            alignment: Alignment.center,
            child: Text('$index', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Padding(padding: const EdgeInsets.only(top: 5), child: Text(text))),
        ],
      );
}

class _StepConnector extends StatelessWidget {
  const _StepConnector();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 15, top: 4, bottom: 4),
        child: Container(width: 2, height: 18, color: AppColors.primary.withOpacity(.20)),
      );
}

enum _PreviewType { home, group, expense, settlement }

class _MiniPrototype extends StatelessWidget {
  const _MiniPrototype({required this.type});
  final _PreviewType type;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).dividerColor, width: 1.3),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.10), blurRadius: 34, offset: const Offset(0, 17)),
            BoxShadow(color: AppColors.primary.withOpacity(.08), blurRadius: 34),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(33),
          child: Column(
            children: [
              Container(
                height: 28,
                color: Theme.of(context).colorScheme.surface,
                alignment: Alignment.center,
                child: Container(
                  width: 68,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(15, 10, 15, 18),
                color: Theme.of(context).scaffoldBackgroundColor,
                child: switch (type) {
                  _PreviewType.home => const _HomePreview(),
                  _PreviewType.group => const _GroupPreview(),
                  _PreviewType.expense => const _ExpensePreview(),
                  _PreviewType.settlement => const _SettlementPreview(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomePreview extends StatelessWidget {
  const _HomePreview();
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _MiniHeader(title: 'Xin chào, Duy', icon: Icons.notifications_none_rounded),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20)),
            child: const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Không gian chung', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                      SizedBox(height: 4),
                      Text('Quản lý chi tiêu nhóm', style: TextStyle(color: Color(0xFFEDE6FF), fontSize: 11)),
                    ],
                  ),
                ),
                Icon(Icons.people_alt_rounded, color: Color(0x88FFFFFF)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: _MetricPreview(label: 'Được nhận', value: '450.000 ₫', positive: true)),
              SizedBox(width: 8),
              Expanded(child: _MetricPreview(label: 'Đang nợ', value: '120.000 ₫', positive: false)),
            ],
          ),
          const SizedBox(height: 11),
          const _ListPreview(icon: Icons.flight_takeoff_rounded, title: 'Đà Lạt 2026', subtitle: '5 thành viên'),
        ],
      );
}

class _GroupPreview extends StatelessWidget {
  const _GroupPreview();
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _MiniHeader(title: 'Tạo nhóm mới', icon: Icons.group_add_rounded),
          const SizedBox(height: 12),
          const _FieldPreview(label: 'Tên nhóm', value: 'Đà Lạt 2026'),
          const SizedBox(height: 8),
          const _FieldPreview(label: 'Tiền tệ', value: 'VND · Việt Nam đồng'),
          const SizedBox(height: 12),
          const _ActionPreview(label: 'Tạo nhóm', icon: Icons.add_rounded),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(child: Text('Mã mời sau khi tạo', style: TextStyle(fontSize: 11))),
              StatusPill(label: 'AB12CD34', kind: FeedbackKind.info),
            ],
          ),
        ],
      );
}

class _ExpensePreview extends StatelessWidget {
  const _ExpensePreview();
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _MiniHeader(title: 'Thêm khoản chi', icon: Icons.receipt_long_rounded),
          const SizedBox(height: 10),
          const _FieldPreview(label: 'Tổng tiền', value: '450.000 ₫'),
          const SizedBox(height: 8),
          const _FieldPreview(label: 'Cách chia', value: 'Theo phần trăm'),
          const SizedBox(height: 10),
          const _ListPreview(icon: Icons.person_rounded, title: 'Duy', subtitle: '50% · 225.000 ₫'),
          const SizedBox(height: 6),
          const _ListPreview(icon: Icons.person_outline_rounded, title: 'Minh', subtitle: '50% · 225.000 ₫'),
          const SizedBox(height: 10),
          const _ActionPreview(label: 'Lưu khoản chi', icon: Icons.check_rounded),
        ],
      );
}

class _SettlementPreview extends StatelessWidget {
  const _SettlementPreview();
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _MiniHeader(title: 'Smart Settlement', icon: Icons.auto_awesome_rounded),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(.07),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                _PaymentArrow(from: 'Bạn', to: 'Minh', amount: '180.000 ₫'),
                SizedBox(height: 8),
                _PaymentArrow(from: 'Lan', to: 'Hà', amount: '90.000 ₫'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              StatusPill(label: 'Ít giao dịch hơn', kind: FeedbackKind.success),
              SizedBox(width: 6),
              StatusPill(label: 'Bảo toàn tổng tiền', kind: FeedbackKind.info),
            ],
          ),
        ],
      );
}

class _MiniHeader extends StatelessWidget {
  const _MiniHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
        ],
      );
}

class _MetricPreview extends StatelessWidget {
  const _MetricPreview({required this.label, required this.value, required this.positive});
  final String label;
  final String value;
  final bool positive;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: positive ? AppColors.success.withOpacity(.08) : AppColors.primary.withOpacity(.07),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10)),
            const SizedBox(height: 3),
            FittedBox(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900))),
          ],
        ),
      );
}

class _ListPreview extends StatelessWidget {
  const _ListPreview({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 19, color: AppColors.primary),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  Text(subtitle, style: const TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _FieldPreview extends StatelessWidget {
  const _FieldPreview({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

class _ActionPreview extends StatelessWidget {
  const _ActionPreview({required this.label, required this.icon});
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 7),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
          ],
        ),
      );
}

class _PaymentArrow extends StatelessWidget {
  const _PaymentArrow({required this.from, required this.to, required this.amount});
  final String from;
  final String to;
  final String amount;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(from, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
          const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primary),
          Expanded(child: Text(to, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
          const SizedBox(width: 6),
          Text(amount, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.primary)),
        ],
      );
}

class _GuideSlide {
  const _GuideSlide({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.steps,
    required this.tip,
    required this.preview,
  });

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final List<String> steps;
  final String tip;
  final _PreviewType preview;
}
