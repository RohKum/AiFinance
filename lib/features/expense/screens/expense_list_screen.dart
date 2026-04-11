import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aifin/core/constants/app_constants.dart';
import 'package:aifin/core/providers/transaction_provider.dart';
import 'package:aifin/data/models/transaction_model.dart';

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'This Week', 'This Month', 'Oldest First'];

  @override
  Widget build(BuildContext context) {
    final transactionsAsyncValue = ref.watch(transactionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Transaction History', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(filter, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
                    selected: isSelected,
                    onSelected: (s) => setState(() => _selectedFilter = filter),
                    selectedColor: Colors.deepPurpleAccent,
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: transactionsAsyncValue.when(
              data: (transactions) {
                // Apply Filters
                List<TransactionModel> filteredTransactions = List.from(transactions);
                final now = DateTime.now();
                
                if (_selectedFilter == 'This Week') {
                  final oneWeekAgo = now.subtract(const Duration(days: 7));
                  filteredTransactions = filteredTransactions.where((e) => e.date.isAfter(oneWeekAgo)).toList();
                } else if (_selectedFilter == 'This Month') {
                  filteredTransactions = filteredTransactions.where((e) => e.date.month == now.month && e.date.year == now.year).toList();
                } else if (_selectedFilter == 'Oldest First') {
                  filteredTransactions.sort((a, b) => a.date.compareTo(b.date));
                } else { 
                  // Default newest first
                  filteredTransactions.sort((a, b) => b.date.compareTo(a.date));
                }

                if (filteredTransactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('No transactions found.', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final t = filteredTransactions[index];
                    return _buildTransactionTile(context, ref, t);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, s) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, WidgetRef ref, TransactionModel transaction) {
    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      onDismissed: (_) {
         // Optimistically delete
         final notifier = ref.read(transactionProvider.notifier);
         notifier.deleteTransaction(transaction.id);
         
         // Provide Undo feedback
         ScaffoldMessenger.of(context).clearSnackBars();
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('${transaction.title} deleted.'),
             behavior: SnackBarBehavior.floating,
             action: SnackBarAction(
               label: 'UNDO',
               onPressed: () => notifier.addTransaction(transaction),
             ),
           ),
         );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: transaction.isIncome ? Colors.green.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                transaction.isIncome ? Icons.keyboard_double_arrow_down : Icons.keyboard_double_arrow_up, 
                color: transaction.isIncome ? Colors.green : Colors.redAccent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${transaction.category} • ${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Text(
              '${transaction.isIncome ? "+" : "-"}${AppConstants.currencySymbol}${transaction.amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: transaction.isIncome ? Colors.green : Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
