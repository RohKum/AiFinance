import 'dart:math' as math;
import 'package:aifin/data/models/budget_model.dart';
import 'package:aifin/features/budget/screens/category_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aifin/core/constants/app_constants.dart';
import 'package:aifin/core/providers/transaction_provider.dart';
import 'package:aifin/data/models/transaction_model.dart';
import 'package:aifin/core/providers/user_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// ── Category Metadata ─────────────────────────────────────────────────────────
class _CatMeta {
  final IconData icon;
  final Color color;
  const _CatMeta(this.icon, this.color);
}

_CatMeta _getMeta(String name) {
  final n = name.toLowerCase();
  if (n.contains('food') || n.contains('dining') || n.contains('restaurant')) {
    return const _CatMeta(Icons.restaurant, Color(0xFFFF8C42));
  }
  if (n.contains('transport') || n.contains('travel') || n.contains('car')) {
    return const _CatMeta(Icons.directions_car, Color(0xFF2196F3));
  }
  if (n.contains('shopping') || n.contains('clothes')) {
    return const _CatMeta(Icons.shopping_bag, Color(0xFFE91E63));
  }
  if (n.contains('entertainment') || n.contains('movie')) {
    return const _CatMeta(Icons.movie, Color(0xFF9C27B0));
  }
  if (n.contains('bills') || n.contains('utilities')) {
    return const _CatMeta(Icons.receipt, Color(0xFF00BCD4));
  }
  if (n.contains('health') || n.contains('medical')) {
    return const _CatMeta(Icons.favorite, Color(0xFFFF5252));
  }
  if (n.contains('groceries') || n.contains('grocery')) {
    return const _CatMeta(Icons.local_grocery_store, Color(0xFF4CAF50));
  }
  if (n.contains('education') || n.contains('school')) {
    return const _CatMeta(Icons.school, Color(0xFF3F51B5));
  }
  if (n.contains('rent') || n.contains('house') || n.contains('home')) {
    return const _CatMeta(Icons.home, Color(0xFF8BC34A));
  }
  return const _CatMeta(Icons.category, Color(0xFF78909C));
}

const List<Color> _palette = [
  Color(0xFF6C63FF),
  Color(0xFF4CAF50),
  Color(0xFFFF5722),
  Color(0xFF2196F3),
  Color(0xFFFF9800),
  Color(0xFF9C27B0),
  Color(0xFF00BCD4),
  Color(0xFFE91E63),
  Color(0xFF8BC34A),
  Color(0xFF607D8B),
];

// ── Enriched Budget Data Class ────────────────────────────────────────────────
class _EnrichedBudget {
  final BudgetModel budget;
  final double prevCycleSpend;
  final double cycleProgress;
  final _CatMeta meta;
  final Color chartColor;

  const _EnrichedBudget({
    required this.budget,
    required this.prevCycleSpend,
    required this.cycleProgress,
    required this.meta,
    required this.chartColor,
  });

  double get spendPercent => budget.monthlyLimit > 0
      ? (budget.currentSpend / budget.monthlyLimit).clamp(0.0, 1.0)
      : 0.0;

  double get expectedSpend => budget.monthlyLimit * cycleProgress;

  double get paceRatio =>
      expectedSpend > 0 ? budget.currentSpend / expectedSpend : 0;

  bool get isPacingOver => paceRatio > 1.3 && budget.currentSpend > 0;

  bool get isOver => budget.currentSpend > budget.monthlyLimit;

  bool get isOnTrack => !isOver && !isPacingOver;

  double get projectedSpend => cycleProgress > 0.05
      ? (budget.currentSpend / cycleProgress)
      : budget.currentSpend;

  double? get momChangePercent => prevCycleSpend > 0
      ? ((budget.currentSpend - prevCycleSpend) / prevCycleSpend * 100)
      : null;
}

