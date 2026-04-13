import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aifin/core/constants/app_constants.dart';
import 'package:aifin/core/providers/transaction_provider.dart';
import 'package:aifin/data/models/transaction_model.dart';
import 'package:aifin/core/providers/user_provider.dart';
import 'package:intl/intl.dart';

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  String _timePeriod = 'All';
  String _typeFilter = 'All';
  String _searchQuery = '';
  bool _showSearch = false;
  final _searchController = TextEditingController();

  final List<String> _timePeriods = ['All', 'Weekly', 'Monthly', 'Yearly'];
  final List<String> _typeFilters = ['All', 'Income', 'Expense'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TransactionModel> _applyFilters(
    List<TransactionModel> all,
    DateTime cycleStart,
  ) {
    final now = DateTime.now();
    List<TransactionModel> result = List.from(all);

    // Time filter
    if (_timePeriod == 'Weekly') {
      final from = now.subtract(const Duration(days: 7));
      result = result.where((t) => t.date.isAfter(from)).toList();
    } else if (_timePeriod == 'Monthly') {
      result = result
          .where((t) => t.date.year == now.year && t.date.month == now.month)
          .toList();
    } else if (_timePeriod == 'Yearly') {
      result = result.where((t) => t.date.year == now.year).toList();
    }

    // Type filter
    if (_typeFilter == 'Income') {
      result = result.where((t) => t.isIncome).toList();
    } else if (_typeFilter == 'Expense') {
      result = result.where((t) => !t.isIncome).toList();
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where(
            (t) =>
                t.title.toLowerCase().contains(q) ||
                t.category.toLowerCase().contains(q),
          )
          .toList();
    }

    // Sort newest first
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  /// Groups transactions by their date label (Today / Yesterday / formatted date)
  Map<String, List<TransactionModel>> _groupByDate(
    List<TransactionModel> transactions,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final groups = <String, List<TransactionModel>>{};

    for (final t in transactions) {
      final tDay = DateTime(t.date.year, t.date.month, t.date.day);
      String label;
      if (tDay == today) {
        label = 'Today';
      } else if (tDay == yesterday) {
        label = 'Yesterday';
      } else {
        label = DateFormat('EEE, d MMM yyyy').format(t.date);
      }
      groups.putIfAbsent(label, () => []).add(t);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactionsAsync = ref.watch(transactionProvider);
    final user = ref.watch(userProvider);
    final currencySymbol =
        user?.preferences['currency'] ?? AppConstants.currencySymbol;

    // Cycle start for monthly filter
    final now = DateTime.now();
    final cycleStartDay =
        int.tryParse(user?.preferences['cycleStartDate']?.toString() ?? '1') ??
        1;
    final cycleStart = now.day >= cycleStartDay
        ? DateTime(now.year, now.month, cycleStartDay)
        : DateTime(
            now.month == 1 ? now.year - 1 : now.year,
            now.month == 1 ? 12 : now.month - 1,
            cycleStartDay,
          );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search transactions...',
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : const Text(
                'Transactions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (all) {
          final filtered = _applyFilters(all, cycleStart);
          final totalIncome = filtered
              .where((t) => t.isIncome)
              .fold(0.0, (s, t) => s + t.amount);
          final totalExpense = filtered
              .where((t) => !t.isIncome)
              .fold(0.0, (s, t) => s + t.amount);
          final net = totalIncome - totalExpense;
          final grouped = _groupByDate(filtered);

          return Column(
            children: [
              // ── Filter Row ──────────────────────────────────────────
              _buildFilterSection(theme),

              // ── Summary Bar ─────────────────────────────────────────
              if (filtered.isNotEmpty)
                _buildSummaryBar(
                  context,
                  currencySymbol,
                  totalIncome,
                  totalExpense,
                  net,
                ),

              // ── Transaction List ─────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: grouped.entries
                            .expand(
                              (e) => [
                                null, // date header
                                ...e.value,
                              ],
                            )
                            .length,
                        itemBuilder: (context, index) {
                          final flatList = grouped.entries
                              .expand((e) => <dynamic>[e.key, ...e.value])
                              .toList();
                          final item = flatList[index];
                          if (item is String) {
                            return _buildDateHeader(item, context);
                          }
                          return _buildTransactionTile(
                            context,
                            item as TransactionModel,
                            currencySymbol,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        children: [
          // Time Period chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _timePeriods.map((p) {
                final isSelected = _timePeriod == p;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _timePeriod = p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            // ignore: deprecated_member_use
                            : theme.colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        p,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Type filter
          Row(
            children: _typeFilters.map((t) {
              final isSelected = _typeFilter == t;
              Color accent = Colors.grey;
              if (t == 'Income') accent = Colors.green;
              if (t == 'Expense') accent = Colors.redAccent;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _typeFilter = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          // ignore: deprecated_member_use
                          ? accent.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        // ignore: deprecated_member_use
                        color: isSelected
                            ? accent
                            // ignore: deprecated_member_use
                            : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      t,
                      style: TextStyle(
                        color: isSelected ? accent : Colors.grey,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(
    BuildContext context,
    String currencySymbol,
    double income,
    double expense,
    double net,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryItem(
            'Income',
            '+$currencySymbol${income.toStringAsFixed(0)}',
            Colors.green,
          ),
          Container(width: 1, height: 30, color: Colors.grey.withOpacity(0.2)),
          _buildSummaryItem(
            'Expense',
            '-$currencySymbol${expense.toStringAsFixed(0)}',
            Colors.redAccent,
          ),
          Container(width: 1, height: 30, color: Colors.grey.withOpacity(0.2)),
          _buildSummaryItem(
            'Net',
            '${net >= 0 ? '+' : ''}$currencySymbol${net.toStringAsFixed(0)}',
            net >= 0 ? Colors.green : Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDateHeader(String label, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.grey[500],
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 72,
            color: Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No transactions found',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try changing filters or adding a transaction.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    TransactionModel t,
    String currencySymbol,
  ) {
    final isIncome = t.isIncome;
    final color = isIncome ? Colors.green : Colors.redAccent;

    return Dismissible(
      key: Key(t.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
      ),
      onDismissed: (_) {
        final notifier = ref.read(transactionProvider.notifier);
        notifier.deleteTransaction(t.id);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t.title} deleted.'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () => notifier.addTransaction(t),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIncome
                    ? Icons.keyboard_double_arrow_down
                    : Icons.keyboard_double_arrow_up,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            // Title + category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          t.category,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('hh:mm a').format(t.date),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Amount
            Text(
              '${isIncome ? '+' : '-'}$currencySymbol${t.amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
