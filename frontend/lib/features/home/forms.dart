import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/api.dart';
import '../../core/widgets/reference_ui.dart';
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
                      color: const Color(0xFFF0EDFF),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(Icons.groups_rounded, color: Color(0xFF6C55EA), size: 44),
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
                    const Icon(Icons.link_rounded, color: Color(0xFF6C55EA)),
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
  final email = TextEditingController();
  final form = GlobalKey<FormState>();
  bool busy = false;
  @override void dispose() { email.dispose(); super.dispose(); }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await Api.call('/groups/${widget.groupId}/members', method: 'POST', body: {'email': email.text.trim()});
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
                      color: const Color(0xFFF0EDFF),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF6C55EA), size: 38),
                  ),
                ),
                const SizedBox(height: 22),
                Text('Mời thêm thành viên', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Text('Nhập email tài khoản SplitDebt. Thành viên cũng có thể tự tham gia bằng mã mời.', textAlign: TextAlign.center),
                const SizedBox(height: 26),
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email thành viên',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                  validator: (v) => v != null && v.contains('@') ? null : 'Nhập email hợp lệ.',
                ),
                const SizedBox(height: 24),
                BusyButton(busy: busy, label: 'Thêm thành viên', onPressed: save),
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
  late final List<Map<String, dynamic>> people = maps(widget.detail['members']);
  late int payer = Session.userId ?? asInt(people.first['id']);
  final Set<int> selected = {};
  final Map<int, TextEditingController> values = {};
  final List<_ItemDraft> items = [];
  late DateTime expenseDate = DateTime.now();
  String splitType = 'EQUAL';
  int? categoryId;
  bool busy = false;
  late Future<List<Map<String, dynamic>>> categoriesFuture;

  String get currency => Map<String, dynamic>.from(widget.detail['group'] as Map)['currency'].toString();
  int get groupId => asInt(Map<String, dynamic>.from(widget.detail['group'] as Map)['id']);

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
    for (final p in people) {
      final id = asInt(p['id']);
      selected.add(id);
      values[id] = TextEditingController();
    }
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
          for (final ps in maps(old['participants'])) d.participants.add(asInt(ps['userId']));
          items.add(d);
        }
      }
    }
  }

  @override
  void dispose() {
    title.dispose(); description.dispose(); amount.dispose(); receipt.dispose();
    for (final c in values.values) c.dispose();
    for (final item in items) item.dispose();
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

    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Thêm khoản chi' : 'Chỉnh sửa khoản chi')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 34),
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Tên khoản chi', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 9),
                    TextFormField(
                      controller: title,
                      maxLength: 200,
                      decoration: const InputDecoration(hintText: 'Ăn tối nhà hàng', counterText: ''),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Nhập tên khoản chi.' : null,
                    ),
                    const SizedBox(height: 20),
                    Text('Số tiền', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
                    const SizedBox(height: 9),
                    TextFormField(
                      controller: amount,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.primary),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: '0',
                        suffixText: currency,
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      validator: (v) => parseMoney(v ?? '', currency) == null ? 'Nhập số tiền hợp lệ.' : null,
                    ),
                    const SizedBox(height: 22),
                    Text('Danh mục', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: categoriesFuture,
                      builder: (context, snapshot) {
                        final categories = snapshot.data ?? const <Map<String, dynamic>>[];
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const LinearProgressIndicator();
                        }
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final c in categories)
                              CategoryChoice(
                                label: c['name'].toString(),
                                icon: categoryIcon(c['name'].toString()),
                                selected: categoryId == asInt(c['id']),
                                onTap: () => setState(() => categoryId = asInt(c['id'])),
                              ),
                            CategoryChoice(
                              label: 'Khác',
                              icon: Icons.inventory_2_rounded,
                              selected: categoryId == null,
                              onTap: () => setState(() => categoryId = null),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 540;
                        final payerField = DropdownButtonFormField<int>(
                          value: payer,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Người trả'),
                          items: people.map((p) => DropdownMenuItem(
                            value: asInt(p['id']),
                            child: Row(children: [
                              Avatar(p['name'].toString(), radius: 14),
                              const SizedBox(width: 9),
                              Expanded(child: Text(p['name'].toString(), overflow: TextOverflow.ellipsis)),
                            ]),
                          )).toList(),
                          onChanged: busy ? null : (v) => setState(() => payer = v!),
                        );
                        final dateField = OutlinedButton.icon(
                          onPressed: pickDate,
                          icon: const Icon(Icons.calendar_month_rounded),
                          label: Text('${expenseDate.day.toString().padLeft(2, '0')}/${expenseDate.month.toString().padLeft(2, '0')}/${expenseDate.year}'),
                        );
                        return compact
                            ? Column(children: [payerField, const SizedBox(height: 12), SizedBox(width: double.infinity, child: dateField)])
                            : Row(children: [Expanded(child: payerField), const SizedBox(width: 12), Expanded(child: SizedBox(height: 56, child: dateField))]);
                      },
                    ),
                    const SizedBox(height: 22),
                    Text('Chia cho', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    PillSegment<String>(
                      items: const [
                        ('EQUAL', 'Chia đều'),
                        ('AMOUNT', 'Số tiền'),
                        ('PERCENT', '%'),
                      ],
                      value: splitType,
                      onChanged: busy ? (_) {} : (v) => setState(() => splitType = v),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Trọng số'),
                          selected: splitType == 'WEIGHT',
                          onSelected: busy ? null : (_) => setState(() => splitType = 'WEIGHT'),
                        ),
                        ChoiceChip(
                          label: const Text('Theo từng món'),
                          selected: splitType == 'ITEM',
                          onSelected: busy ? null : (_) => setState(() => splitType = 'ITEM'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(.65),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(splitHelp)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...people.map((p) {
                      final id = asInt(p['id']);
                      final checked = selected.contains(id);
                      final preview = splitType == 'EQUAL' && checked ? equalShare : 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: Column(
                            children: [
                              CheckboxListTile(
                                value: checked,
                                onChanged: busy ? null : (v) => setState(() {
                                  if (v == true) { selected.add(id); } else { selected.remove(id); }
                                }),
                                title: Row(children: [
                                  Avatar(p['name'].toString(), radius: 17),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(p['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w800))),
                                  if (splitType == 'EQUAL' && checked)
                                    Text(money(preview, currency), style: const TextStyle(fontWeight: FontWeight.w900)),
                                ]),
                                controlAffinity: ListTileControlAffinity.leading,
                              ),
                              if (checked && {'AMOUNT', 'PERCENT', 'WEIGHT'}.contains(splitType))
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                                  child: TextFormField(
                                    controller: values[id],
                                    onChanged: (_) => setState(() {}),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      labelText: splitType == 'AMOUNT' ? 'Số tiền của ${p['name']}' : splitType == 'PERCENT' ? 'Phần trăm' : 'Trọng số',
                                      suffixText: splitType == 'AMOUNT' ? currency : splitType == 'PERCENT' ? '%' : null,
                                    ),
                                    validator: (v) {
                                      if (!selected.contains(id)) return null;
                                      if (splitType == 'AMOUNT') return parseMoney(v ?? '', currency) == null ? 'Nhập số tiền.' : null;
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
                      );
                    }),
                    if (splitType == 'ITEM') ...[
                      SectionTitle('Các món', trailing: TextButton.icon(onPressed: addItem, icon: const Icon(Icons.add), label: const Text('Thêm món'))),
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
                          child: Surface(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            Row(children: [
                              Expanded(child: Text('Món ${index + 1}', style: Theme.of(context).textTheme.titleMedium)),
                              IconButton(onPressed: busy ? null : () => setState(() { item.dispose(); items.removeAt(index); }), icon: const Icon(Icons.delete_outline_rounded)),
                            ]),
                            TextFormField(controller: item.name, decoration: const InputDecoration(labelText: 'Tên món')),
                            const SizedBox(height: 10),
                            TextFormField(controller: item.total, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(labelText: 'Thành tiền', suffixText: currency)),
                            const SizedBox(height: 10),
                            const Text('Người dùng món:', style: TextStyle(fontWeight: FontWeight.w700)),
                            ...people.where((p) => selected.contains(asInt(p['id']))).map((p) {
                              final id = asInt(p['id']);
                              return CheckboxListTile(
                                dense: true,
                                value: item.participants.contains(id),
                                title: Text(p['name'].toString()),
                                onChanged: busy ? null : (v) => setState(() {
                                  if (v == true) { item.participants.add(id); } else { item.participants.remove(id); }
                                }),
                              );
                            }),
                          ])),
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
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: receipt,
                      decoration: const InputDecoration(labelText: 'URL ảnh hóa đơn (không bắt buộc)', prefixIcon: Icon(Icons.camera_alt_outlined)),
                    ),
                    if (myShare > 0) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.primary.withOpacity(.45)),
                        ),
                        child: Row(children: [
                          const Expanded(child: Text('Phần của bạn', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800))),
                          Text(money(myShare, currency), style: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w900)),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 26),
                    BusyButton(
                      busy: busy,
                      label: widget.existing == null ? 'Lưu khoản chi' : 'Lưu chỉnh sửa',
                      onPressed: save,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
