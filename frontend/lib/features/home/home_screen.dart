import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/premium_ui.dart';
import '../../core/widgets/reference_ui.dart';
import '../../data/api.dart';
import '../../widgets/design.dart';
import '../help/quick_guide_screen.dart';
import 'forms.dart';
import 'group_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;
  String query = '';
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerGuideIfNeeded());
  }

  Future<void> _offerGuideIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'home_guide_prompted_${Session.userId ?? 0}';
    if (prefs.getBool(key) == true || !mounted) return;
    await prefs.setBool(key, true);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Orb(icon: Icons.waving_hand_rounded, size: 64),
              const SizedBox(height: 18),
              Text('Chào mừng đến SplitDebt', textAlign: TextAlign.center,
                  style: Theme.of(sheetContext).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Bạn có muốn xem hướng dẫn nhanh về Trang chủ, tạo nhóm, chia tiền và Smart Settlement?',
                textAlign: TextAlign.center,
                style: Theme.of(sheetContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              BrandButton(
                label: 'Xem hướng dẫn nhanh',
                icon: Icons.school_rounded,
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _openGuide();
                },
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: () => Navigator.pop(sheetContext), child: const Text('Để sau')),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openGuide() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickGuideScreen()));
  }

  Future<Map<String, dynamic>> load() async => Map<String, dynamic>.from(await Api.call('/overview') as Map);

  Future<void> refresh() async {
    final next = load();
    setState(() => future = next);
    try { await next; } catch (_) {}
  }

  Future<void> openGroup(Map<String, dynamic> group) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => GroupScreen(id: asInt(group['id']))));
    if (mounted) await refresh();
  }

  Future<void> create() async {
    final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
    if (result == true && mounted) {
      showSuccess(context, 'Nhóm mới đã sẵn sàng. Bạn có thể mời thành viên và thêm khoản chi đầu tiên.', title: 'Đã tạo nhóm');
      await refresh();
    }
  }

  Future<void> join() async {
    final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const JoinGroupScreen()));
    if (result == true && mounted) {
      showSuccess(context, 'Bạn đã tham gia nhóm và có thể xem các khoản chi chung.', title: 'Đã tham gia nhóm');
      await refresh();
    }
  }

  Widget groupTile(Map<String, dynamic> g) {
    final balance = asInt(g['balance']);
    final currency = g['currency'].toString();
    final balanceColor = balance > 0
        ? AppColors.success
        : balance < 0
            ? AppColors.error
            : Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Surface(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => openGroup(g),
          child: Row(children: [
            GroupArtwork(g['name'].toString(), size: 48),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(g['name'].toString(), style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('${g['memberCount']} thành viên · $currency', style: Theme.of(context).textTheme.bodyMedium),
            ])),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                balance == 0 ? '0' : '${balance > 0 ? '+' : '-'}${money(balance.abs(), currency)}',
                style: TextStyle(color: balanceColor, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                balance == 0 ? 'Đã cân bằng' : balance > 0 ? 'Bạn được nhận' : 'Bạn cần trả',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    body: PremiumBackground(
      child: SafeArea(
      child: FutureBuilder<Map<String, dynamic>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: EmptyState(
            title: 'Không thể tải dữ liệu',
            description: snapshot.error.toString(),
            icon: Icons.cloud_off_rounded,
            action: FilledButton(onPressed: refresh, child: const Text('Thử lại')),
          ));
          final data = snapshot.data!;
          final me = Map<String, dynamic>.from(data['me'] as Map);
          final groups = maps(data['groups']);
          if (tab == 2) return ActivityView(onOpen: openGroup);
          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(tab == 0 ? 'KHÔNG GIAN CHUNG' : tab == 1 ? 'CÁC NHÓM CỦA BẠN' : 'TÀI KHOẢN',
                        style: const TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Text(tab == 0 ? 'Xin chào, ${me['name'].toString().split(' ').last}' : tab == 1 ? 'Nhóm chi tiêu' : 'Cá nhân',
                        style: Theme.of(context).textTheme.headlineMedium),
                  ])),
                  IconButton.filledTonal(
                    tooltip: 'Hướng dẫn sử dụng',
                    onPressed: _openGuide,
                    icon: const Icon(Icons.help_outline_rounded),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Thông báo',
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())).then((_) => refresh()),
                    icon: Badge(
                      isLabelVisible: asInt(data['unreadNotifications'] ?? 0) > 0,
                      label: Text('${data['unreadNotifications']}'),
                      child: const Icon(Icons.notifications_none_rounded),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Avatar(me['name'].toString()),
                ]),
                const SizedBox(height: 26),
                if (tab == 0) ...[
                  Builder(builder: (context) {
                    final balances = maps(data['balances']);
                    final summary = balances.isEmpty ? <String, dynamic>{} : balances.first;
                    final currency = (summary['currency'] ?? (groups.isEmpty ? 'VND' : groups.first['currency']) ?? 'VND').toString();
                    final payable = asInt(summary['payable'] ?? 0);
                    final receivable = asInt(summary['receivable'] ?? 0);
                    return SplitSummaryCard(
                      name: me['name'].toString().split(' ').last,
                      payable: payable,
                      receivable: receivable,
                      currency: currency,
                      onGuide: _openGuide,
                    );
                  }),
                  SectionTitle(
                    'Nhóm của tôi',
                    trailing: TextButton(
                      onPressed: () => setState(() => tab = 1),
                      child: const Text('Xem tất cả'),
                    ),
                  ),
                  if (groups.isEmpty)
                    EmptyState(
                      title: 'Chưa có nhóm nào',
                      description: 'Tạo nhóm đầu tiên hoặc tham gia bằng mã mời để bắt đầu chia chi phí.',
                      icon: Icons.groups_2_outlined,
                      action: FilledButton.icon(
                        onPressed: create,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Tạo nhóm đầu tiên'),
                      ),
                    )
                  else
                    SizedBox(
                      height: 162,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: groups.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final g = groups[index];
                          return ReferenceGroupCard(
                            name: g['name'].toString(),
                            memberCount: asInt(g['memberCount']),
                            balance: asInt(g['balance']),
                            currency: g['currency'].toString(),
                            onTap: () => openGroup(g),
                          );
                        },
                      ),
                    ),
                  SectionTitle(
                    'Khoản nợ gần đây',
                    trailing: TextButton.icon(
                      onPressed: _openGuide,
                      icon: const Icon(Icons.school_outlined, size: 18),
                      label: const Text('Hướng dẫn'),
                    ),
                  ),
                  if (groups.where((g) => asInt(g['balance']) != 0).isEmpty)
                    const EmptyState(
                      title: 'Chưa có công nợ',
                      description: 'Khi nhóm có khoản chi, số dư cần trả hoặc được nhận sẽ xuất hiện tại đây.',
                      icon: Icons.account_balance_wallet_outlined,
                    )
                  else
                    ...groups.where((g) => asInt(g['balance']) != 0).take(4).map((g) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DebtListTile(
                        name: g['name'].toString(),
                        amount: asInt(g['balance']).abs(),
                        currency: g['currency'].toString(),
                        positive: asInt(g['balance']) > 0,
                        subtitle: asInt(g['balance']) > 0 ? 'Nhóm cần trả lại cho bạn' : 'Bạn cần thanh toán trong nhóm',
                        onTap: () => openGroup(g),
                      ),
                    )),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: join,
                          icon: const Icon(Icons.login_rounded),
                          label: const Text('Tham gia nhóm'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: create,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Tạo nhóm'),
                        ),
                      ),
                    ],
                  ),
                ],
                if (tab == 1) ...[
                  Row(children: [
                    Expanded(child: TextField(
                      decoration: const InputDecoration(hintText: 'Tìm nhóm', prefixIcon: Icon(Icons.search_rounded)),
                      onChanged: (value) => setState(() => query = value),
                    )),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(tooltip: 'Tham gia bằng mã', onPressed: join, icon: const Icon(Icons.login_rounded)),
                  ]),
                  SectionTitle('${groups.length} nhóm', trailing: TextButton.icon(onPressed: create, icon: const Icon(Icons.add), label: const Text('Tạo nhóm'))),
                  if (groups.isEmpty) EmptyState(
                    title: 'Chưa có nhóm',
                    description: 'Tạo nhóm hoặc nhập mã mời do trưởng nhóm chia sẻ.',
                    action: FilledButton(onPressed: create, child: const Text('Tạo nhóm')),
                  ),
                  if (groups.isNotEmpty && groups.where((g) => g['name'].toString().toLowerCase().contains(query.toLowerCase())).isEmpty)
                    const EmptyState(title: 'Không tìm thấy nhóm', description: 'Thử tên nhóm khác.', icon: Icons.search_off_rounded),
                  ...groups.where((g) => g['name'].toString().toLowerCase().contains(query.toLowerCase())).map(groupTile),
                ],
                if (tab == 3) ...[
                  Center(
                    child: Column(children: [
                      Avatar(me['name'].toString(), radius: 38),
                      const SizedBox(height: 14),
                      Text(me['name'].toString(), style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(me['email'].toString(), style: Theme.of(context).textTheme.bodyMedium),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  Surface(
                    padding: EdgeInsets.zero,
                    child: Column(children: [
                      ListTile(
                        leading: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                        title: const Text('Thông tin cá nhân'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () async {
                          final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => EditProfileScreen(
                            name: me['name'].toString(), phone: me['phone']?.toString() ?? '', avatarUrl: me['avatarUrl']?.toString() ?? '',
                          )));
                          if (changed == true && mounted) await refresh();
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.palette_outlined, color: AppColors.primary),
                        title: const Text('Giao diện'),
                        subtitle: ValueListenableBuilder<ThemeMode>(
                          valueListenable: Appearance.mode,
                          builder: (_, mode, __) => Text(mode == ThemeMode.system ? 'Theo hệ thống' : mode == ThemeMode.light ? 'Sáng' : 'Tối'),
                        ),
                        trailing: PopupMenuButton<ThemeMode>(
                          onSelected: (mode) async {
                            try {
                              await Appearance.set(mode);
                              await Api.call('/me/settings', method: 'PATCH', body: {'theme': mode.name.toUpperCase()});
                            } catch (e) { if (context.mounted) showError(context, e); }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: ThemeMode.system, child: Text('Theo hệ thống')),
                            PopupMenuItem(value: ThemeMode.light, child: Text('Sáng')),
                            PopupMenuItem(value: ThemeMode.dark, child: Text('Tối')),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.language_rounded, color: AppColors.primary),
                        title: const Text('Ngôn ngữ'),
                        subtitle: const Text('Tiếng Việt'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => showInfo(context, 'Phiên bản hiện tại đang sử dụng Tiếng Việt.', title: 'Ngôn ngữ'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.school_outlined, color: AppColors.primary),
                        title: const Text('Hướng dẫn sử dụng'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _openGuide,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                        title: const Text('Giới thiệu SplitDebt'),
                        subtitle: const Text('Quản lý chi tiêu nhóm và công nợ minh bạch'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => showInfo(
                          context,
                          'SplitDebt ghi nhận chi tiêu và thanh toán giữa các thành viên; ứng dụng không trực tiếp nắm giữ tiền.',
                          title: 'SplitDebt',
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async => Session.signOut(),
                      icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                      label: const Text('Đăng xuất', style: TextStyle(color: AppColors.error)),
                    ),
                  ),
                ],

              ],
            ),
          );
        },
      ),
    ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: tab,
      onDestinationSelected: (value) => setState(() => tab = value),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard_rounded), label: 'Tổng quan'),
        NavigationDestination(icon: Icon(Icons.people_outline_rounded), selectedIcon: Icon(Icons.people_rounded), label: 'Nhóm'),
        NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded), label: 'Lịch sử'),
        NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Cá nhân'),
      ],
    ),
  );

  List<Widget> balanceCards(List<Map<String, dynamic>> balances) => balances.map((b) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: BalancePair(currency: b['currency'].toString(), receivable: asInt(b['receivable']), payable: asInt(b['payable'])),
  )).toList();
}

