import 'transaction.dart';

class AppUser {
  final String name;
  final String email;
  final String password;
  final String accountNumber;
  final double balance;
  final List<Transaction> transactions;
  final List<String> generatedQrCodes;

  AppUser({
    required this.name,
    required this.email,
    required this.password,
    required this.accountNumber,
    this.balance = 0.0,
    this.transactions = const [],
    this.generatedQrCodes = const [],
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      name: json['name'],
      email: json['email'],
      password: json['password'],
      accountNumber: json['accountNumber'],
      balance: json['balance'],
      transactions: (json['transactions'] as List)
          .map((tx) => Transaction.fromJson(tx))
          .toList(),
      generatedQrCodes: List<String>.from(json['generatedQrCodes'] ?? []),
    );
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? password,
    double? balance,
    List<Transaction>? transactions,
    List<String>? generatedQrCodes,
  }) {
    return AppUser(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      accountNumber: accountNumber,
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
      generatedQrCodes: generatedQrCodes ?? this.generatedQrCodes,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'password': password,
        'accountNumber': accountNumber,
        'balance': balance,
        'transactions': transactions.map((tx) => tx.toJson()).toList(),
        'generatedQrCodes': generatedQrCodes,
      };
}
