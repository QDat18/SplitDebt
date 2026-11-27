// Trách nhiệm file: Hợp nhất trạng thái đã đọc đang chờ (pending reads) với dữ liệu mới tải về từ máy chủ.

List<Map<String, dynamic>> applyPendingReads(
  List<Map<String, dynamic>> fetched,
  Set<Object> pendingReadIds,
) {
  return fetched.map((item) {
    final copy = Map<String, dynamic>.from(item);
    if (pendingReadIds.contains(copy['id'])) {
      copy['isRead'] = true;
    }
    return copy;
  }).toList();
}

List<Map<String, dynamic>> markUnread(
  List<Map<String, dynamic>> items,
  Object id,
) {
  return items.map((item) {
    final copy = Map<String, dynamic>.from(item);
    if (copy['id'] == id) {
      copy['isRead'] = false;
    }
    return copy;
  }).toList();
}
