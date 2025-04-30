class Transaction {
  final String id;
  final String type; // 'incoming' or 'outgoing'
  final double amount;
  final String counterpart; // e.g., receiver/sender name or account number
  final DateTime timestamp;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.counterpart,
    required this.timestamp,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      type: json['type'],
      amount: json['amount'],
      counterpart: json['counterpart'],
      timestamp: DateTime.parse(json['timestamp']).toLocal(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'amount': amount,
        'counterpart': counterpart,
        'timestamp': timestamp.toLocal().toIso8601String(),
      };
}
