// Trách nhiệm file: Hộp thoại tham gia nhóm qua mã mời hoặc đường dẫn QR theo chuẩn Apple HIG.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/invite_code_parser.dart';
import '../models/group_model.dart';
import '../providers/group_provider.dart';

class JoinGroupDialog extends ConsumerStatefulWidget {
  const JoinGroupDialog({super.key});

  static Future<GroupModel?> show(BuildContext context) {
    return showModalBottomSheet<GroupModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.n100,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const JoinGroupDialog(),
    );
  }

  @override
  ConsumerState<JoinGroupDialog> createState() => _JoinGroupDialogState();
}

class _JoinGroupDialogState extends ConsumerState<JoinGroupDialog> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    HapticFeedback.lightImpact();
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      final parsed = InviteCodeParser.parse(text);
      setState(() {
        _controller.text = parsed;
        _errorMessage = null;
      });
    }
  }

  Future<void> _submitJoin() async {
    final rawInput = _controller.text.trim();
    final inviteCode = InviteCodeParser.parse(rawInput);

    if (inviteCode.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập mã nhóm hoặc dán link mời';
      });
      return;
    }

    final existingGroups = ref.read(userGroupsProvider).valueOrNull ?? [];
    final alreadyInGroup = existingGroups.any(
      (g) =>
          (g.inviteCode != null && g.inviteCode == inviteCode) ||
          g.id == inviteCode,
    );
    if (alreadyInGroup) {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = 'Bạn đã ở trong nhóm này rồi';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final joinedGroup =
          await ref.read(userGroupsProvider.notifier).joinGroup(inviteCode);
      HapticFeedback.mediumImpact();

      if (mounted) {
        Navigator.of(context).pop(joinedGroup);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tham gia nhóm "${joinedGroup.name}" thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e
              .toString()
              .replaceAll('Exception: ', '')
              .replaceAll('DioException [bad response]: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // iOS drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.n300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tham gia nhóm',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.n900,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.n500, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Nhập mã mời hoặc dán đường dẫn/mã quét QR của nhóm để tham gia.',
                style: TextStyle(fontSize: 13, color: AppColors.n600),
              ),
              const SizedBox(height: 18),

              // Input card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.n0,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppDimensions.shadowSm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.link_rounded,
                            color: AppColors.p500, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Mã nhóm hoặc Link mời',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.n700,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: _pasteFromClipboard,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: Row(
                              children: const [
                                Icon(Icons.content_paste_rounded,
                                    size: 14, color: AppColors.p500),
                                SizedBox(width: 4),
                                Text(
                                  'Dán',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.p500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.n900,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'VD: GR-8A9B2C hoặc https://...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: AppColors.n400,
                          fontWeight: FontWeight.normal,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 4),
                      ),
                      onSubmitted: (_) => _submitJoin(),
                    ),
                  ],
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: const TextStyle(fontSize: 12, color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 20),

              // Submit button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.p500,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Vào nhóm ngay',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

