import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/api.dart';
import '../../core/widgets/reference_ui.dart';
import '../../core/widgets/premium_ui.dart';
import '../../widgets/design.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});
  @override State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final description = TextEditingController();
  String currency = 'VND';
  bool busy = false;

  @override void dispose() { name.dispose(); description.dispose(); super.dispose(); }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await Api.call('/groups', method: 'POST', body: {
        'name': name.text.trim(),
        'description': description.text.trim(),
        'currency': currency,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tạo nhóm mới')),
    body: SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 34),
            child: Form(
              key: form,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Center(
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(Icons.groups_rounded, color: AppColors.primary, size: 44),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: name,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'Tên nhóm', hintText: 'Hải Phòng Trip'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Nhập tên nhóm.' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: description,
                  maxLength: 500,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Mô tả (tùy chọn)', hintText: 'Chuyến đi cuối tuần...'),
                ),
                const SizedBox(height: 16),
                Text('Tiền tệ', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['VND', 'USD', 'EUR'].map((value) => ChoiceChip(
                    label: Text(value),
                    selected: currency == value,
                    onSelected: busy ? null : (_) => setState(() => currency = value),
                  )).toList(),
                ),
                const SizedBox(height: 22),
                Surface(
                  interactive: false,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.link_rounded, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Mã mời tự động', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      const Text('Sau khi tạo nhóm, SplitDebt sẽ sinh mã mời để bạn chia sẻ cho các thành viên.'),
                    ])),
                  ]),
                ),
                const SizedBox(height: 24),
                BusyButton(busy: busy, label: 'Tạo nhóm', onPressed: save),
              ]),
            ),
          ),
        ),
      ),
    ),
  );
}

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});
  @override State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final code = TextEditingController();
  final form = GlobalKey<FormState>();
  bool busy = false;
  @override void dispose() { code.dispose(); super.dispose(); }

  Future<void> join() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await Api.call('/groups/join', method: 'POST', body: {'inviteCode': code.text.trim().toUpperCase()});
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tham gia nhóm')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Orb(icon: Icons.key_rounded),
          const SizedBox(height: 26),
          Text('Nhập mã mời', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text('Mã mời do Trưởng nhóm chia sẻ. Sau khi tham gia, bạn sẽ thấy khoản chi và công nợ của nhóm.', textAlign: TextAlign.center),
          const SizedBox(height: 20),
          TextFormField(
            controller: code,
            textCapitalization: TextCapitalization.characters,
            maxLength: 64,
            decoration: const InputDecoration(labelText: 'Mã mời', hintText: 'AB12CD34EF'),
            validator: (v) => v == null || v.trim().isEmpty ? 'Nhập mã mời.' : null,
          ),
          const SizedBox(height: 12),
          BusyButton(busy: busy, label: 'Tham gia', onPressed: join),
        ]),
      ),
    ),
  );
}

class EditProfileScreen extends StatefulWidget {
  final String name;
  final String phone;
  final String avatarUrl;
  const EditProfileScreen({super.key, required this.name, this.phone = '', this.avatarUrl = ''});
  @override State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController name = TextEditingController(text: widget.name);
  late final TextEditingController phone = TextEditingController(text: widget.phone);
  late final TextEditingController avatar = TextEditingController(text: widget.avatarUrl);
  final form = GlobalKey<FormState>();
  bool busy = false;

  @override void dispose() { name.dispose(); phone.dispose(); avatar.dispose(); super.dispose(); }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await Api.call('/me', method: 'PATCH', body: {
        'fullName': name.text.trim(),
        'phone': phone.text.trim(),
        'avatarUrl': avatar.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chỉnh sửa hồ sơ')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextFormField(
            controller: name,
            maxLength: 100,
            decoration: const InputDecoration(labelText: 'Họ và tên'),
            validator: (v) => v == null || v.trim().length < 2 ? 'Nhập họ tên.' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(controller: phone, maxLength: 20, keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Số điện thoại')),
          const SizedBox(height: 12),
          TextFormField(controller: avatar, decoration: const InputDecoration(labelText: 'Avatar URL (không bắt buộc)')),
          const SizedBox(height: 24),
          BusyButton(busy: busy, label: 'Lưu thay đổi', onPressed: save),
        ]),
      ),
    ),
  );
}

