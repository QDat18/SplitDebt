// Trách nhiệm file: Màn hình hiển thị tóm tắt và toàn bộ dữ liệu cá nhân dạng JSON có thể sao chép.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/grouped_list.dart';
import 'privacy_repository.dart';

class DataExportScreen extends StatefulWidget {
  const DataExportScreen({super.key});

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  final _repo = PrivacyRepository();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;
  String _prettyJson = '';

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
      final data = await _repo.exportData();
      const encoder = JsonEncoder.withIndent('  ');
      if (!mounted) return;
      setState(() {
        _data = data;
        _prettyJson = encoder.convert(data);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  int _countList(String key) {
    final val = _data?[key];
    return val is List ? val.length : 0;
  }

  Future<void> _copyJson() async {
    if (_prettyJson.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _prettyJson));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép dữ liệu JSON.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.n50,
      appBar: AppBar(
        title: const Text('Dữ liệu của tôi'),
        backgroundColor: AppColors.n50,
        actions: [
          if (_prettyJson.isNotEmpty)
            TextButton(
              onPressed: _copyJson,
              child: const Text('Sao chép'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.s16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: textTheme.bodyMedium),
                        const SizedBox(height: AppDimensions.s12),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.s16,
                  ),
                  children: [
                    GroupedSection(
                      header: 'TÓM TẮT DỮ LIỆU',
                      children: [
                        GroupedTile(
                          title: 'Nhóm đã tham gia',
                          value: '${_countList('groups')}',
                        ),
                        GroupedTile(
                          title: 'Khoản chi liên quan',
                          value: '${_countList('expenses')}',
                        ),
                        GroupedTile(
                          title: 'Thanh toán công nợ',
                          value: '${_countList('settlements')}',
                        ),
                        GroupedTile(
                          title: 'Tin nhắn đã gửi',
                          value: '${_countList('messages')}',
                        ),
                        GroupedTile(
                          title: 'Thông báo',
                          value: '${_countList('notifications')}',
                        ),
                        GroupedTile(
                          title: 'Lịch sử đồng ý',
                          value: '${_countList('consents')}',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.s20),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.s16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'DỮ LIỆU JSON',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.n600,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.s8),
                          Container(
                            padding: const EdgeInsets.all(AppDimensions.s16),
                            decoration: BoxDecoration(
                              color: AppColors.n0,
                              borderRadius: AppDimensions.radius12,
                            ),
                            child: SelectableText(
                              _prettyJson,
                              style: textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                                color: AppColors.n900,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppDimensions.s12),
                          Text(
                            'Yêu cầu khác về dữ liệu, liên hệ [CẦN ĐIỀN: email liên hệ]',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.n600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

