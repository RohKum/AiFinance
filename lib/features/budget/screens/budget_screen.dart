import 'package:aifin/data/models/budget_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aifin/core/constants/app_constants.dart';
import 'package:aifin/core/providers/transaction_provider.dart';
import 'package:aifin/data/models/transaction_model.dart';
import 'package:aifin/core/providers/user_provider.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Fetch live transactions
    final transactionsAsync = ref.watch(transactionProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Monthly Budget', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          final now = DateTime.now();
          final user = ref.watch(userProvider);
          
          // Determine custom Financial Cycle boundaries
          final cycleStartDay = int.tryParse(user?.preferences['cycleStartDate']?.toString() ?? '1') ?? 1;
          DateTime cycleStart;
          DateTime cycleEnd;
          
          if (now.day >= cycleStartDay) {
            cycleStart = DateTime(now.year, now.month, cycleStartDay);
            final nextMonth = now.month == 12 ? 1 : now.month + 1;
            final nextYear = now.month == 12 ? now.year + 1 : now.year;
            cycleEnd = DateTime(nextYear, nextMonth, cycleStartDay);
          } else {
            final prevMonth = now.month == 1 ? 12 : now.month - 1;
            final prevYear = now.month == 1 ? now.year - 1 : now.year;
            cycleStart = DateTime(prevYear, prevMonth, cycleStartDay);
            cycleEnd = DateTime(now.year, now.month, cycleStartDay);
          }

          // Filter ONLY expenses for this active custom cycle
          final monthlyExpenses = transactions.where((t) {
            if (t.type != TransactionType.expense) return false;
            final isSameOrAfter = t.date.isAfter(cycleStart) || t.date.isAtSameMomentAs(cycleStart);
            final isBefore = t.date.isBefore(cycleEnd);
            return isSameOrAfter && isBefore;
          });
          
          // Extract active user preferences
          final val = user?.preferences['monthlyBudget'];
          final double monthlyBudgetObj = (val != null) ? double.tryParse(val.toString()) ?? 40000.0 : 40000.0;
          
          final totalSpent = monthlyExpenses.fold(0.0, (sum, t) => sum + t.amount);
          final double spendPercent = monthlyBudgetObj > 0 ? (totalSpent / monthlyBudgetObj).clamp(0.0, 1.0) : 0.0;
          final bool isOverBudget = totalSpent > monthlyBudgetObj && monthlyBudgetObj > 0;

          final currencySymbol = user?.preferences['currency'] ?? AppConstants.currencySymbol;
          
          final expenseCategories = user?.customCategories.where((c) => c['type'] == 'expense') ?? [];
          final List<BudgetModel> dynamicBudgets = expenseCategories.map((c) => BudgetModel(
            id: c['name'], 
            categoryName: c['name'], 
            monthlyLimit: double.tryParse(c['limit'].toString()) ?? 5000.0,
          )).toList();

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Global Budget Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
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
                          Text('$currencySymbol${totalSpent.toStringAsFixed(0)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text(' / $currencySymbol${monthlyBudgetObj.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white54)),
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
                    itemCount: dynamicBudgets.length,
                    itemBuilder: (context, index) {
                      final budget = dynamicBudgets[index];
                      final categorySpend = monthlyExpenses.where((t) => t.category == budget.categoryName).fold(0.0, (sum, t) => sum + t.amount);
                      final activeBudget = budget.copyWith(currentSpend: categorySpend);
                      return _buildCategoryBudgetCard(context, activeBudget, currencySymbol);
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

  // No predefinedBudgets anymore! Fully Dynamic.

  Widget _buildCategoryBudgetCard(BuildContext context, BudgetModel budget, String currencySymbol) {
    final double percent = budget.monthlyLimit > 0 ? (budget.currentSpend / budget.monthlyLimit).clamp(0.0, 1.0) : 0.0;
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
        color: Theme.of(context).cardColor,
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
                const SizedBox(height: 6),
                Text(
                  '$currencySymbol${budget.currentSpend.toStringAsFixed(0)} / $currencySymbol${budget.monthlyLimit.toStringAsFixed(0)}',
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
                      'Over budget by $currencySymbol${(budget.currentSpend - budget.monthlyLimit).toStringAsFixed(0)}',
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
                  color: isOver ? Colors.redAccent : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
