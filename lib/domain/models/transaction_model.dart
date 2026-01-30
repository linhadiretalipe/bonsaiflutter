enum TransactionType { sent, received }

class UserTransaction {
  final String id;
  final TransactionType type;
  final double amountBtc; // Storing as BTC for simplicity
  final DateTime date;
  final bool isNew; // For animation
  final bool isConfirmed;
  final int? confirmationHeight;

  UserTransaction({
    required this.id,
    required this.type,
    required this.amountBtc,
    required this.date,
    this.isNew = false,
    this.isConfirmed = false,
    this.confirmationHeight,
  });
}
