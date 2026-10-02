import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/settlement_api_service.dart';
import '../models/settlement_models.dart';
import 'payment_dialog.dart';

class FinancialDashboardScreen extends StatefulWidget {
  final int groupId;

  final int currentUserId;

  final String groupName;

  const FinancialDashboardScreen({
    super.key,
    required this.groupId,
    required this.currentUserId,
    this.groupName = 'Nhóm',
  });

  @override
  State<FinancialDashboardScreen> createState() =>
      _FinancialDashboardScreenState();
}

class _FinancialDashboardScreenState extends State<FinancialDashboardScreen> {
  final _api = SettlementApiService();

  String _period = 'MONTH';

  bool _loading = true;

  String? _error;

  DebtSummary? _debt;

  FinancialStats? _stats;

  SmartSettlementResult? _smart;

  List<SettlementRecord> _settlements = const [];

  final _currency = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  String _money(
    double value,
  ) {
    return _currency.format(
      value,
    );
  }

  @override
  void initState() {
    super.initState();

    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;

      _error = null;
    });

    try {
      final results = await Future.wait([
        _api.getDebtSummary(
          widget.groupId,
          widget.currentUserId,
        ),
        _api.getStats(
          widget.groupId,
          widget.currentUserId,
          _period,
        ),
        _api.getSettlements(
          widget.groupId,
          widget.currentUserId,
        ),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _debt = results[0] as DebtSummary;

        _stats = results[1] as FinancialStats;

        _settlements = results[2] as List<SettlementRecord>;
      });
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(
          () => _loading = false,
        );
      }
    }
  }

  Future<void> _runSmartSettlement() async {
    try {
      final result = await _api.getSmartSettlement(
        widget.groupId,
        widget.currentUserId,
      );

      if (mounted) {
        setState(
          () => _smart = result,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Xén nợ thất bại: $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _createFromSuggestion(
    DebtEdge edge,
  ) async {
    try {
      final settlement = await _api.createSettlement(
        groupId: widget.groupId,
        currentUserId: widget.currentUserId,
        suggestion: edge,
      );

      await _load();

      if (!mounted) {
        return;
      }

      if (settlement.debtorId == widget.currentUserId) {
        showDialog(
          context: context,
          builder: (_) => PaymentDialog(
            groupId: widget.groupId,
            currentUserId: widget.currentUserId,
            settlement: settlement,
            onUpdated: _load,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đã tạo yêu cầu quyết toán. '
              'Người trả sẽ nhận được thông báo.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không thể tạo giao dịch: $e',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tài chính • '
          '${widget.groupName}',
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? _ErrorState(
                  message: _error!,
                  onRetry: _load,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(
                      16,
                    ),
                    children: [
                      _buildPeriodSelector(),
                      const SizedBox(
                        height: 16,
                      ),
                      _buildSummaryCards(),
                      const SizedBox(
                        height: 20,
                      ),
                      _buildCategoryChart(),
                      const SizedBox(
                        height: 20,
                      ),
                      _buildMemberChart(),
                      const SizedBox(
                        height: 20,
                      ),
                      _buildDebtSection(),
                      const SizedBox(
                        height: 20,
                      ),
                      _buildSmartSettlement(),
                      const SizedBox(
                        height: 20,
                      ),
                      _buildPendingSettlements(),
                      const SizedBox(
                        height: 32,
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPeriodSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'WEEK',
          label: Text('Tuần'),
        ),
        ButtonSegment(
          value: 'MONTH',
          label: Text('Tháng'),
        ),
        ButtonSegment(
          value: 'ALL',
          label: Text('Tất cả'),
        ),
      ],
      selected: {
        _period,
      },
      onSelectionChanged: (value) {
        setState(
          () => _period = value.first,
        );

        _load();
      },
    );
  }

  Widget _buildSummaryCards() {
    final stats = _stats!;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        _metric(
          'Tổng chi tiêu',
          _money(
            stats.totalExpense,
          ),
          Icons.payments_outlined,
        ),
        _metric(
          'Bạn đã trả',
          _money(
            stats.totalPaidByCurrentUser,
          ),
          Icons.account_balance_wallet_outlined,
        ),
        _metric(
          'Bạn cần trả',
          _money(
            stats.totalDebtToPay,
          ),
          Icons.north_east_rounded,
        ),
        _metric(
          'Bạn sẽ nhận',
          _money(
            stats.totalDebtToReceive,
          ),
          Icons.south_west_rounded,
        ),
      ],
    );
  }

  Widget _metric(
    String label,
    String value,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(
          14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
            const Spacer(),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart() {
    final data = _stats!.byCategory;

    return _section(
      'Chi tiêu theo danh mục',
      data.isEmpty
          ? const _EmptyText(
              'Chưa có dữ liệu trong khoảng thời gian đã chọn.',
            )
          : SizedBox(
              height: 230,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 45,
                  sectionsSpace: 3,
                  sections: List.generate(
                    data.length,
                    (index) {
                      final item = data[index];

                      final colors = [
                        Colors.deepPurple,
                        Colors.orange,
                        Colors.teal,
                        Colors.pink,
                        Colors.blue,
                        Colors.green,
                        Colors.amber,
                      ];

                      return PieChartSectionData(
                        value: item.amount,
                        title: item.amount <= 0 ? '' : item.label,
                        radius: 68,
                        color: colors[index % colors.length],
                        titleStyle: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildMemberChart() {
    final data = _stats!.byMember.take(5).toList();

    return _section(
      'Top người chi tiêu',
      data.isEmpty
          ? const _EmptyText(
              'Chưa có dữ liệu thành viên.',
            )
          : Column(
              children: data.map(
                (item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Text(
                          _money(
                            item.amount,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ).toList(),
            ),
    );
  }

  Widget _buildDebtSection() {
    final debt = _debt!;

    return _section(
      'Ai nợ ai',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bạn cần trả',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(
            height: 8,
          ),
          if (debt.youOwe.isEmpty)
            const _EmptyText(
              'Bạn không có khoản phải trả.',
            )
          else
            ...debt.youOwe.map(
              (edge) => _debtTile(
                edge,
                outgoing: true,
              ),
            ),
          const Divider(
            height: 28,
          ),
          Text(
            'Bạn sẽ nhận',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(
            height: 8,
          ),
          if (debt.owedToYou.isEmpty)
            const _EmptyText(
              'Không có khoản phải nhận.',
            )
          else
            ...debt.owedToYou.map(
              (edge) => _debtTile(
                edge,
                outgoing: false,
              ),
            ),
        ],
      ),
    );
  }

  Widget _debtTile(
    DebtEdge edge, {
    required bool outgoing,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        child: Icon(
          outgoing ? Icons.north_east : Icons.south_west,
        ),
      ),
      title: Text(
        outgoing ? 'Bạn → ${edge.creditorName}' : '${edge.debtorName} → Bạn',
      ),
      trailing: Text(
        _money(
          edge.amount,
        ),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildSmartSettlement() {
    return _section(
      'Xén nợ thông minh',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: _runSmartSettlement,
            icon: const Icon(
              Icons.auto_awesome,
            ),
            label: const Text(
              'Chạy Smart Settlement',
            ),
          ),
          if (_smart != null) ...[
            const SizedBox(
              height: 14,
            ),
            Text(
              'Giao dịch: '
              '${_smart!.beforeTransactionCount} '
              '→ '
              '${_smart!.afterTransactionCount}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            if (_smart!.suggestions.isEmpty)
              const _EmptyText(
                'Nhóm đã cân bằng, không cần tạo giao dịch mới.',
              )
            else
              ..._smart!.suggestions.map(
                (edge) {
                  return Card(
                    margin: const EdgeInsets.only(
                      bottom: 8,
                    ),
                    child: ListTile(
                      title: Text(
                        '${edge.debtorName} '
                        '→ '
                        '${edge.creditorName}',
                      ),
                      subtitle: Text(
                        _money(
                          edge.amount,
                        ),
                      ),
                      trailing: (edge.debtorId == widget.currentUserId ||
                              edge.creditorId == widget.currentUserId)
                          ? TextButton(
                              onPressed: () => _createFromSuggestion(
                                edge,
                              ),
                              child: const Text(
                                'Quyết toán',
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingSettlements() {
    final relevant = _settlements
        .where(
          (settlement) =>
              settlement.status != 'CONFIRMED' &&
              settlement.status != 'CANCELLED',
        )
        .toList();

    return _section(
      'Thanh toán chờ xử lý',
      relevant.isEmpty
          ? const _EmptyText(
              'Không có giao dịch đang chờ.',
            )
          : Column(
              children: relevant.map(
                (settlement) {
                  final canAct = (settlement.status == 'PENDING' &&
                          settlement.debtorId == widget.currentUserId) ||
                      (settlement.status == 'PAID' &&
                          settlement.creditorId == widget.currentUserId);

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${settlement.debtorName} '
                      '→ '
                      '${settlement.creditorName}',
                    ),
                    subtitle: Text(
                      '${_money(settlement.amount)} '
                      '• '
                      '${settlement.status}',
                    ),
                    trailing: canAct
                        ? FilledButton.tonal(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => PaymentDialog(
                                  groupId: widget.groupId,
                                  currentUserId: widget.currentUserId,
                                  settlement: settlement,
                                  onUpdated: _load,
                                ),
                              );
                            },
                            child: Text(
                              settlement.status == 'PENDING'
                                  ? 'Thanh toán'
                                  : 'Xác nhận',
                            ),
                          )
                        : null,
                  );
                },
              ).toList(),
            ),
    );
  }

  Widget _section(
    String title,
    Widget child,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(
          16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(
              height: 14,
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  final String text;

  const _EmptyText(
    this.text,
  );

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
            ),
            const SizedBox(
              height: 12,
            ),
            const Text(
              'Không tải được dữ liệu',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 16,
            ),
            FilledButton(
              onPressed: onRetry,
              child: const Text(
                'Thử lại',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
