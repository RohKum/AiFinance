class BudgetModel {
  final String id;
  final String categoryName;
  final double monthlyLimit;
  final double currentSpend; // Usually calculated at runtime

  BudgetModel({
    required this.id,
    required this.categoryName,
    required this.monthlyLimit,
    this.currentSpend = 0.0, // Default to 0
  });

  BudgetModel copyWith({
    String? id,
    String? categoryName,
    double? monthlyLimit,
    double? currentSpend,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      categoryName: categoryName ?? this.categoryName,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      currentSpend: currentSpend ?? this.currentSpend,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryName': categoryName,
      'monthlyLimit': monthlyLimit,
      // We generally don't store currentSpend in a DB if it's calculated live 
      // from expenses, but we can serialize it for API transport.
      'currentSpend': currentSpend,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] ?? '',
      categoryName: map['categoryName'] ?? '',
      monthlyLimit: map['monthlyLimit']?.toDouble() ?? 0.0,
      currentSpend: map['currentSpend']?.toDouble() ?? 0.0,
    );
  }
}
