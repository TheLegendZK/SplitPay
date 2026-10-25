class Expense {
  const Expense({
    required this.id,
    required this.groupId,
    required this.name,
    required this.amount,
    required this.memberUid,
    this.type = 'expense',
    this.settlementToUid,
  });

  final String id;
  final String groupId;
  final String name;
  final double amount;
  final String memberUid;
  final String type;
  final String? settlementToUid;

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'name': name,
      'amount': amount,
      'memberUid': memberUid,
      'type': type,
      'settlementToUid': settlementToUid,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map, String docId) {
    return Expense(
      id: docId,
      groupId: map['groupId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      memberUid: map['memberUid'] as String? ?? '',
      type: map['type'] as String? ?? 'expense',
      settlementToUid: map['settlementToUid'] as String?,
    );
  }
}
