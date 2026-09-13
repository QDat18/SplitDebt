class GroupModel {
  final String id;
  final String name;
  final String? description;
  final String? createdById;
  final String? createdByName;
  final String currentUserRole; // OWNER, ADMIN, MEMBER
  final int memberCount;
  final double? userBalance;
  final String? formattedBalance;
  final String? timeAgo;
  final String? categoryIcon;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GroupModel({
    required this.id,
    required this.name,
    this.description,
    this.createdById,
    this.createdByName,
    required this.currentUserRole,
    required this.memberCount,
    this.userBalance,
    this.formattedBalance,
    this.timeAgo,
    this.categoryIcon,
    this.createdAt,
    this.updatedAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'].toString(),
      name: json['name'] as String? ?? 'N/A',
      description: json['description'] as String?,
      createdById: json['createdById']?.toString(),
      createdByName: json['createdByName'] as String?,
      currentUserRole: json['currentUserRole'] as String? ?? 'MEMBER',
      memberCount: json['memberCount'] as int? ?? 1,
      userBalance: (json['userBalance'] as num?)?.toDouble(),
      formattedBalance: json['formattedBalance'] as String?,
      timeAgo: json['timeAgo'] as String?,
      categoryIcon: json['categoryIcon'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdById': createdById,
      'createdByName': createdByName,
      'currentUserRole': currentUserRole,
      'memberCount': memberCount,
      'userBalance': userBalance,
      'formattedBalance': formattedBalance,
      'timeAgo': timeAgo,
      'categoryIcon': categoryIcon,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  bool get isOwner => currentUserRole == 'OWNER';
  bool get isAdminOrOwner =>
      currentUserRole == 'OWNER' || currentUserRole == 'ADMIN';
}
