// Trách nhiệm file: Quy tắc quyết định khi nào hiển thị lời nhắc xin quyền thông báo.

bool shouldPromptNotifications({
  required int count,
  required DateTime? last,
  required DateTime now,
}) {
  if (count >= 2) return false;
  if (count == 0 || last == null) return true;
  return !now.isBefore(last.add(const Duration(days: 7)));
}

