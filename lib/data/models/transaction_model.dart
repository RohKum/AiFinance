enum TransactionType { income, expense }

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final TransactionType type;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.type = TransactionType.expense,
  });

  bool get isIncome => type == TransactionType.income;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'type': type.name,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      category: map['category'] ?? '',
      date: DateTime.parse(map['date']),
      type: TransactionType.values.byName(map['type'] ?? 'expense'),
    );
  }
}
