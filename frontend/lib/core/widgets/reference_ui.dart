import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../data/api.dart' show money;
import '../../widgets/design.dart' show Avatar, Surface, AnimatedMoneyText, StaggerReveal;
import '../theme/app_theme.dart';
import 'premium_ui.dart';

class SplitSummaryCard extends StatelessWidget {
  const SplitSummaryCard({
    super.key,
    required this.name,
    required this.payable,
    required this.receivable,
    required this.currency,
    this.groupCount = 0,
    this.onGuide,
  });

  final String name;
  final int payable;
  final int receivable;
  final String currency;
  final int groupCount;
  final VoidCallback? onGuide;

  @override
  Widget build(BuildContext context) {
    final net = receivable - payable;
    final balanced = payable == 0 && receivable == 0;
    final positive = net >= 0;
    final netColor = balanced
        ? AppColors.tertiary
        : positive
            ? AppColors.primary
            : AppColors.error;
    return Column(
      children: [
        StaggerReveal(
          index: 1,
          child: Surface(
            interactive: false,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -54,
                  right: -48,
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: netColor.withValues(alpha: .10),
                          blurRadius: 70,
                          spreadRadius: 14,
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: netColor.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(Icons.account_balance_outlined, color: netColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TỔNG SỐ DƯ RÒNG',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      letterSpacing: .9,
                                      color: AppColors.textPrimary,
                                      fontSize: 11,
                                    ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                groupCount == 0
                                    ? 'Chưa có nhóm đang hoạt động'
                                    : 'Tổng hợp từ $groupCount nhóm đang hoạt động',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        if (onGuide != null)
                          IconButton(
                            tooltip: 'Hướng dẫn nhanh',
                            visualDensity: VisualDensity.compact,
                            onPressed: onGuide,
                            icon: const Icon(Icons.help_outline_rounded, size: 18),
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: AnimatedMoneyText(
                          amount: net.abs(),
                          currency: currency,
                          prefix: net < 0 ? '-' : net > 0 ? '+' : '',
                          style: TextStyle(
                            fontFamily: 'Geist',
                            color: netColor,
                            fontSize: 40,
                            height: 1,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.6,
                            shadows: [
                              Shadow(color: netColor.withValues(alpha: .18), blurRadius: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 13),
                    Row(
                      children: [
                        Icon(
                          balanced
                              ? Icons.check_circle_outline_rounded
                              : positive
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                          size: 17,
                          color: netColor,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            balanced
                                ? 'Bạn đang cân bằng, chưa cần thanh toán.'
                                : positive
                                    ? 'Bạn sẽ thu về nhiều hơn số tiền cần trả.'
                                    : 'Bạn còn khoản cần thanh toán trong các nhóm.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 350;
            final receive = StaggerReveal(
              index: 2,
              child: _DebtMetricCard(
                label: 'MÌNH SẼ NHẬN',
                caption: 'Số tiền mình sẽ thu về',
                amount: receivable,
                currency: currency,
                icon: Icons.south_west_rounded,
                color: AppColors.primary,
              ),
            );
            final owe = StaggerReveal(
              index: 3,
              child: _DebtMetricCard(
                label: 'MÌNH CẦN TRẢ',
                caption: 'Số tiền mình cần thanh toán',
                amount: payable,
                currency: currency,
                icon: Icons.north_east_rounded,
                color: AppColors.secondary,
              ),
            );
            if (compact) {
              return Column(children: [receive, const SizedBox(height: 10), owe]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: receive),
                const SizedBox(width: 12),
                Expanded(child: owe),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DebtMetricCard extends StatelessWidget {
  const _DebtMetricCard({
    required this.label,
    required this.caption,
    required this.amount,
    required this.currency,
    required this.icon,
    required this.color,
  });

  final String label;
  final String caption;
  final int amount;
  final String currency;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Surface(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
        child: Stack(
          children: [
            Positioned(
              top: -14,
              left: 0,
              right: 0,
              child: Container(height: 2, color: color.withValues(alpha: .48)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 15, color: color),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontSize: 10,
                              color: color,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: AnimatedMoneyText(
                    amount: amount,
                    currency: currency,
                    style: TextStyle(
                      fontFamily: 'Geist',
                      color: color,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      );
}

class ReferenceGroupCard extends StatelessWidget {
  const ReferenceGroupCard({
    super.key,
    required this.name,
    required this.memberCount,
    required this.balance,
    required this.currency,
    required this.onTap,
    this.pending = false,
    this.total = 0,
    this.index = 0,
  });

  final String name;
  final int memberCount;
  final int balance;
  final String currency;
  final VoidCallback onTap;
  final bool pending;
  final int total;
  final int index;

  @override
  Widget build(BuildContext context) {
    final positive = balance > 0;
    final settled = balance == 0 && !pending;
    final color = pending && balance == 0
        ? AppColors.warning
        : settled
            ? AppColors.textSecondary
            : positive
                ? AppColors.primary
                : AppColors.error;
    return StaggerReveal(
      index: index,
      child: Opacity(
        opacity: settled ? .56 : 1,
        child: Surface(
          padding: EdgeInsets.zero,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: Icon(
                          index % 3 == 0
                              ? Icons.flight_takeoff_rounded
                              : index % 3 == 1
                                  ? Icons.family_restroom_rounded
                                  : Icons.school_rounded,
                          color: settled ? AppColors.textSecondary : index.isEven ? AppColors.primary : AppColors.secondary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17),
                            ),
                            const SizedBox(height: 4),
                            Text('$memberCount thành viên · $currency', style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!settled) ...[
                              Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              pending ? 'Pending' : settled ? 'Settled' : 'Active',
                              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 86,
                        height: 30,
                        child: Stack(
                          children: [
                            for (var i = 0; i < math.min(memberCount, 3); i++)
                              Positioned(
                                left: i * 22,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.surfaceHighest,
                                    border: Border.all(color: AppColors.background, width: 2),
                                  ),
                                  child: Icon(Icons.person_rounded, size: 16, color: i.isEven ? AppColors.primary : AppColors.secondary),
                                ),
                              ),
                            if (memberCount > 3)
                              Positioned(
                                left: 66,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceHighest, border: Border.all(color: AppColors.background, width: 2)),
                                  alignment: Alignment.center,
                                  child: Text('+${memberCount - 3}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Total Spent', style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 3),
                          AnimatedMoneyText(
                            amount: total,
                            currency: currency,
                            style: const TextStyle(fontFamily: 'Geist', fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pending && balance == 0
                                ? 'Chờ xác nhận'
                                : settled
                                    ? 'Đã hoàn tất'
                                    : balance > 0
                                        ? 'Bạn được nhận ${money(balance, currency)}'
                                        : 'Bạn cần trả ${money(balance.abs(), currency)}',
                            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DebtListTile extends StatelessWidget {
  const DebtListTile({
    super.key,
    required this.name,
    required this.amount,
    required this.currency,
    this.subtitle,
    this.positive = false,
    this.onTap,
  });

  final String name;
  final int amount;
  final String currency;
  final String? subtitle;
  final bool positive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = positive ? AppColors.primary : AppColors.error;
    return Surface(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Stack(
          children: [
            Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 2, color: color.withValues(alpha: .75))),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceHigh,
                      border: Border.all(color: color.withValues(alpha: .24)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.w700, color: color),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: Theme.of(context).textTheme.titleMedium),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${positive ? '+' : '-'}${money(amount.abs(), currency)}',
                    style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700),
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

class GroupHeroSummary extends StatelessWidget {
  const GroupHeroSummary({
    super.key,
    required this.total,
    required this.payable,
    required this.receivable,
    required this.currency,
    required this.onAddExpense,
    required this.onSettlement,
  });

  final int total;
  final int payable;
  final int receivable;
  final String currency;
  final VoidCallback onAddExpense;
  final VoidCallback onSettlement;

  @override
  Widget build(BuildContext context) => Surface(
        interactive: false,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: Stack(
          children: [
            Positioned(
              right: -80,
              top: -90,
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: .07),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .08), blurRadius: 70)],
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'TOTAL TRIP SPEND',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 1,
                      ),
                ),
                const SizedBox(height: 7),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    money(total, currency),
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      color: AppColors.primary,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: _GroupMetric(label: 'BẠN NỢ', amount: payable, currency: currency, color: AppColors.error)),
                    const SizedBox(width: 10),
                    Expanded(child: _GroupMetric(label: 'ĐƯỢC NHẬN', amount: receivable, currency: currency, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onAddExpense,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Thêm khoản chi'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onSettlement,
                        icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                        label: const Text('Công nợ'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
}

class _GroupMetric extends StatelessWidget {
  const _GroupMetric({required this.label, required this.amount, required this.currency, required this.color});
  final String label;
  final int amount;
  final String currency;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: .55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontSize: 9)),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                money(amount, currency),
                style: TextStyle(fontFamily: 'Geist', color: color, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
}

class PillSegment<T> extends StatelessWidget {
  const PillSegment({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  final List<(T, String)> items;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.glassBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .30),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            for (final item in items)
              Expanded(
                child: AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: item.$1 == value ? AppColors.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    border: item.$1 == value ? Border.all(color: AppColors.glassBorder) : null,
                    boxShadow: item.$1 == value
                        ? [BoxShadow(color: Colors.black.withValues(alpha: .25), blurRadius: 8, offset: const Offset(0, 3))]
                        : null,
                  ),
                  child: TextButton(
                    onPressed: () => onChanged(item.$1),
                    style: TextButton.styleFrom(
                      foregroundColor: item.$1 == value ? AppColors.textPrimary : AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                    ),
                    child: Text(
                      item.$2,
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 11,
                        fontWeight: item.$1 == value ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

class CategoryChoice extends StatelessWidget {
  const CategoryChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon = Icons.category_rounded,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) => ChoiceChip(
        avatar: Icon(icon, size: 17, color: selected ? const Color(0xFF003824) : AppColors.primary),
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surfaceLow,
        side: BorderSide(color: selected ? AppColors.primary : AppColors.glassBorder),
        labelStyle: TextStyle(
          color: selected ? const Color(0xFF003824) : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      );
}

class PaymentSuccessScreen extends StatefulWidget {
  const PaymentSuccessScreen({
    super.key,
    required this.amount,
    required this.currency,
    required this.name,
    this.reference,
  });

  final int amount;
  final String currency;
  final String name;
  final String? reference;

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        body: PremiumBackground(
          animate: true,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: GlassSurface(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScaleTransition(
                          scale: CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                              border: Border.all(color: Colors.white.withValues(alpha: .22)),
                              boxShadow: [
                                BoxShadow(color: AppColors.primary.withValues(alpha: .28), blurRadius: 34, offset: const Offset(0, 14)),
                              ],
                            ),
                            child: const Icon(Icons.check_rounded, size: 48, color: Color(0xFF003824)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text('Thanh toán đã ghi nhận', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                        const SizedBox(height: 9),
                        Text(
                          'Bạn đã thanh toán ${money(widget.amount, widget.currency)} cho ${widget.name}.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        Surface(
                          interactive: false,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const _SuccessMeta(label: 'Trạng thái', value: 'Chờ người nhận xác nhận'),
                              if (widget.reference != null) ...[
                                const Divider(height: 24),
                                _SuccessMeta(label: 'Mã giao dịch', value: widget.reference!),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Về trang nhóm'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _SuccessMeta extends StatelessWidget {
  const _SuccessMeta({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          const SizedBox(width: 12),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      );
}