class ActivityView extends StatefulWidget {
  final void Function(Map<String, dynamic>) onOpen;
  const ActivityView({super.key, required this.onOpen});
  @override State<ActivityView> createState() => _ActivityViewState();
}

class _ActivityViewState extends State<ActivityView> {
  late Future<void> initial;
  final items = <Map<String, dynamic>>[];
  int? nextOffset;
  bool loadingMore = false;
  String filter = 'ALL';

  @override void initState() { super.initState(); initial = loadFirst(); }

  Future<void> loadFirst() async {
    final page = Map<String, dynamic>.from(await Api.call('/activity?limit=30&offset=0') as Map);
    items..clear()..addAll(maps(page['items']));
    nextOffset = page['nextOffset'] == null ? null : asInt(page['nextOffset']);
  }

  Future<void> refresh() async {
    final task = loadFirst(); setState(() => initial = task);
    try { await task; } catch (_) {}
  }

  Future<void> more() async {
    if (loadingMore || nextOffset == null) return;
    setState(() => loadingMore = true);
    try {
      final page = Map<String, dynamic>.from(await Api.call('/activity?limit=30&offset=$nextOffset') as Map);
      if (!mounted) return;
      setState(() {
        final known = items.map((e) => '${e['kind']}:${e['id']}').toSet();
        items.addAll(maps(page['items']).where((e) => known.add('${e['kind']}:${e['id']}')));
        nextOffset = page['nextOffset'] == null ? null : asInt(page['nextOffset']);
      });
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => loadingMore = false);
    }
  }

  bool _matches(Map<String, dynamic> item) {
    if (filter == 'ALL') return true;
    final kind = (item['kind'] ?? '').toString().toLowerCase();
    final status = (item['status'] ?? '').toString().toUpperCase();
    if (filter == 'EXPENSE') return kind != 'settlement';
    if (filter == 'PAYMENT') return kind == 'settlement' && status != 'CONFIRMED';
    if (filter == 'RECEIVE') return kind == 'settlement' && status == 'CONFIRMED';
    return true;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: initial,
    builder: (context, snapshot) => RefreshIndicator(
      onRefresh: loadingMore ? () async {} : refresh,
      child: ListView(
        padding: const EdgeInsets.all(24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Text('Lịch sử', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text('Các khoản chi và giao dịch quyết toán gần đây.'),
          const SizedBox(height: 18),
          PillSegment<String>(
            items: const [
              ('ALL', 'Tất cả'),
              ('EXPENSE', 'Chi tiêu'),
              ('PAYMENT', 'Thanh toán'),
              ('RECEIVE', 'Nhận tiền'),
            ],
            value: filter,
            onChanged: (value) => setState(() => filter = value),
          ),
          const SizedBox(height: 24),
          if (snapshot.connectionState != ConnectionState.done) const Center(child: CircularProgressIndicator())
          else if (snapshot.hasError) EmptyState(
            title: 'Không thể tải lịch sử', description: snapshot.error.toString(),
            action: FilledButton(onPressed: refresh, child: const Text('Thử lại')),
          ) else ...[
            if (items.where(_matches).isEmpty) const EmptyState(title: 'Chưa có hoạt động phù hợp', description: 'Thử chọn bộ lọc khác hoặc tạo khoản chi mới.', icon: Icons.receipt_long_rounded),
            ...items.where(_matches).map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Surface(
                padding: EdgeInsets.zero,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Icon(e['kind'] == 'settlement' ? Icons.payments_outlined : Icons.receipt_long_rounded,
                      color: Theme.of(context).colorScheme.primary),
                  title: Text(e['kind'] == 'settlement' ? 'Quyết toán · ${e['status'] ?? ''}' : e['title'].toString()),
                  subtitle: Text('${e['groupName']} · ${money(asInt(e['amount']), e['currency'].toString())}\n${e['payerName']} · ${dateLabel(e['createdAt']?.toString())}'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => widget.onOpen({'id': e['groupId']}),
                ),
              ),
            )),
            if (nextOffset != null) BusyButton(busy: loadingMore, label: 'Tải thêm', onPressed: more),
          ],
        ],
      ),
    ),
  );
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = load();
  }

  Future<List<Map<String, dynamic>>> load() async => maps(await Api.call('/notifications'));

  Future<void> mark(Map<String, dynamic> n) async {
    if (n['isRead'] == true) return;
    try {
      await Api.call('/notifications/${n['id']}/read', method: 'POST');
      if (mounted) setState(() => future = load());
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  FeedbackKind _kind(Map<String, dynamic> n) {
    final type = (n['type'] ?? '').toString().toUpperCase();
    if (type.contains('CONFIRM') || type.contains('SUCCESS') || type.contains('PAID')) {
      return FeedbackKind.success;
    }
    if (type.contains('REMIND') || type.contains('DEBT')) return FeedbackKind.warning;
    if (type.contains('ERROR') || type.contains('FAIL')) return FeedbackKind.error;
    return FeedbackKind.info;
  }

  IconData _icon(Map<String, dynamic> n) {
    final type = (n['type'] ?? '').toString().toUpperCase();
    if (type.contains('EXPENSE')) return Icons.receipt_long_rounded;
    if (type.contains('SETTLEMENT') || type.contains('PAY')) return Icons.payments_rounded;
    if (type.contains('MEMBER') || type.contains('JOIN')) return Icons.person_add_alt_1_rounded;
    if (type.contains('DEBT') || type.contains('REMIND')) return Icons.notifications_active_rounded;
    return Icons.notifications_rounded;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Thông báo')),
        body: PremiumBackground(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return EmptyState(
                  title: 'Không thể tải thông báo',
                  description: snapshot.error.toString(),
                );
              }
              final items = snapshot.data!;
              if (items.isEmpty) {
                return const EmptyState(
                  title: 'Chưa có thông báo',
                  description: 'Các sự kiện quan trọng sẽ xuất hiện tại đây.',
                  icon: Icons.notifications_none_rounded,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(18),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final n = items[i];
                  final kind = _kind(n);
                  return Surface(
                    padding: const EdgeInsets.all(15),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => mark(n),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(.08),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(_icon(n), color: Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        n['title'].toString(),
                                        style: TextStyle(
                                          fontWeight: n['isRead'] == true ? FontWeight.w600 : FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    StatusPill(
                                      label: n['isRead'] == true ? 'Đã đọc' : 'Mới',
                                      kind: n['isRead'] == true ? FeedbackKind.info : kind,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(n['content'].toString()),
                                const SizedBox(height: 7),
                                Text(
                                  dateLabel(n['createdAt']?.toString()),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (n['isRead'] != true) ...[
                                  const SizedBox(height: 7),
                                  Text(
                                    'Chạm để đánh dấu đã đọc',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      );
}
