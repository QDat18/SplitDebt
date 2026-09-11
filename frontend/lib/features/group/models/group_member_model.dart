class GroupMemberModel {
  final String id;
  final String groupId;
  final String userId;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String role;
  final DateTime? joinedAt;

  GroupMemberModel({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    required this.role,
    this.joinedAt,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      id: json['id'] as String? ?? '',
      groupId: json['groupId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? 'Thành viên',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String? ?? 'MEMBER',
      joinedAt:
          json['joinedAt'] != null
              ? DateTime.tryParse(json['joinedAt'].toString())
              : null,
    );
  }

  bool get isOwner => role == 'OWNER';
  bool get isAdmin => role == 'ADMIN';
}
