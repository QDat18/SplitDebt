import 'package:flutter/material.dart';

import '../../data/api.dart' show money;
import '../theme/app_theme.dart';

class SplitSummaryCard extends StatelessWidget {
  const SplitSummaryCard({
    super.key,
    required this.name,
    required this.payable,
    required this.receivable,
    required this.currency,
    this.onGuide,
  });

  final String name;
  final int payable;
  final int receivable;
  final String currency;
  final VoidCallback? onGuide;

  @override
  Widget build(BuildContext context) {
    final net = receivable - payable;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4C38C5), Color(0xFF775CF0)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.24),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -42,
            top: -48,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Xin chào, $name 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (onGuide != null)
                    IconButton(
                      tooltip: 'Hướng dẫn nhanh',
                      onPressed: onGuide,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(.12),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.help_outline_rounded),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _SummaryMetric(
                      label: 'Bạn đang nợ',
                      amount: money(payable, currency),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 62,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.white.withOpacity(.24),
                  ),
                  Expanded(
                    child: _SummaryMetric(
                      label: 'Người khác nợ bạn',
                      amount: money(receivable, currency),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Divider(color: Colors.white.withOpacity(.22), height: 1),
              const SizedBox(height: 19),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Số dư của bạn',
                      style: TextStyle(
                        color: Color(0xFFE5E0FF),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${net >= 0 ? '+' : '-'}${money(net.abs(), currency)}',
                    style: TextStyle(
                      color: net >= 0 ? const Color(0xFF20E39F) : const Color(0xFFFF7B82),
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.4,
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
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.amount});
  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFD9D4F8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
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
  });

  final String name;
  final int memberCount;
  final int balance;
  final String currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final positive = balance > 0;
    final color = balance == 0
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : positive
            ? AppColors.success
            : AppColors.error;
    return SizedBox(
      width: 190,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.group_rounded, color: AppColors.primary),
                    ),
                    const Spacer(),
                    Text(
                      '${memberCount}TV',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  balance == 0 ? 'Đã cân bằng' : '${positive ? '+' : '-'}${money(balance.abs(), currency)}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
              ],
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
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  child: Text(
                    name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: Theme.of(context).textTheme.titleMedium),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${positive ? '+' : '-'}${money(amount.abs(), currency)}',
                  style: TextStyle(
                    color: positive ? AppColors.success : AppColors.error,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
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
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: AppColors.primaryDark,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withOpacity(.22),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TỔNG CHI TIÊU',
              style: TextStyle(
                color: Color(0xFFCFC9EE),
                fontWeight: FontWeight.w700,
                letterSpacing: .8,
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                money(total, currency),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.7,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Divider(color: Colors.white.withOpacity(.16), height: 1),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _GroupMetric(
                    label: 'Bạn đang nợ',
                    amount: money(payable, currency),
                    color: AppColors.error,
                  ),
                ),
                Container(width: 1, height: 42, color: Colors.white.withOpacity(.16)),
                const SizedBox(width: 20),
                Expanded(
                  child: _GroupMetric(
                    label: 'Bạn được nhận',
                    amount: money(receivable, currency),
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onAddExpense,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Thêm chi'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6D57ED),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onSettlement,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(.15),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Thanh toán'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _GroupMetric extends StatelessWidget {
  const _GroupMetric({required this.label, required this.amount, required this.color});
  final String label;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFCFC9EE))),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: TextStyle(color: color, fontSize: 19, fontWeight: FontWeight.w900),
            ),
          ),
        ],
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
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF222838)
              : const Color(0xFFEDECF1),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          children: [
            for (final item in items)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: item.$1 == value ? Theme.of(context).colorScheme.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: item.$1 == value
                        ? [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10, offset: const Offset(0, 3))]
                        : null,
                  ),
                  child: TextButton(
                    onPressed: () => onChanged(item.$1),
                    child: Text(
                      item.$2,
                      style: TextStyle(
                        color: item.$1 == value
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: item.$1 == value ? FontWeight.w900 : FontWeight.w600,
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
        avatar: Icon(icon, size: 18, color: selected ? Colors.white : AppColors.primary),
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: AppColors.primary,
        backgroundColor: Theme.of(context).colorScheme.surface,
        side: BorderSide(color: selected ? AppColors.primary : Theme.of(context).dividerColor),
        labelStyle: TextStyle(
          color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
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
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
                      child: Container(
                        width: 94,
                        height: 94,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE8FBF4),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.success.withOpacity(.22),
                              blurRadius: 32,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.check_rounded, size: 52, color: AppColors.success),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text('Thanh toán thành công!', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(
                      'Đã ghi nhận ${money(widget.amount, widget.currency)} thanh toán cho ${widget.name}.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Column(
                        children: [
                          _SuccessMeta(label: 'Trạng thái', value: 'Chờ người nhận xác nhận'),
                          if (widget.reference != null) ...[
                            const Divider(height: 26),
                            _SuccessMeta(label: 'Mã giao dịch', value: widget.reference!),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
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
          Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800))),
        ],
      );
}
