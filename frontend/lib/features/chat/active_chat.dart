// Trách nhiệm file: Quản lý trạng thái group id của màn hình chat đang mở để các service (push notification) biết và suppress thông báo trùng lặp.

class ActiveChat {
  static int? groupId;
}
