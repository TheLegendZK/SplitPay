class Settlement {
  const Settlement({
    required this.debtorUid,
    required this.creditorUid,
    required this.amount,
  });

  final String debtorUid;

  final String creditorUid;

  final double amount;
}
