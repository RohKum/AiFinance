import 'package:aifin/data/models/budget_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aifin/core/constants/app_constants.dart';
import 'package:aifin/core/providers/transaction_provider.dart';
import 'package:aifin/data/models/transaction_model.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Fetch live transactions
    final transactionsAsync = ref.watch(transactionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Monthly Budget', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          final now = DateTime.now();
          // Filter ONLY expenses for this month
          final monthlyExpenses = transactions.where(
            (t) => t.type == TransactionType.expense && t.date.month == now.month && t.date.year == now.year,
          );
          
          final totalSpent = monthlyExpenses.fold(0.0, (sum, t) => sum + t.amount);
          const double monthlyBudgetObj = 40000.0;
          final double spendPercent = (totalSpent / monthlyBudgetObj).clamp(0.0, 1.0);
          final bool isOverBudget = totalSpent > monthlyBudgetObj;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Global Budget Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5E35B1), Color(0xFF7E57C2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5E35B1).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text('Total Budget vs Spending', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${AppConstants.currencySymbol}${totalSpent.toStringAsFixed(0)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text(' / ${AppConstants.currencySymbol}${monthlyBudgetObj.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white54)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: spendPercent,
                          minHeight: 12,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation(isOverBudget ? Colors.redAccent : Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Category Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _predefinedBudgets.length,
                    itemBuilder: (context, index) {
                      final budget = _predefinedBudgets[index];
                      final categorySpend = monthlyExpenses.where((t) => t.category == budget.categoryName).fold(0.0, (sum, t) => sum + t.amount);
                      final activeBudget = budget.copyWith(currentSpend: categorySpend);
                      return _buildCategoryBudgetCard(activeBudget);
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, s) => Center(child: Text('Error: $err')),
      ),
    );
  }

  List<BudgetModel> get _predefinedBudgets => [
    BudgetModel(id: 'b1', categoryName: 'Food & Dining', monthlyLimit: 15000),
    BudgetModel(id: 'b2', categoryName: 'Transportation', monthlyLimit: 5000),
    BudgetModel(id: 'b3', categoryName: 'Shopping', monthlyLimit: 10000),
    BudgetModel(id: 'b4', categoryName: 'Entertainment', monthlyLimit: 4000),
    BudgetModel(id: 'b5', categoryName: 'Bills & Utilities', monthlyLimit: 6000),
  ];

  Widget _buildCategoryBudgetCard(BudgetModel budget) {
    final double percent = (budget.currentSpend / budget.monthlyLimit).clamp(0.0, 1.0);
    final bool isOver = budget.currentSpend > budget.monthlyLimit;
    final int percentInt = (percent * 100).toInt();

    IconData icon = Icons.category;
    Color color = Colors.grey;
    if (budget.categoryName.contains('Food')) {
      icon = Icons.restaurant;
      color = Colors.orange;
    } else if (budget.categoryName.contains('Transport')) {
      icon = Icons.directions_car;
      color = Colors.blue;
    } else if (budget.categoryName.contains('Shopping')) {
      icon = Icons.shopping_bag;
      color = Colors.pink;
    } else if (budget.categoryName.contains('Entertainment')) {
      icon = Icons.movie;
      color = Colors.purple;
    } else if (budget.categoryName.contains('Bills')) {
      icon = Icons.receipt;
      color = Colors.teal;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Dynamic Icon Avatar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          
          // Spend Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  budget.categoryName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Text(
                  '${AppConstants.currencySymbol}${budget.currentSpend.toStringAsFixed(0)} / ${AppConstants.currencySymbol}${budget.monthlyLimit.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: isOver ? Colors.redAccent : Colors.grey[600],
                    fontSize: 14,
                    fontWeight: isOver ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                if (isOver)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Over budget by ${AppConstants.currencySymbol}${(budget.currentSpend - budget.monthlyLimit).toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          
          // Beautiful Circular Dial
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 55,
                height: 55,
                child: CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 5,
                  backgroundColor: Colors.grey[100],
                  valueColor: AlwaysStoppedAnimation(isOver ? Colors.redAccent : color),
                ),
              ),
              Text(
                '$percentInt%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isOver ? Colors.redAccent : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