class AddMemberScreen extends StatefulWidget {
  final int groupId;
  const AddMemberScreen({super.key, required this.groupId});
  @override State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final identifier = TextEditingController();
  final form = GlobalKey<FormState>();
  bool busy = false;
  @override void dispose() { identifier.dispose(); super.dispose(); }

  String? validateIdentifier(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Nhập email hoặc số điện thoại.';
    if (text.contains('@')) {
      return text.contains('.') ? null : 'Email chưa đúng định dạng.';
    }
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 9 && digits.length <= 15 ? null : 'Số điện thoại chưa hợp lệ.';
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await Api.call('/groups/${widget.groupId}/members', method: 'POST', body: {
        'identifier': identifier.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Thêm thành viên')),
    body: SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 34),
            child: Form(
              key: form,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Center(
                  child: Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary, size: 38),
                  ),
                ),
                const SizedBox(height: 22),
                Text('Mời thêm thành viên', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Text(
                  'Trưởng nhóm có thể thêm trực tiếp bằng email hoặc số điện thoại. Thành viên cũng có thể tự tham gia bằng mã nhóm.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                Surface(
                  interactive: false,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.key_rounded, color: AppColors.primary),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Cách 1 · Chia sẻ mã nhóm để thành viên tự tham gia từ màn hình “Tham gia nhóm”.')),
                  ]),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: identifier,
                  keyboardType: TextInputType.text,
                  autofillHints: const [AutofillHints.email, AutofillHints.telephoneNumber],
                  decoration: const InputDecoration(
                    labelText: 'Email hoặc số điện thoại',
                    hintText: 'duy@example.com hoặc 0912345678',
                    prefixIcon: Icon(Icons.person_search_rounded),
                  ),
                  validator: validateIdentifier,
                ),
                const SizedBox(height: 10),
                const Text('Cách 2 · Hệ thống tìm đúng tài khoản SplitDebt rồi thêm vào nhóm ngay.'),
                const SizedBox(height: 24),
                BusyButton(busy: busy, label: 'Thêm vào nhóm', onPressed: save),
              ]),
            ),
          ),
        ),
      ),
    ),
  );
}

class _ItemDraft {
  final name = TextEditingController();
  final total = TextEditingController();
  final Set<int> participants = {};
  void dispose() { name.dispose(); total.dispose(); }
}

class AddExpenseScreen extends StatefulWidget {
  final Map<String, dynamic> detail;
  final Map<String, dynamic>? existing;
  const AddExpenseScreen({super.key, required this.detail, this.existing});
  @override State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController();
  final description = TextEditingController();
  final amount = TextEditingController();
  final receipt = TextEditingController();
  late final Map<String, dynamic> group = Map<String, dynamic>.from(widget.detail['group'] as Map);
  late final List<Map<String, dynamic>> people = maps(widget.detail['members']);
  late int payer;
  final Set<int> selected = {};
  final Map<int, TextEditingController> values = {};
  final List<_ItemDraft> items = [];
  late DateTime expenseDate = DateTime.now();
  String splitType = 'EQUAL';
  int? categoryId;
  bool busy = false;
  late Future<List<Map<String, dynamic>>> categoriesFuture;

  String get currency => group['currency'].toString();
  int get groupId => asInt(group['id']);
  int get ownerId => asInt(group['ownerId']);

  String get splitHelp => switch (splitType) {
    'EQUAL' => 'Chia đều tổng tiền cho tất cả người đang được chọn.',
    'AMOUNT' => 'Nhập chính xác số tiền mỗi người chịu. Tổng phải khớp tổng khoản chi.',
    'PERCENT' => 'Nhập phần trăm cho từng người. Tổng phần trăm phải bằng 100%.',
    'WEIGHT' => 'Dùng trọng số khi mức sử dụng khác nhau, ví dụ 1 phần và 2 phần.',
    'ITEM' => 'Tách hóa đơn theo từng món rồi chọn người sử dụng từng món.',
    _ => 'Chọn cách chia phù hợp với khoản chi.',
  };

