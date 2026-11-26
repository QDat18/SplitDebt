// Trách nhiệm file: Model chi tiết từng món trong chế độ chia theo món.

class ExpenseItemDetail {
  String id;
  String name;
  double price;
  List<String> assignedMemberIds;

  ExpenseItemDetail({
    required this.id,
    required this.name,
    required this.price,
    required this.assignedMemberIds,
  });
}
