enum TransactionType { sent, received }

class UserTransaction {
  final String id;
  final TransactionType type;
  final double amountBtc; // Storing as BTC for simplicity in this mock
  final DateTime date;
  final bool isNew; // For animation

  UserTransaction({
    required this.id,
    required this.type,
    required this.amountBtc,
    required this.date,
    this.isNew = false,
  });
}
