// Trách nhiệm file: Màn hình công nợ và tối ưu thanh toán chuẩn Fintech, rõ ràng ai trả ai, không dùng emoji, hỗ trợ Light & Dark mode.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/network/dio_client.dart';
import '../../core/network/network_error.dart';
import '../../core/state/app_sync.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/pdf_components.dart';
import '../../core/widgets/fintech_components.dart';
import '../../core/widgets/motion_kit.dart';
import '../../core/widgets/premium_shell.dart';
import '../../data/repositories/auth_repository.dart';
import '../notifications/notification_screen.dart';
import 'data/settlement_api_service.dart';
import 'models/settlement_models.dart';
import 'presentation/payment_dialog.dart';

class GroupSettlementScreen extends StatefulWidget {
  final int? groupId;
  final bool isActive;
  const GroupSettlementScreen({super.key, this.groupId, this.isActive = true});

  @override
  State<GroupSettlementScreen> createState() => _GroupSettlementScreenState();
}

class _GroupSettlementScreenState extends State<GroupSettlementScreen>
    with WidgetsBindingObserver {
  final _api = SettlementApiService();
  StreamSubscription<RemoteMessage>? _messages;
  List<Map<String, dynamic>> _groups = [];
  int? _userId;
  int? _groupId;
  DebtSummary? _debt;
  SmartSettlementResult? _smart;
  List<SettlementRecord> _settlements = [];
  bool _loading = true;
  bool _busy = false;
  String? _error;
  int _tab = 0;
  int _version = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    try {
      _messages = FirebaseMessaging.onMessage.listen((message) {
        if (message.data['groupId']?.toString() == _groupId?.toString()) {
          _load();
        }
      });
    } catch (_) {
      // Firebase có thể tắt ở môi trường local/web.
    }
    _initialize();
    appDataSyncSignal.addListener(_load);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appDataSyncSignal.removeListener(_load);
    _messages?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GroupSettlementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _initialize();
  }

  String _friendlyError(Object error) {
    if (error is DioException) return networkErrorMessage(error);
    return tr(
      context,
      'Không tải được dữ liệu công nợ. Vui lòng thử lại.',
      'Could not load settlement data. Please try again.',
    );
  }

  Future<void> _initialize() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userId = await AuthRepository().getCurrentUserId();
      final response = await dioClient.get('/groups');
      final groups = (response.data['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (!mounted) return;
      _userId = userId;
      _groups = groups;
      final preferred = _groupId ?? widget.groupId;
      _groupId = groups.any((g) => g['id'] == preferred)
          ? preferred
          : (groups.isEmpty ? null : (groups.first['id'] as num).toInt());
      if (_groupId != null) {
        await _load();
      } else {
        setState(() => _loading = false);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = _friendlyError(error);
          _loading = false;
        });
      }
    }
  }

  Future<void> _load() async {
    final group = _groupId;
    final user = _userId;
    if (group == null || user == null || !mounted) return;
    final version = ++_version;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object>([
        _api.getDebtSummary(group),
        _api.getSmartSettlement(group),
        _api.getSettlements(group),
      ]);
      if (!mounted || version != _version) return;
      setState(() {
        _debt = results[0] as DebtSummary;
        _smart = results[1] as SmartSettlementResult;
        _settlements = results[2] as List<SettlementRecord>;
        _loading = false;
      });
    } catch (error) {
      if (mounted && version == _version) {
        setState(() {
          _error = _friendlyError(error);
          _loading = false;
        });
      }
    }
  }

  Future<void> _openPayment(SettlementRecord record) async {
    await Navigator.push<void>(
      context,
      fintechRoute(
        PaymentDialog(
          groupId: record.groupId,
          currentUserId: _userId!,
          settlement: record,
          onUpdated: () {},
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _create(DebtEdge edge) async {
    if (_busy || _groupId == null) return;
    final isDebtor = _userId == edge.debtorId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isDebtor
              ? tr(ctx, 'Bắt đầu thanh toán?', 'Start payment?')
              : tr(ctx, 'Gửi yêu cầu thanh toán?', 'Send payment request?'),
        ),
        content: Text(
          isDebtor
              ? tr(
                  ctx,
                  'Tạo giao dịch thanh toán ${money(edge.amount)} cho ${edge.creditorName}.',
                  'Create a payment of ${money(edge.amount)} to ${edge.creditorName}.',
                )
              : tr(
                  ctx,
                  'Gửi yêu cầu để ${edge.debtorName} thanh toán ${money(edge.amount)}.',
                  'Send a payment request of ${money(edge.amount)} to ${edge.debtorName}.',
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr(ctx, 'Hủy', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr(ctx, 'Tiếp tục', 'Continue')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final record = await _api.createSettlement(
        groupId: _groupId!,
        suggestion: edge,
      );
      if (mounted && record.debtorId == _userId) {
        await _openPayment(record);
      } else {
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                tr(
                  context,
                  'Đã tạo yêu cầu thanh toán. Người trả sẽ báo đã chuyển tiền trước khi bạn xác nhận.',
                  'Request created. The payer will mark paid before you confirm.',
                ),
              ),
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _tab == 0
              ? tr(context, 'Công nợ', 'Balances')
              : tr(context, 'Tối ưu thanh toán', 'Smart settle'),
        ),
        actions: [
          const NotificationBell(),
          IconButton(
            onPressed: _loading ? null : _initialize,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: tr(context, 'Tải lại', 'Refresh'),
          ),
        ],
      ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(AppDimensions.s16),
              child: Column(
                children: [
                  ShimmerBox(width: double.infinity, height: 140, radius: 14),
                  SizedBox(height: 12),
                  ShimmerBox(width: double.infinity, height: 80, radius: 12),
                  SizedBox(height: 8),
                  ShimmerBox(width: double.infinity, height: 80, radius: 12),
                ],
              ),
            )
          : _error != null
          ? Padding(
              padding: const EdgeInsets.all(AppDimensions.s20),
              child: Center(
                child: AppErrorState(
                  title: tr(context, 'Lỗi tải công nợ', 'Load error'),
                  message: _error!,
                  onRetry: _initialize,
                ),
              ),
            )
          : _groups.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(AppDimensions.s20),
              child: Center(
                child: AppEmptyState(
                  icon: CupertinoIcons.person_2,
                  title: tr(context, 'Chưa tham gia nhóm nào', 'No groups yet'),
                  message: tr(
                    context,
                    'Tham gia hoặc tạo nhóm để theo dõi và thanh toán công nợ.',
                    'Join or create a group to track and settle balances.',
                  ),
                ),
              ),
            )
          : RefreshIndicator(
              color: scheme.primary,
              onRefresh: _load,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppDimensions.maxContentWidth,
                  ),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.s16,
                      AppDimensions.s12,
                      AppDimensions.s16,
                      AppDimensions.s32,
                    ),
                    children: [
                      if (widget.groupId == null) ...[
                        DropdownButtonFormField<int>(
                          initialValue: _groupId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: tr(context, 'Nhóm', 'Group'),
                            prefixIcon: const Icon(Icons.group_outlined),
                          ),
                          items: _groups
                              .map(
                                (g) => DropdownMenuItem(
                                  value: (g['id'] as num).toInt(),
                                  child: Text(
                                    g['name'].toString(),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            _groupId = v;
                            _load();
                          },
                        ),
                        const SizedBox(height: AppDimensions.s12),
                      ],
                      PdfTabs(
                        labels: [
                          tr(context, 'Tổng quan nợ', 'Overview'),
                          tr(context, 'Tối ưu & Thanh toán', 'Settle up'),
                        ],
                        selected: _tab,
                        onChanged: (v) => setState(() => _tab = v),
                      ),
                      const SizedBox(height: AppDimensions.s16),
                      if (_tab == 0)
                        _buildDebtOverview(scheme)
                      else
                        _buildSmartSettlement(scheme),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildDebtOverview(ColorScheme scheme) {
    final debt = _debt!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BalanceSummaryCard(
          net: debt.totalToReceive - debt.totalToPay,
          receivable: debt.totalToReceive,
          payable: debt.totalToPay,
          title: tr(context, 'Công nợ của bạn', 'Your balance'),
        ),
        const SizedBox(height: AppDimensions.s20),
        SectionLabel(title: tr(context, 'Bạn cần trả', 'You owe')),
        const SizedBox(height: AppDimensions.s8),
        if (debt.youOwe.isEmpty)
          PremiumSurface(
            radius: AppDimensions.r12,
            child: Text(
              tr(
                context,
                'Bạn không còn khoản phải trả trong nhóm này.',
                'You have no outgoing debts in this group.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          PremiumSurface(
            padding: EdgeInsets.zero,
            radius: AppDimensions.r12,
            child: Column(
              children: [
                for (int i = 0; i < debt.youOwe.length; i++) ...[
                  _debtRow(
                    debt.youOwe[i].creditorName,
                    tr(
                      context,
                      'Bạn trả ${debt.youOwe[i].creditorName}',
                      'You pay ${debt.youOwe[i].creditorName}',
                    ),
                    -debt.youOwe[i].amount,
                  ),
                  if (i < debt.youOwe.length - 1)
                    const Divider(height: 1, indent: 64),
                ],
              ],
            ),
          ),
        const SizedBox(height: AppDimensions.s20),
        SectionLabel(title: tr(context, 'Bạn được nhận', 'Owed to you')),
        const SizedBox(height: AppDimensions.s8),
        if (debt.owedToYou.isEmpty)
          PremiumSurface(
            radius: AppDimensions.r12,
            child: Text(
              tr(
                context,
                'Bạn không còn khoản cần nhận trong nhóm này.',
                'No one owes you in this group.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          PremiumSurface(
            padding: EdgeInsets.zero,
            radius: AppDimensions.r12,
            child: Column(
              children: [
                for (int i = 0; i < debt.owedToYou.length; i++) ...[
                  _debtRow(
                    debt.owedToYou[i].debtorName,
                    tr(
                      context,
                      '${debt.owedToYou[i].debtorName} trả bạn',
                      '${debt.owedToYou[i].debtorName} pays you',
                    ),
                    debt.owedToYou[i].amount,
                  ),
                  if (i < debt.owedToYou.length - 1)
                    const Divider(height: 1, indent: 64),
                ],
              ],
            ),
          ),
        const SizedBox(height: AppDimensions.s20),
        FilledButton.icon(
          onPressed: () => setState(() => _tab = 1),
          icon: const Icon(CupertinoIcons.arrow_2_squarepath, size: 18),
          label: Text(
            tr(
              context,
              'Xem phương án tối ưu thanh toán',
              'View settlement plan',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmartSettlement(ColorScheme scheme) {
    final smart = _smart!;
    final pendingSuggestions = smart.suggestions
        .where(
          (e) => !_settlements.any(
            (s) =>
                (s.status == 'PENDING' || s.status == 'PAID') &&
                s.debtorId == e.debtorId &&
                s.creditorId == e.creditorId,
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumSurface(
          radius: AppDimensions.r12,
          child: Row(
            children: [
              Expanded(
                child: _countMetric(
                  tr(context, 'Trước tối ưu', 'Before'),
                  '${smart.beforeTransactionCount}',
                  scheme.onSurface,
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              Expanded(
                child: _countMetric(
                  tr(context, 'Sau tối ưu', 'After'),
                  '${smart.afterTransactionCount}',
                  AppColors.successFor(context),
                ),
              ),
            ],
          ),
        ),
        if (_settlements.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.s20),
          SectionLabel(
            title: tr(context, 'Giao dịch thanh toán', 'Active settlements'),
          ),
          const SizedBox(height: AppDimensions.s8),
          for (final r in _settlements) _recordCard(r),
        ],
        const SizedBox(height: AppDimensions.s20),
        SectionLabel(
          title: tr(context, 'Đề xuất thanh toán', 'Suggested transfers'),
        ),
        const SizedBox(height: AppDimensions.s8),
        if (pendingSuggestions.isEmpty)
          AppEmptyState(
            icon: CupertinoIcons.checkmark_circle,
            title: tr(context, 'Không còn khoản cần thanh toán', 'All settled'),
            message: tr(
              context,
              'Mọi khoản công nợ trong nhóm đã được cân bằng hoặc đang chờ xác nhận.',
              'All group debts are settled or awaiting confirmation.',
            ),
          )
        else
          for (final e in pendingSuggestions) _suggestionCard(e, scheme),
      ],
    );
  }

  Widget _countMetric(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          tr(context, '$value giao dịch', '$value transfers'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: valueColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _debtRow(String name, String subtitle, double amount) {
    final color = amount < 0
        ? AppColors.errorFor(context)
        : AppColors.successFor(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: PersonBadge(name, color: color),
      title: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Text(
        '${amount > 0 ? '+' : '-'}${money(amount.abs())}',
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _suggestionCard(DebtEdge e, ColorScheme scheme) {
    final canAct = _userId == e.debtorId || _userId == e.creditorId;
    final isDebtor = _userId == e.debtorId;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.s8),
      child: PremiumSurface(
        radius: AppDimensions.r12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                PersonBadge(
                  e.debtorName,
                  color: AppColors.errorFor(context),
                  radius: 18,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                PersonBadge(
                  e.creditorName,
                  color: AppColors.successFor(context),
                  radius: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    money(e.amount),
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.s8),
            Text(
              tr(
                context,
                '${e.debtorName} trả ${e.creditorName}',
                '${e.debtorName} pays ${e.creditorName}',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (canAct) ...[
              const SizedBox(height: AppDimensions.s12),
              isDebtor
                  ? FilledButton(
                      onPressed: _busy ? null : () => _create(e),
                      child: Text(tr(context, 'Thanh toán ngay', 'Pay now')),
                    )
                  : OutlinedButton(
                      onPressed: _busy ? null : () => _create(e),
                      child: Text(
                        tr(context, 'Yêu cầu thanh toán', 'Request payment'),
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _recordCard(SettlementRecord record) {
    final scheme = Theme.of(context).colorScheme;
    final canPay = record.status == 'PENDING' && record.debtorId == _userId;
    final canConfirm = record.status == 'PAID' && record.creditorId == _userId;

    final label = switch (record.status) {
      'PENDING' => tr(
        context,
        'Chờ người trả chuyển tiền',
        'Awaiting transfer',
      ),
      'PAID' => tr(context, 'Chờ người nhận xác nhận', 'Awaiting confirmation'),
      'CONFIRMED' => tr(context, 'Hoàn tất thanh toán', 'Confirmed'),
      _ => record.status,
    };
    final color = record.status == 'CONFIRMED'
        ? AppColors.successFor(context)
        : record.status == 'PAID'
        ? AppColors.warningFor(context)
        : scheme.primary;
    final statusIcon = record.status == 'CONFIRMED'
        ? Icons.check_circle_outline
        : record.status == 'PAID'
        ? Icons.hourglass_top_rounded
        : Icons.schedule_rounded;

    final youSuffix = tr(context, ' (Bạn)', ' (You)');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.s8),
      child: PremiumSurface(
        radius: AppDimensions.r12,
        borderColor: record.status == 'PAID'
            ? AppColors.warningFor(context).withValues(alpha: 0.5)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                PersonBadge(
                  record.debtorName,
                  color: scheme.primary,
                  radius: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${record.debtorName}${record.debtorId == _userId ? youSuffix : ''} → ${record.creditorName}${record.creditorId == _userId ? youSuffix : ''}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.s12),
            Text(
              money(record.amount),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: scheme.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const Divider(height: AppDimensions.s20),
            Row(
              children: [
                Icon(statusIcon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
            if (canPay || canConfirm) ...[
              const SizedBox(height: AppDimensions.s12),
              FilledButton.icon(
                onPressed: _busy ? null : () => _openPayment(record),
                icon: Icon(
                  canPay ? Icons.payments_outlined : Icons.verified_outlined,
                  size: 18,
                ),
                label: Text(
                  canPay
                      ? tr(context, 'Thanh toán', 'Mark as paid')
                      : tr(context, 'Xác nhận đã nhận tiền', 'Confirm receipt'),
                ),
              ),
            ],
            if (record.status == 'PENDING' && record.creditorId == _userId) ...[
              const SizedBox(height: AppDimensions.s8),
              Text(
                tr(
                  context,
                  'Chờ ${record.debtorName} báo đã thanh toán trước khi bạn xác nhận nhận tiền.',
                  'Waiting for ${record.debtorName} to report payment before you confirm.',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (record.status == 'PAID' && record.debtorId == _userId) ...[
              const SizedBox(height: AppDimensions.s8),
              Text(
                tr(
                  context,
                  'Bạn đã báo thanh toán. Công nợ sẽ được trừ ngay khi người nhận xác nhận.',
                  'Payment reported. Balances update once the recipient confirms.',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