// ── Budget Screen ─────────────────────────────────────────────────────────────
class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  int _cycleOffset = 0;
  int _touchedDonutIndex = -1;

  // Safely shift a date by N months
  DateTime _addMonths(DateTime date, int months) {
    int month = date.month + months;
    int year = date.year;
    while (month <= 0) {
      month += 12;
      year--;
    }
    while (month > 12) {
      month -= 12;
      year++;
    }
    final maxDay = DateUtils.getDaysInMonth(year, month);
    return DateTime(year, month, math.min(date.day, maxDay));
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Monthly Budget',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: transactionsAsync.when(
        data: (transactions) => _buildContent(context, transactions),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<TransactionModel> allTransactions,
  ) {
    final now = DateTime.now();
    final user = ref.watch(userProvider);
    final currencySymbol =
        user?.preferences['currency'] ?? AppConstants.currencySymbol;

    // ── Cycle boundaries ──────────────────────────────────────────────────────
    final cycleStartDay =
        int.tryParse(user?.preferences['cycleStartDate']?.toString() ?? '1') ??
        1;

    DateTime baseCycleStart;
    if (now.day >= cycleStartDay) {
      baseCycleStart = DateTime(now.year, now.month, cycleStartDay);
    } else {
      baseCycleStart = _addMonths(
        DateTime(now.year, now.month, cycleStartDay),
        -1,
      );
    }
    final baseCycleEnd = _addMonths(baseCycleStart, 1);

    final cycleStart = _addMonths(baseCycleStart, _cycleOffset);
    final cycleEnd = _addMonths(baseCycleEnd, _cycleOffset);
    final prevCycleStart = _addMonths(cycleStart, -1);
    final prevCycleEnd = cycleStart;

    // ── Cycle progress ────────────────────────────────────────────────────────
    final totalCycleDays = cycleEnd.difference(cycleStart).inDays;
    final isCurrentCycle = _cycleOffset == 0;

    final double cycleProgress;
    final int daysRemaining;

    if (isCurrentCycle) {
      final daysElapsed = now.difference(cycleStart).inDays;
      cycleProgress = totalCycleDays > 0
          ? (daysElapsed / totalCycleDays).clamp(0.0, 1.0)
          : 0.0;
      daysRemaining = cycleEnd.difference(now).inDays.clamp(1, totalCycleDays);
    } else {
      cycleProgress = 1.0;
      daysRemaining = 0;
    }

    // ── Filter helpers ────────────────────────────────────────────────────────
    List<TransactionModel> filterCycle(DateTime start, DateTime end) =>
        allTransactions.where((t) {
          if (t.type != TransactionType.expense) return false;
          return (t.date.isAfter(start) || t.date.isAtSameMomentAs(start)) &&
              t.date.isBefore(end);
        }).toList();

    final monthlyExpenses = filterCycle(cycleStart, cycleEnd);
    final prevExpenses = filterCycle(prevCycleStart, prevCycleEnd);

    // ── Global budget totals ──────────────────────────────────────────────────
    final val = user?.preferences['monthlyBudget'];
    final double monthlyBudget = val != null
        ? double.tryParse(val.toString()) ?? 40000.0
        : 40000.0;
    final totalSpent = monthlyExpenses.fold(0.0, (s, t) => s + t.amount);
    final spendPercent = monthlyBudget > 0
        ? (totalSpent / monthlyBudget).clamp(0.0, 1.0)
        : 0.0;
    final isOverBudget = totalSpent > monthlyBudget && monthlyBudget > 0;
    final remaining = monthlyBudget - totalSpent;
    final safePerDay = (remaining > 0 && daysRemaining > 0)
        ? remaining / daysRemaining
        : 0.0;

    // ── Enrich category budgets ───────────────────────────────────────────────
    final expenseCategories =
        user?.customCategories.where((c) => c['type'] == 'expense') ?? [];
    final List<_EnrichedBudget> enriched = expenseCategories
        .toList()
        .asMap()
        .entries
        .map((entry) {
          final i = entry.key;
          final c = entry.value;
          final name = c['name'] as String;
          final limit = double.tryParse(c['limit'].toString()) ?? 5000.0;
          final spend = monthlyExpenses
              .where((t) => t.category == name)
              .fold(0.0, (s, t) => s + t.amount);
          final prevSpend = prevExpenses
              .where((t) => t.category == name)
              .fold(0.0, (s, t) => s + t.amount);
          final model = BudgetModel(
            id: name,
            categoryName: name,
            monthlyLimit: limit,
          ).copyWith(currentSpend: spend);
          return _EnrichedBudget(
            budget: model,
            prevCycleSpend: prevSpend,
            cycleProgress: cycleProgress,
            meta: _getMeta(name),
            chartColor: _palette[i % _palette.length],
          );
        })
        .toList();

    // ── Summary stats ─────────────────────────────────────────────────────────
    final onTrackCount = enriched.where((e) => e.isOnTrack).length;
    final pacingCount = enriched
        .where((e) => e.isPacingOver && !e.isOver)
        .length;
    final exceededCount = enriched.where((e) => e.isOver).length;
    final allOnTrack =
        enriched.isNotEmpty && exceededCount == 0 && pacingCount == 0;

    // ── Top alert ─────────────────────────────────────────────────────────────
    _EnrichedBudget? topAlert;
    if (!allOnTrack && enriched.isNotEmpty) {
      final problematic = enriched.where((e) => !e.isOnTrack).toList()
        ..sort((a, b) => b.spendPercent.compareTo(a.spendPercent));
      if (problematic.isNotEmpty) topAlert = problematic.first;
    }

    final donutData = enriched.where((e) => e.budget.currentSpend > 0).toList();

    // ── Registration date cap ─────────────────────────────────────────────────
    final registrationDate = user?.createdAt ?? DateTime.now();
    // Find which cycle the registration date falls in
    final regCycleStart = registrationDate.day >= cycleStartDay
        ? DateTime(registrationDate.year, registrationDate.month, cycleStartDay)
        : _addMonths(
            DateTime(
              registrationDate.year,
              registrationDate.month,
              cycleStartDay,
            ),
            -1,
          );
    // Minimum offset = negative months between regCycleStart and baseCycleStart
    final minOffset =
        -((baseCycleStart.year - regCycleStart.year) * 12 +
            (baseCycleStart.month - regCycleStart.month));

    // ── Build ─────────────────────────────────────────────────────────────────
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        _buildCycleSwitcher(context, cycleStart, cycleEnd, minOffset),
        const SizedBox(height: 12),
        _buildGlobalCard(
          context,
          currencySymbol,
          totalSpent,
          monthlyBudget,
          spendPercent,
          isOverBudget,
          cycleProgress,
          daysRemaining,
          isCurrentCycle,
        ),
        const SizedBox(height: 16),
        if (isCurrentCycle) ...[
          _buildSafeToSpend(context, safePerDay, currencySymbol, isOverBudget),
          const SizedBox(height: 16),
        ],
        if (enriched.isNotEmpty) ...[
          _buildSummaryStats(context, onTrackCount, pacingCount, exceededCount),
          const SizedBox(height: 16),
        ],
        if (topAlert != null) ...[
          _buildTopAlert(context, topAlert, currencySymbol),
          const SizedBox(height: 16),
        ],
        if (donutData.isNotEmpty) ...[
          _buildDonutChart(context, donutData, totalSpent, currencySymbol),
          const SizedBox(height: 24),
        ],
        const Text(
          'Category Breakdown',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (allOnTrack && enriched.isNotEmpty) ...[
          _buildAllGoodBanner(context, enriched.length),
          const SizedBox(height: 8),
        ],
        if (enriched.isEmpty)
          _buildEmptyState(context)
        else
          ...enriched.map(
            (e) => _buildCategoryCard(
              context,
              e,
              currencySymbol,
              isCurrentCycle,
              cycleStart,
              cycleEnd,
            ),
          ),
      ],
    );
  }

  // ── Cycle Switcher ────────────────────────────────────────────────────────
  Widget _buildCycleSwitcher(
    BuildContext context,
    DateTime cycleStart,
    DateTime cycleEnd,
    int minOffset,
  ) {
    final label =
        '${DateFormat('MMM d').format(cycleStart)} – ${DateFormat('MMM d, yyyy').format(cycleEnd)}';
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(
            Icons.chevron_left,
            // ignore: deprecated_member_use
            color: _cycleOffset <= minOffset
                ? Colors.grey.withOpacity(0.3)
                : null,
          ),
          onPressed: _cycleOffset <= minOffset
              ? null
              : () => setState(() {
                  _cycleOffset--;
                  _touchedDonutIndex = -1;
                }),
        ),
        Column(
          children: [
            Text(
              _cycleOffset == 0 ? 'Current Cycle' : 'Past Cycle',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        IconButton(
          icon: Icon(
            Icons.chevron_right,
            // ignore: deprecated_member_use
            color: _cycleOffset >= 0 ? Colors.grey.withOpacity(0.3) : null,
          ),
          onPressed: _cycleOffset >= 0
              ? null
              : () => setState(() {
                  _cycleOffset++;
                  _touchedDonutIndex = -1;
                }),
        ),
      ],
    );
  }

  // ── Global Budget Card ────────────────────────────────────────────────────
  Widget _buildGlobalCard(
    BuildContext context,
    String cs,
    double totalSpent,
    double budget,
    double spendPercent,
    bool isOver,
    double cycleProgress,
    int daysRemaining,
    bool isCurrentCycle,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            // ignore: deprecated_member_use
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Budget vs Spending',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isCurrentCycle)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$daysRemaining days left',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$cs${totalSpent.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                ' / $cs${budget.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: spendPercent),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) => _progressBar(
              spendPercent: value,
              cycleProgress: cycleProgress,
              isOver: isOver,
              barColor: Colors.white,
              // ignore: deprecated_member_use
              bgColor: Colors.white.withOpacity(0.2),
            ),
          ),
          if (isOver)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Over budget by $cs${(totalSpent - budget).toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Safe to Spend Banner ──────────────────────────────────────────────────
  Widget _buildSafeToSpend(
    BuildContext context,
    double safePerDay,
    String cs,
    bool isOver,
  ) {
    final color = isOver
        ? Colors.redAccent
        : Theme.of(context).colorScheme.primary;
    final icon = isOver ? Icons.warning_amber_rounded : Icons.savings_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        // ignore: deprecated_member_use
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOver
                      ? 'You\'ve exceeded your budget!'
                      : 'You can safely spend',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!isOver)
                  Text(
                    '$cs${safePerDay.toStringAsFixed(0)}/day',
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                Text(
                  isOver
                      ? 'Try to reduce spending for the rest of the cycle.'
                      : 'for the rest of this cycle',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary Stats Row ─────────────────────────────────────────────────────
  Widget _buildSummaryStats(
    BuildContext context,
    int onTrack,
    int pacing,
    int exceeded,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statPill('On Track', onTrack, Colors.green),
          Container(
            width: 1,
            height: 32,
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(0.2),
          ),
          _statPill('Pacing Over', pacing, Colors.orangeAccent),
          Container(
            width: 1,
            height: 32,
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(0.2),
          ),
          _statPill('Exceeded', exceeded, Colors.redAccent),
        ],
      ),
    );
  }

  Widget _statPill(String label, int count, Color color) => Column(
    children: [
      Text(
        '$count',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
    ],
  );

  // ── Top Alert Card ────────────────────────────────────────────────────────
  Widget _buildTopAlert(BuildContext context, _EnrichedBudget e, String cs) {
    final isOver = e.isOver;
    final color = isOver ? Colors.redAccent : Colors.orangeAccent;
    final message = isOver
        ? '${e.budget.categoryName} exceeded limit by $cs${(e.budget.currentSpend - e.budget.monthlyLimit).toStringAsFixed(0)}'
        : '${e.budget.categoryName} is pacing ${e.paceRatio.toStringAsFixed(1)}x over — ${(e.spendPercent * 100).toInt()}% used';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        // ignore: deprecated_member_use
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(
            isOver ? Icons.error_outline : Icons.trending_up,
            color: color,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOver ? '⚠️ Budget Exceeded' : '📈 Top Spending Alert',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(message, style: TextStyle(color: color, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Donut Chart ───────────────────────────────────────────────────────────
  Widget _buildDonutChart(
    BuildContext context,
    List<_EnrichedBudget> data,
    double totalSpent,
    String cs,
  ) {
    final theme = Theme.of(context);
    final touched = _touchedDonutIndex >= 0 && _touchedDonutIndex < data.length
        ? data[_touchedDonutIndex]
        : null;

    return Container(
      height: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Donut
          Expanded(
            flex: 5,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (response == null ||
                              response.touchedSection == null) {
                            _touchedDonutIndex = -1;
                            return;
                          }
                          _touchedDonutIndex =
                              response.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    centerSpaceRadius: 55,
                    sectionsSpace: 2,
                    sections: data.asMap().entries.map((entry) {
                      final i = entry.key;
                      final e = entry.value;
                      final isTouched = _touchedDonutIndex == i;
                      return PieChartSectionData(
                        value: e.budget.currentSpend,
                        color: e.chartColor,
                        radius: isTouched ? 68 : 56,
                        title: isTouched
                            ? '${(e.budget.currentSpend / totalSpent * 100).toStringAsFixed(1)}%'
                            : '',
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Center label
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      touched != null
                          ? touched.budget.categoryName.split(' ').first
                          : 'Spent',
                      style: TextStyle(color: Colors.grey[500], fontSize: 10),
                    ),
                    Text(
                      touched != null
                          ? '$cs${touched.budget.currentSpend.toStringAsFixed(0)}'
                          : '$cs${totalSpent.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Legend
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.take(6).toList().asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                final pct = totalSpent > 0
                    ? (e.budget.currentSpend / totalSpent * 100)
                    : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.5),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: e.chartColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          e.budget.categoryName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: _touchedDonutIndex == i
                                ? FontWeight.bold
                                : FontWeight.w400,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      Text(
                        '${pct.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── All Good Banner ───────────────────────────────────────────────────────
  Widget _buildAllGoodBanner(BuildContext context, int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.green.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Row(
        children: [
          Text('🎉', style: TextStyle(fontSize: 32)),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You\'re on track!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'All categories are within budget and pacing well. Keep it up!',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 64,
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Budget Categories Yet',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Go to Profile → Manage Categories\nto set up your budget limits.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Category Card ─────────────────────────────────────────────────────────
  Widget _buildCategoryCard(
    BuildContext context,
    _EnrichedBudget e,
    String cs,
    bool isCurrentCycle,
    DateTime cycleStart,
    DateTime cycleEnd,
  ) {
    final activeColor = e.isOver
        ? Colors.redAccent
        : e.isPacingOver
        ? Colors.orangeAccent
        : e.meta.color;
    final percentInt = (e.spendPercent * 100).toInt();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoryDetailScreen(
            categoryName: e.budget.categoryName,
            icon: e.meta.icon,
            color: activeColor,
            monthlyLimit: e.budget.monthlyLimit,
            currentSpend: e.budget.currentSpend,
            currencySymbol: cs,
            cycleStart: cycleStart,
            cycleEnd: cycleEnd,
          ),
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: e.isOver
              // ignore: deprecated_member_use
              ? Border.all(color: Colors.redAccent.withOpacity(0.4))
              : e.isPacingOver
              // ignore: deprecated_member_use
              ? Border.all(color: Colors.orangeAccent.withOpacity(0.4))
              : null,
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.grey.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Hero animated icon avatar
                Hero(
                  tag: 'category_icon_${e.budget.categoryName}',
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: activeColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(e.meta.icon, color: activeColor, size: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Name + spent/limit
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.budget.categoryName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$cs${e.budget.currentSpend.toStringAsFixed(0)} / $cs${e.budget.monthlyLimit.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: e.isOver ? Colors.redAccent : Colors.grey[600],
                          fontSize: 13,
                          fontWeight: e.isOver
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Circular dial
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: CircularProgressIndicator(
                        value: e.spendPercent,
                        strokeWidth: 5,
                        // ignore: deprecated_member_use
                        backgroundColor: Colors.grey.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation(activeColor),
                      ),
                    ),
                    Text(
                      '$percentInt%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: activeColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Animated progress bar
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: e.spendPercent),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => _progressBar(
                spendPercent: value,
                cycleProgress: e.cycleProgress,
                isOver: e.isOver,
                barColor: activeColor,
                // ignore: deprecated_member_use
                bgColor: activeColor.withOpacity(0.12),
              ),
            ),
            const SizedBox(height: 8),
            // Status row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (e.isOver)
                  Text(
                    'Over by $cs${(e.budget.currentSpend - e.budget.monthlyLimit).toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else if (e.isPacingOver)
                  Text(
                    '⚠️ Pacing ${e.paceRatio.toStringAsFixed(1)}x over',
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  Text(
                    '$cs${(e.budget.monthlyLimit - e.budget.currentSpend).toStringAsFixed(0)} left',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ), // AnimatedContainer
    ); // GestureDetector
  }

  // ── Progress Bar with Pace Marker ─────────────────────────────────────────
  Widget _progressBar({
    required double spendPercent,
    required double cycleProgress,
    required bool isOver,
    required Color barColor,
    required Color bgColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          Container(height: 10, color: bgColor),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: spendPercent.clamp(0.0, 1.0),
            child: Container(height: 10, color: barColor),
          ),
        ],
      ),
    );
  }
}
