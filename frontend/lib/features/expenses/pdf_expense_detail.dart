// Trách nhiệm file: Màn hình chi tiết khoản chi chuẩn Fintech, không dùng emoji, tương thích Light & Dark mode.

import 'package:flutter/material.dart';

import '../../core/network/dio_client.dart';
import '../../core/state/app_sync.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/pdf_components.dart';
import '../../core/widgets/fintech_components.dart';
import '../../core/widgets/premium_shell.dart';

class ExpenseReadScreen extends StatefulWidget {
  final Map<String, dynamic> expense;
  const ExpenseReadScreen({super.key, required this.expense});

  @override
  State<ExpenseReadScreen> createState() => _ExpenseReadScreenState();
}

class _ExpenseReadScreenState extends State<ExpenseReadScreen> {
  late Map<String, dynamic> expense = Map.of(widget.expense);
  bool _busy = false;

  Future<void> _edit() async {
    final title = TextEditingController(
      text: expense['title']?.toString() ?? '',
    );
    final note = TextEditingController(
      text: expense['description']?.toString() ?? '',
    );
    final values = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(ctx, 'Chỉnh sửa khoản chi', 'Edit expense')),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: InputDecoration(
                  labelText: tr(ctx, 'Tên khoản chi', 'Expense title'),
                ),
              ),
              const SizedBox(height: AppDimensions.s16),
              TextField(
                controller: note,
                decoration: InputDecoration(
                  labelText: tr(ctx, 'Ghi chú', 'Note'),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr(ctx, 'Hủy', 'Cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (title.text.trim().isNotEmpty) {
                Navigator.pop(ctx, {
                  'title': title.text.trim(),
                  'description': note.text.trim(),
                });
              }
            },
            child: Text(tr(ctx, 'Lưu', 'Save')),
          ),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    title.dispose();
    note.dispose();
    if (values == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final parts = expense['participants'] as List? ?? [];
      final response = await dioClient.put(
        '/v1/expenses/${expense['id']}',
        data: {
          'groupId': expense['groupId'],
          'payerId': expense['payerId'],
          'categoryId': expense['categoryId'],
          'title': values['title'],
          'description': values['description'],
          'totalAmount': expense['totalAmount'],
          'expenseDate': expense['expenseDate'],
          'receiptUrl': expense['receiptUrl'],
          'splitType': parts.isEmpty ? 'EQUAL' : parts.first['splitType'],
          'participants': parts
              .map(
                (p) => {
                  'userId': p['userId'],
                  'amount': p['amount'],
                  'percentage': p['percentage'],
                  'weight': p['weight'],
                },
              )
              .toList(),
          'items': (expense['items'] as List? ?? [])
              .map(
                (item) => {
                  'itemName': item['itemName'],
                  'quantity': item['quantity'],
                  'unitPrice': item['unitPrice'],
                  'participants': (item['participants'] as List? ?? [])
                      .map((p) => {'userId': p['userId']})
                      .toList(),
                },
              )
              .toList(),
        },
      );
      notifyDataChanged();
      if (mounted) {
        setState(
          () =>
              expense = Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                context,
                'Không thể sửa khoản chi. Kiểm tra quyền và trạng thái quyết toán.',
                'Cannot edit expense. Check permissions and settlement status.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(ctx, 'Xóa khoản chi?', 'Delete expense?')),
        content: Text(
          tr(
            ctx,
            'Xóa "${expense['title']}" và cập nhật lại công nợ của nhóm.',
            'Delete "${expense['title']}" and recalculate group balances.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr(ctx, 'Hủy', 'Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorFor(ctx),
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr(ctx, 'Xóa', 'Delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await dioClient.delete('/v1/expenses/${expense['id']}');
      notifyDataChanged();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                context,
                'Không thể xóa khoản chi. Kiểm tra quyền và trạng thái quyết toán.',
                'Cannot delete expense. Check permissions and settlement status.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final errorColor = AppColors.errorFor(context);
    final parts = expense['participants'] as List? ?? [];
    final titleText = expense['title']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'Chi tiết khoản chi', 'Expense details')),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.s16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : _edit,
                  child: Text(tr(context, 'Chỉnh sửa', 'Edit')),
                ),
              ),
              const SizedBox(width: AppDimensions.s12),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: errorColor,
                    side: BorderSide(color: errorColor),
                  ),
                  onPressed: _busy ? null : _delete,
                  child: Text(tr(context, 'Xóa', 'Delete')),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.s16),
            children: [
              PremiumSurface(
                padding: const EdgeInsets.all(AppDimensions.s20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ExpenseIconBadge(
                          title: titleText,
                          categoryName: expense['categoryName']?.toString(),
                          size: 44,
                        ),
                        const SizedBox(width: AppDimensions.s12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                titleText,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${expense['categoryName'] ?? tr(context, 'Khoản chi', 'Expense')} · ${expense['expenseDate'] ?? ''}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.s16),
                    Text(
                      money((expense['totalAmount'] as num?) ?? 0),
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                        letterSpacing: -0.6,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.s16),
              SectionLabel(title: tr(context, 'Người thanh toán', 'Paid by')),
              const SizedBox(height: AppDimensions.s8),
              PremiumSurface(
                padding: EdgeInsets.zero,
                radius: AppDimensions.r12,
                child: ListTile(
                  leading: PersonBadge(
                    expense['payerName']?.toString() ?? '',
                    color: scheme.primary,
                  ),
                  title: Text(
                    expense['payerName']?.toString() ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: Text(
                    money((expense['totalAmount'] as num?) ?? 0),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.s20),
              SectionLabel(
                title: tr(
                  context,
                  'Chia cho ${parts.length} người',
                  'Split among ${parts.length} people',
                ),
              ),
              const SizedBox(height: AppDimensions.s8),
              PremiumSurface(
                padding: EdgeInsets.zero,
                radius: AppDimensions.r12,
                child: Column(
                  children: [
                    for (int i = 0; i < parts.length; i++) ...[
                      ListTile(
                        leading: PersonBadge(
                          parts[i]['userName']?.toString() ?? '',
                          color: scheme.primary,
                        ),
                        title: Text(
                          parts[i]['userName']?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Text(
                          money((parts[i]['amount'] as num?) ?? 0),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      if (i < parts.length - 1)
                        const Divider(height: 1, indent: 64),
                    ],
                  ],
                ),
              ),
              if ((expense['description'] ?? '')
                  .toString()
                  .trim()
                  .isNotEmpty) ...[
                const SizedBox(height: AppDimensions.s20),
                SectionLabel(title: tr(context, 'Ghi chú', 'Note')),
                const SizedBox(height: AppDimensions.s8),
                PremiumSurface(
                  radius: AppDimensions.r12,
                  child: Text(
                    expense['description'].toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
