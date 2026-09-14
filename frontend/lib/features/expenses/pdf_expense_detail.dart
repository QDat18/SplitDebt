import 'package:flutter/material.dart';
import '../../core/theme/pdf_components.dart';
import '../../core/network/dio_client.dart';

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
    final title = TextEditingController(text: expense['title']);
    final note = TextEditingController(text: expense['description'] ?? '');
    final values = await showDialog<Map<String, String>>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Chỉnh sửa khoản chi'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: title,
                    decoration:
                        const InputDecoration(labelText: 'Tên khoản chi')),
                const SizedBox(height: 16),
                TextField(
                    controller: note,
                    decoration: const InputDecoration(labelText: 'Ghi chú'),
                    maxLines: 3)
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Hủy')),
                FilledButton(
                    onPressed: () {
                      if (title.text.trim().isNotEmpty)
                        Navigator.pop(ctx, {
                          'title': title.text.trim(),
                          'description': note.text.trim()
                        });
                    },
                    child: const Text('Lưu'))
              ],
            ));
    // Dialog controllers stay alive until its closing animation completes.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    title.dispose();
    note.dispose();
    if (values == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final parts = expense['participants'] as List? ?? [];
      final response =
          await dioClient.put('/v1/expenses/${expense['id']}', data: {
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
            .map((p) => {
                  'userId': p['userId'],
                  'amount': p['amount'],
                  'percentage': p['percentage'],
                  'weight': p['weight']
                })
            .toList(),
        'items': (expense['items'] as List? ?? [])
            .map((item) => {
                  'itemName': item['itemName'],
                  'quantity': item['quantity'],
                  'unitPrice': item['unitPrice'],
                  'participants': (item['participants'] as List? ?? [])
                      .map((p) => {'userId': p['userId']})
                      .toList()
                })
            .toList(),
      });
      if (mounted)
        setState(
            () => expense = Map<String, dynamic>.from(response.data['data']));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Không thể sửa khoản chi. Kiểm tra quyền và trạng thái quyết toán.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Xóa khoản chi?'),
                content: Text(
                    'Xóa “${expense['title']}” và cập nhật công nợ của nhóm.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Hủy')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Xóa'))
                ]));
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await dioClient.delete('/v1/expenses/${expense['id']}');
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Không thể xóa khoản chi. Kiểm tra quyền và trạng thái quyết toán.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final parts = expense['participants'] as List? ?? [];
    return Scaffold(
        bottomNavigationBar: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed: _busy ? null : _edit,
                          child: const Text('Chỉnh sửa',
                              style: TextStyle(color: pdfPurple)))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFFECEE),
                              foregroundColor: pdfRed),
                          onPressed: _busy ? null : _delete,
                          child: const Text('Xóa')))
                ]))),
        appBar: AppBar(title: const Text('Chi tiết khoản chi')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const SizedBox(height: 20),
          const Center(
              child: CircleAvatar(
                  radius: 38,
                  backgroundColor: Color(0xFFF0EDFF),
                  child: Text('🍲', style: TextStyle(fontSize: 32)))),
          const SizedBox(height: 18),
          Text(expense['title'] ?? '',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(money(expense['totalAmount'] ?? 0),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w800, color: pdfPurple)),
          const SizedBox(height: 6),
          Text(
              '${expense['categoryName'] ?? 'Khoản chi'} • ${expense['expenseDate'] ?? ''}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: pdfMuted, fontSize: 12)),
          const SizedBox(height: 28),
          Card(
              child: ListTile(
                  leading: PersonBadge(expense['payerName'] ?? ''),
                  title: const Text('Người thanh toán',
                      style: TextStyle(fontSize: 11, color: pdfMuted)),
                  subtitle: Text(
                      '${expense['payerName']} đã trả ${money(expense['totalAmount'] ?? 0)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF202127))))),
          const SizedBox(height: 24),
          Text('CHIA CHO ${parts.length} NGƯỜI',
              style: const TextStyle(
                  color: pdfMuted, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Card(
              child: Column(children: [
            for (final p in parts)
              ListTile(
                  leading: PersonBadge(p['userName'] ?? ''),
                  title: Text(p['userName'] ?? '',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  trailing: Text(money(p['amount'] ?? 0),
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)))
          ])),
          if ((expense['description'] ?? '').toString().isNotEmpty)
            Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(expense['description'])),
        ]));
  }
}
