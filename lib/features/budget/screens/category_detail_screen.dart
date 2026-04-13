import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aifin/core/providers/transaction_provider.dart';
import 'package:aifin/data/models/transaction_model.dart';
import 'package:intl/intl.dart';

class CategoryDetailScreen extends ConsumerWidget {
  final String categoryName;
  final IconData icon;
  final Color color;
  final double monthlyLimit;
  final double currentSpend;
  final String currencySymbol;
  final DateTime cycleStart;
  final DateTime cycleEnd;

  const CategoryDetailScreen({
    super.key,
    required this.categoryName,
    required this.icon,
    required this.color,
    required this.monthlyLimit,
    required this.currentSpend,
    required this.currencySymbol,
    required this.cycleStart,
    required this.cycleEnd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionProvider);
    final theme = Theme.of(context);
    final spendPercent = monthlyLimit > 0
        ? (currentSpend / monthlyLimit).clamp(0.0, 1.0)
        : 0.0;
    final isOver = currentSpend > monthlyLimit;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Animated SliverAppBar ────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: color,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 56, bottom: 16, right: 16),
              title: Row(
                children: [
                  // Hero animated icon
                  Hero(
                    tag: 'category_icon_$categoryName',
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      categoryName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color,
                      // ignore: deprecated_member_use
                      color.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 32),
                      // ignore: deprecated_member_use
                      Icon(icon, color: Colors.white.withOpacity(0.15),
                          size: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Budget Summary Card ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  Row(
                    children: [
                      _statCard(
                        context,
                        'Spent',
                        '$currencySymbol${currentSpend.toStringAsFixed(0)}',
                        isOver ? Colors.redAccent : color,
                      ),
                      const SizedBox(width: 12),
                      _statCard(
                        context,
                        'Budget',
                        '$currencySymbol${monthlyLimit.toStringAsFixed(0)}',
                        Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      _statCard(
                        context,
                        isOver ? 'Over By' : 'Remaining',
                        '$currencySymbol${(monthlyLimit - currentSpend).abs().toStringAsFixed(0)}',
                        isOver ? Colors.redAccent : Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: spendPercent),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (_, value, __) => LinearProgressIndicator(
                        value: value,
                        minHeight: 10,
                        // ignore: deprecated_member_use
                        backgroundColor: color.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation(
                            isOver ? Colors.redAccent : color),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${(spendPercent * 100).toInt()}% of budget used  ·  '
                      '${DateFormat('MMM d').format(cycleStart)} – ${DateFormat('MMM d').format(cycleEnd)}',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12),
                    ),
                  ),

                  const SizedBox(height: 28),
                  const Text(
                    'Transactions',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // ── Transaction List ─────────────────────────────────────────────
          transactionsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $err')),
            ),
            data: (all) {
              final filtered = all
                  .where((t) =>
                      t.category == categoryName &&
                      t.type == TransactionType.expense &&
                      (t.date.isAfter(cycleStart) ||
                          t.date.isAtSameMomentAs(cycleStart)) &&
                      t.date.isBefore(cycleEnd))
                  .toList()
                ..sort((a, b) => b.date.compareTo(a.date));

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmpty(context),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildTile(
                      context, filtered[index], currencySymbol, color),
                  childCount: filtered.length,
                ),
              );
            },
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }

  // ── Stat Card ──────────────────────────────────────────────────────────────
  Widget _statCard(
      BuildContext context, String label, String value, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.grey.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: valueColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }

  // ── Transaction Tile ───────────────────────────────────────────────────────
  Widget _buildTile(BuildContext context, TransactionModel t,
      String cs, Color catColor) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: catColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: catColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color:
                          Theme.of(context).textTheme.bodyLarge?.color),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('EEE, d MMM · hh:mm a').format(t.date),
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '-$cs${t.amount.toStringAsFixed(0)}',
            style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────
  Widget _buildEmpty(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon,
            size: 60,
            // ignore: deprecated_member_use
            color: color.withOpacity(0.2)),
        const SizedBox(height: 16),
        Text(
          'No transactions in $categoryName',
          style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        const Text(
          'Expenses logged in this category\nwill appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ],
    );
  }
}