  @override
  void initState() {
    super.initState();
    categoriesFuture = Api.call('/categories').then(maps);
    payer = ownerId;
    for (final p in people) {
      final id = asInt(p['id']);
      if (id != ownerId) selected.add(id);
      values[id] = TextEditingController();
    }
    // Nhóm chỉ có Trưởng nhóm vẫn cần một người tham gia hợp lệ.
    if (selected.isEmpty && people.isNotEmpty) selected.add(ownerId);
    final e = widget.existing;
    if (e != null) {
      title.text = e['title']?.toString() ?? '';
      description.text = e['description']?.toString() ?? '';
      amount.text = _moneyInput(asInt(e['amount']), currency);
      receipt.text = e['receiptUrl']?.toString() ?? '';
      payer = asInt(e['payerId']);
      categoryId = e['categoryId'] == null ? null : asInt(e['categoryId']);
      expenseDate = DateTime.tryParse(e['expenseDate']?.toString() ?? '') ?? DateTime.now();
      final shares = maps(e['shares']);
      if (shares.isNotEmpty) splitType = shares.first['splitType']?.toString() ?? 'EQUAL';
      selected.clear();
      for (final s in shares) {
        final id = asInt(s['userId']);
        selected.add(id);
        values.putIfAbsent(id, () => TextEditingController());
        if (splitType == 'AMOUNT') values[id]!.text = _moneyInput(asInt(s['amount']), currency);
        if (splitType == 'PERCENT') values[id]!.text = s['percentage']?.toString() ?? '';
        if (splitType == 'WEIGHT') values[id]!.text = s['weight']?.toString() ?? '';
      }
      if (splitType == 'ITEM') {
        for (final old in maps(e['items'])) {
          final d = _ItemDraft();
          d.name.text = old['itemName']?.toString() ?? '';
          d.total.text = _moneyInput(asInt(old['totalPrice']), currency);
          for (final ps in maps(old['participants'])) {
            d.participants.add(asInt(ps['userId']));
          }
          items.add(d);
        }
      }
    }
  }

  @override
  void dispose() {
    title.dispose(); description.dispose(); amount.dispose(); receipt.dispose();
    for (final c in values.values) {
      c.dispose();
    }
    for (final item in items) {
      item.dispose();
    }
    super.dispose();
  }

  String _moneyInput(int minor, String currency) {
    if (currency == 'VND') return '$minor';
    return '${minor ~/ 100}.${(minor % 100).toString().padLeft(2, '0')}';
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => expenseDate = date);
  }

  Map<String, dynamic> participantFor(int id) {
    final out = <String, dynamic>{'userId': id};
    if (splitType == 'AMOUNT') out['amount'] = parseMoney(values[id]!.text, currency);
    if (splitType == 'PERCENT') out['percentage'] = double.tryParse(values[id]!.text.trim());
    if (splitType == 'WEIGHT') out['weight'] = double.tryParse(values[id]!.text.trim());
    return out;
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    if (selected.isEmpty) { showError(context, 'Chọn ít nhất một người tham gia.'); return; }
    final total = parseMoney(amount.text, currency);
    if (total == null) { showError(context, 'Số tiền không hợp lệ.'); return; }
    if (splitType == 'AMOUNT') {
      final sum = selected.fold<int>(0, (v, id) => v + (parseMoney(values[id]!.text, currency) ?? -999999999));
      if (sum != total) { showError(context, 'Tổng số tiền chia phải bằng tổng khoản chi.'); return; }
    }
    if (splitType == 'PERCENT') {
      final sum = selected.fold<double>(0, (v, id) => v + (double.tryParse(values[id]!.text.trim()) ?? -1000));
      if ((sum - 100).abs() > 0.0001) { showError(context, 'Tổng phần trăm phải bằng 100%.'); return; }
    }
    if (splitType == 'WEIGHT' && selected.any((id) => (double.tryParse(values[id]!.text.trim()) ?? 0) <= 0)) {
      showError(context, 'Trọng số của mỗi người phải lớn hơn 0.'); return;
    }
    final itemPayload = <Map<String, dynamic>>[];
    if (splitType == 'ITEM') {
      if (items.isEmpty) { showError(context, 'Thêm ít nhất một món.'); return; }
      var sum = 0;
      for (final item in items) {
        final itemTotal = parseMoney(item.total.text, currency);
        if (item.name.text.trim().isEmpty || itemTotal == null || item.participants.isEmpty) {
          showError(context, 'Mỗi món cần tên, số tiền và ít nhất một người tham gia.'); return;
        }
        if (!item.participants.every(selected.contains)) {
          showError(context, 'Người tham gia món phải nằm trong danh sách người tham gia khoản chi.'); return;
        }
        sum += itemTotal;
        itemPayload.add({
          'itemName': item.name.text.trim(),
          'quantity': 1,
          'unitPrice': itemTotal,
          'totalPrice': itemTotal,
          'participantIds': item.participants.toList(),
        });
      }
      if (sum != total) { showError(context, 'Tổng tiền các món phải bằng tổng khoản chi.'); return; }
    }

    setState(() => busy = true);
    try {
      final sortedParticipantIds = selected.toList()..sort();
      final body = <String, dynamic>{
        'title': title.text.trim(),
        'description': description.text.trim(),
        'totalAmount': total,
        'categoryId': categoryId,
        'payerId': payer,
        'expenseDate': '${expenseDate.year.toString().padLeft(4, '0')}-${expenseDate.month.toString().padLeft(2, '0')}-${expenseDate.day.toString().padLeft(2, '0')}',
        'receiptUrl': receipt.text.trim(),
        'splitType': splitType,
        'participants': sortedParticipantIds.map(participantFor).toList(),
        'items': itemPayload,
      };
      if (widget.existing == null) {
        await Api.call('/groups/$groupId/expenses', method: 'POST', body: body);
      } else {
        await Api.call('/groups/$groupId/expenses/${widget.existing!['id']}', method: 'PUT', body: body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void addItem() {
    final item = _ItemDraft();
    item.participants.addAll(selected);
    setState(() => items.add(item));
  }

  @override
  Widget build(BuildContext context) {
    final parsedTotal = parseMoney(amount.text, currency) ?? 0;
    final equalShare = selected.isEmpty ? 0 : parsedTotal ~/ selected.length;
    final myId = Session.userId ?? -1;
    final myShare = splitType == 'EQUAL' && selected.contains(myId)
        ? equalShare
        : splitType == 'AMOUNT' && selected.contains(myId)
            ? (parseMoney(values[myId]?.text ?? '', currency) ?? 0)
            : 0;

    IconData categoryIcon(String label) {
      final value = label.toLowerCase();
      if (value.contains('ăn')) return Icons.ramen_dining_rounded;
      if (value.contains('di chuyển')) return Icons.directions_car_rounded;
      if (value.contains('khách')) return Icons.hotel_rounded;
      if (value.contains('mua')) return Icons.shopping_bag_rounded;
      if (value.contains('giải')) return Icons.movie_rounded;
      return Icons.inventory_2_rounded;
    }

    final me = people.firstWhere(
      (p) => asInt(p['id']) == myId,
      orElse: () => {'name': 'Bạn'},
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PremiumBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Quay lại',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Expanded(
                      child: Text(
                        widget.existing == null ? 'Thêm khoản chi' : 'Sửa khoản chi',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                    Avatar(me['name']?.toString() ?? 'Bạn', radius: 17, imageUrl: me['avatarUrl']?.toString()),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
                      child: Form(
                        key: form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            StaggerReveal(
                              index: 0,
                              child: Surface(
                                interactive: false,
                                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                                child: Column(
                                  children: [
                                    Text('AMOUNT', style: Theme.of(context).textTheme.labelSmall),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: amount,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: 'Geist',
                                        fontSize: 34,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -1.2,
                                        color: AppColors.textPrimary,
                                      ),
                                      onChanged: (_) => setState(() {}),
                                      decoration: InputDecoration(
                                        hintText: '0',
                                        prefixText: currency == 'VND' ? '₫ ' : '',
                                        suffixText: currency == 'VND' ? null : currency,
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        filled: false,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      validator: (v) => parseMoney(v ?? '', currency) == null ? 'Nhập số tiền hợp lệ.' : null,
                                    ),
                                    const SizedBox(height: 6),
                                    TextButton.icon(
                                      onPressed: pickDate,
                                      icon: const Icon(Icons.calendar_month_rounded, size: 16),
                                      label: Text(
                                        '${expenseDate.day.toString().padLeft(2, '0')}/${expenseDate.month.toString().padLeft(2, '0')}/${expenseDate.year}',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: title,
                              maxLength: 200,
                              decoration: const InputDecoration(
                                labelText: 'Khoản chi',
                                hintText: 'Saturday Night Pizza',
                                prefixIcon: Icon(Icons.receipt_long_rounded),
                                counterText: '',
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Nhập tên khoản chi.' : null,
                            ),
                            const SizedBox(height: 14),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final compact = constraints.maxWidth < 390;
                                final payerField = DropdownButtonFormField<int>(
                                  initialValue: payer,
                                  isExpanded: true,
                                  decoration: const InputDecoration(labelText: 'Người trả'),
                                  items: people.map((p) => DropdownMenuItem<int>(
                                    value: asInt(p['id']),
                                    child: Row(
                                      children: [
                                        Avatar(p['name'].toString(), radius: 13, imageUrl: p['avatarUrl']?.toString()),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            asInt(p['id']) == ownerId ? '${p['name']} · Trưởng nhóm' : p['name'].toString(),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )).toList(),
                                  onChanged: busy || widget.existing == null ? null : (v) => setState(() => payer = v!),
                                );
                                final categoryField = FutureBuilder<List<Map<String, dynamic>>>(
                                  future: categoriesFuture,
                                  builder: (context, snapshot) {
                                    final categories = snapshot.data ?? const <Map<String, dynamic>>[];
                                    if (snapshot.connectionState != ConnectionState.done) {
                                      return const SizedBox(height: 58, child: Center(child: LinearProgressIndicator()));
                                    }
                                    return DropdownButtonFormField<int>(
                                      initialValue: categoryId ?? 0,
                                      isExpanded: true,
                                      decoration: const InputDecoration(labelText: 'Danh mục'),
                                      items: [
                                        const DropdownMenuItem<int>(value: 0, child: Text('Khác')),
                                        ...categories.map((c) => DropdownMenuItem<int>(
                                          value: asInt(c['id']),
                                          child: Row(
                                            children: [
                                              Icon(categoryIcon(c['name'].toString()), size: 18, color: AppColors.tertiary),
                                              const SizedBox(width: 7),
                                              Expanded(child: Text(c['name'].toString(), overflow: TextOverflow.ellipsis)),
                                            ],
                                          ),
                                        )),
                                      ],
                                      onChanged: busy ? null : (v) => setState(() => categoryId = v == 0 ? null : v),
                                    );
                                  },
                                );
                                return compact
                                    ? Column(children: [payerField, const SizedBox(height: 12), categoryField])
                                    : Row(children: [Expanded(child: payerField), const SizedBox(width: 12), Expanded(child: categoryField)]);
                              },
                            ),
                            if (widget.existing == null) ...[
                              const SizedBox(height: 12),
                              Surface(
                                interactive: false,
                                padding: const EdgeInsets.all(13),
                                child: Row(
                                  children: [
                                    const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary, size: 19),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Người trả mặc định: Trưởng nhóm. Tổng chi được ghi nhận cho trưởng nhóm, sau đó chia phần phải thanh toán cho các thành viên còn lại.',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            Surface(
                              interactive: false,
                              child: Column(
                                children: [
                                  const Icon(Icons.receipt_long_outlined, color: AppColors.textSecondary, size: 27),
                                  const SizedBox(height: 7),
                                  Text('Hóa đơn / chứng từ', style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 4),
                                  Text('Có thể thêm đường dẫn ảnh hoặc PDF hóa đơn', style: Theme.of(context).textTheme.bodySmall),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: receipt,
                                    decoration: const InputDecoration(
                                      hintText: 'URL hóa đơn (không bắt buộc)',
                                      prefixIcon: Icon(Icons.link_rounded),
                                    ),
                                  ),
                                  const SizedBox(height: 9),
                                  OutlinedButton.icon(
                                    onPressed: () => showInfo(context, 'Bạn có thể dán URL ảnh hóa đơn vào ô phía trên.', title: 'Receipt'),
                                    icon: const Icon(Icons.qr_code_scanner_rounded),
                                    label: const Text('OCR SCAN'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text('Split Options', style: Theme.of(context).textTheme.labelMedium),
                            const SizedBox(height: 10),
                            PillSegment<String>(
                              items: const [
                                ('EQUAL', 'Equal'),
                                ('AMOUNT', 'Exact'),
                                ('PERCENT', '%'),
                                ('WEIGHT', 'Weight'),
                                ('ITEM', 'Item'),
                              ],
                              value: splitType,
                              onChanged: busy ? (_) {} : (v) => setState(() => splitType = v),
                            ),
                            const SizedBox(height: 10),
                            Text(splitHelp, style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 12),
                            ...people.asMap().entries.map((entry) {
                              final index = entry.key;
                              final p = entry.value;
                              final id = asInt(p['id']);
                              final checked = selected.contains(id);
                              final preview = splitType == 'EQUAL' && checked ? equalShare : 0;
                              return StaggerReveal(
                                index: 1 + index,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 9),
                                  child: Surface(
                                    padding: EdgeInsets.zero,
                                    child: Column(
                                      children: [
                                        CheckboxListTile(
                                          value: checked,
                                          onChanged: busy ? null : (v) => setState(() {
                                            if (v == true) {
                                              selected.add(id);
                                            } else {
                                              selected.remove(id);
                                            }
                                          }),
                                          title: Row(
                                            children: [
                                              Avatar(p['name'].toString(), radius: 17, imageUrl: p['avatarUrl']?.toString()),
                                              const SizedBox(width: 10),
                                              Expanded(child: Text(p['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w800))),
                                              if (splitType == 'EQUAL' && checked)
                                                Text(money(preview, currency), style: const TextStyle(fontFamily: 'Geist', color: AppColors.tertiary, fontWeight: FontWeight.w900)),
                                            ],
                                          ),
                                          controlAffinity: ListTileControlAffinity.leading,
                                        ),
                                        if (checked && {'AMOUNT', 'PERCENT', 'WEIGHT'}.contains(splitType))
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                                            child: TextFormField(
                                              controller: values[id],
                                              onChanged: (_) => setState(() {}),
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              decoration: InputDecoration(
                                                labelText: splitType == 'AMOUNT'
                                                    ? 'Số tiền của ${p['name']}'
                                                    : splitType == 'PERCENT'
                                                        ? 'Phần trăm'
                                                        : 'Trọng số',
                                                suffixText: splitType == 'AMOUNT' ? currency : splitType == 'PERCENT' ? '%' : null,
                                              ),
                                              validator: (v) {
                                                if (!selected.contains(id)) return null;
                                                if (splitType == 'AMOUNT') {
                                                  return parseMoney(v ?? '', currency) == null ? 'Nhập số tiền.' : null;
                                                }
                                                if (splitType == 'PERCENT' || splitType == 'WEIGHT') {
                                                  final number = double.tryParse(v?.trim() ?? '');
                                                  return number != null && number > 0 ? null : 'Nhập giá trị lớn hơn 0.';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                            if (splitType == 'ITEM') ...[
                              SectionTitle(
                                'Các món',
                                trailing: TextButton.icon(onPressed: addItem, icon: const Icon(Icons.add), label: const Text('Thêm món')),
                              ),
                              if (items.isEmpty)
                                const EmptyState(
                                  title: 'Chưa có món',
                                  description: 'Thêm từng món trong hóa đơn và chọn ai sử dụng món đó.',
                                  icon: Icons.restaurant_menu_rounded,
                                ),
                              ...List.generate(items.length, (index) {
                                final item = items[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Surface(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(child: Text('Món ${index + 1}', style: Theme.of(context).textTheme.titleMedium)),
                                            IconButton(
                                              onPressed: busy ? null : () => setState(() {
                                                item.dispose();
                                                items.removeAt(index);
                                              }),
                                              icon: const Icon(Icons.delete_outline_rounded),
                                            ),
                                          ],
                                        ),
                                        TextFormField(controller: item.name, decoration: const InputDecoration(labelText: 'Tên món')),
                                        const SizedBox(height: 10),
                                        TextFormField(
                                          controller: item.total,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          decoration: InputDecoration(labelText: 'Thành tiền', suffixText: currency),
                                        ),
                                        const SizedBox(height: 10),
                                        const Text('Người dùng món:', style: TextStyle(fontWeight: FontWeight.w700)),
                                        ...people.where((p) => selected.contains(asInt(p['id']))).map((p) {
                                          final id = asInt(p['id']);
                                          return CheckboxListTile(
                                            dense: true,
                                            value: item.participants.contains(id),
                                            title: Text(p['name'].toString()),
                                            onChanged: busy ? null : (v) => setState(() {
                                              if (v == true) {
                                                item.participants.add(id);
                                              } else {
                                                item.participants.remove(id);
                                              }
                                            }),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: description,
                              minLines: 2,
                              maxLines: 4,
                              decoration: const InputDecoration(labelText: 'Ghi chú (không bắt buộc)'),
                            ),
                            if (myShare > 0) ...[
                              const SizedBox(height: 14),
                              Surface(
                                interactive: false,
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text('Phần của mình', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
                                    ),
                                    Text(
                                      money(myShare, currency),
                                      style: const TextStyle(fontFamily: 'Geist', color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            BrandButton(
                              label: widget.existing == null ? 'Lưu khoản chi' : 'Lưu thay đổi',
                              icon: Icons.check_rounded,
                              busy: busy,
                              onPressed: busy ? null : save,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
