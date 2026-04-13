import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aifin/features/ai_insights/providers/ai_provider.dart';
import 'package:aifin/core/constants/app_constants.dart';
import 'package:aifin/core/providers/transaction_provider.dart';
import 'package:aifin/core/providers/user_provider.dart';
import 'package:aifin/data/models/transaction_model.dart';

// ── Health Score Arc Painter ───────────────────────────────────────────────────
class _ScoreArcPainter extends CustomPainter {
  final double score;
  final Color color;
  final double progress;

  const _ScoreArcPainter({
    required this.score,
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - 14;
    const strokeWidth = 14.0;
    const startAngle = math.pi * 5 / 4; // 7:30 position (bottom-left)
    const sweepFull = math.pi * 3 / 2;  // 270° sweep

    // Background track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepFull,
      false,
      Paint()
        // ignore: deprecated_member_use
        ..color = color.withOpacity(0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Animated score fill
    final fillSweep = sweepFull * (score / 100) * progress;
    if (fillSweep > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        fillSweep,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ScoreArcPainter old) =>
      old.score != score ||
      old.progress != progress ||
      old.color != color;
}

// ── Data class ─────────────────────────────────────────────────────────────────
class _HealthData {
  final double score;
  final double savingRate;
  final double net;
  final double totalIncome;
  final double totalExpense;
  final Map<String, double> topCategories;

  const _HealthData({
    required this.score,
    required this.savingRate,
    required this.net,
    required this.totalIncome,
    required this.totalExpense,
    required this.topCategories,
  });
}

// ── AiInsightsScreen ───────────────────────────────────────────────────────────
class AiInsightsScreen extends ConsumerStatefulWidget {
  const AiInsightsScreen({super.key});

  @override
  ConsumerState<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends ConsumerState<AiInsightsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  _HealthData _computeHealth(List<TransactionModel> tx) {
    if (tx.isEmpty) {
      return const _HealthData(
        score: 0,
        savingRate: 0,
        net: 0,
        totalIncome: 0,
        totalExpense: 0,
        topCategories: {},
      );
    }

    double income = 0, expense = 0;
    final Map<String, double> catSpend = {};

    for (final t in tx) {
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else {
        expense += t.amount;
        catSpend[t.category] = (catSpend[t.category] ?? 0) + t.amount;
      }
    }

    final net = income - expense;
    final savingRate =
        income > 0 ? ((net / income) * 100).clamp(-100.0, 100.0) : 0.0;

    // Score: savings rate (0–50 pts)
    final savingsScore =
        savingRate >= 20 ? 50.0 : (savingRate / 20 * 50).clamp(0.0, 50.0);

    // Score: spending diversity (0–30 pts)
    double divScore = 30.0;
    if (catSpend.isNotEmpty && expense > 0) {
      final topShare = catSpend.values.reduce(math.max) / expense;
      divScore = ((1 - topShare) * 30).clamp(0.0, 30.0);
    }

    // Score: data richness (0–20 pts)
    final dataScore = (tx.length / 30 * 20).clamp(0.0, 20.0);

    final score = (savingsScore + divScore + dataScore).clamp(0.0, 100.0);

    final sorted = catSpend.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _HealthData(
      score: score,
      savingRate: savingRate,
      net: net,
      totalIncome: income,
      totalExpense: expense,
      topCategories: Map.fromEntries(sorted.take(5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactionsAsync = ref.watch(transactionProvider);
    final aiInsights = ref.watch(aiInsightsProvider);
    final user = ref.watch(userProvider);
    final cs = user?.preferences['currency'] ?? AppConstants.currencySymbol;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Financial Advisor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.refresh(aiInsightsProvider);
              _ctrl.reset();
              _ctrl.forward();
            },
          ),
        ],
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tx) {
          final health = _computeHealth(tx);
          final scoreColor = health.score >= 70
              ? Colors.green
              : health.score >= 40
                  ? Colors.orangeAccent
                  : Colors.redAccent;
          final scoreLabel = health.score >= 70
              ? 'Excellent'
              : health.score >= 40
                  ? 'Fair'
                  : 'Needs Work';

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),

                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Health Score ──────────────────────────────────
                    _buildScoreCard(
                        context, theme, health, scoreColor, scoreLabel, cs),
                    const SizedBox(height: 20),

                    // ── Quick Stats ───────────────────────────────────
                    _buildStatsRow(context, health, cs),
                    const SizedBox(height: 28),

                    // ── Insights ──────────────────────────────────────
                    const Text(
                      'Personal Insights',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),
                    _buildInsights(context, aiInsights, health, cs),

                    // ── Category Breakdown ────────────────────────────
                    if (health.topCategories.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      const Text(
                        'Spending Breakdown',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 14),
                      _buildBreakdown(context, theme, health, cs),
                    ],
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Health Score Card ─────────────────────────────────────────────────────
  Widget _buildScoreCard(
    BuildContext context,
    ThemeData theme,
    _HealthData h,
    Color scoreColor,
    String scoreLabel,
    String cs,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            // ignore: deprecated_member_use
            theme.colorScheme.primary.withOpacity(0.72),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: theme.colorScheme.primary.withOpacity(0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome,
                  color: Colors.white54, size: 15),
              const SizedBox(width: 6),
              const Text(
                'AEGIS  ·  YOUR AI ADVISOR',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Animated Gauge
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => SizedBox(
              width: 170,
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(170, 170),
                    painter: _ScoreArcPainter(
                      score: h.score,
                      color: scoreColor,
                      progress: _anim.value,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(h.score * _anim.value).toInt()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        scoreLabel,
                        style: TextStyle(
                          color: scoreColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Health Score',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              h.score >= 70
                  ? '🎉 Your finances look great! Keep it up.'
                  : h.score >= 40
                      ? '📊 Some areas could use improvement.'
                      : '⚠️ Let\'s strengthen your finances together.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick Stats Row ───────────────────────────────────────────────────────
  Widget _buildStatsRow(
      BuildContext context, _HealthData h, String cs) {
    return Row(
      children: [
        _statCard(
          context,
          '💰',
          'Savings Rate',
          '${h.savingRate.toStringAsFixed(1)}%',
          h.savingRate >= 20 ? Colors.green : Colors.orangeAccent,
        ),
        const SizedBox(width: 12),
        _statCard(
          context,
          h.net >= 0 ? '📈' : '📉',
          'Net Balance',
          '${h.net >= 0 ? '+' : '-'}$cs${h.net.abs().toStringAsFixed(0)}',
          h.net >= 0 ? Colors.green : Colors.redAccent,
        ),
        const SizedBox(width: 12),
        _statCard(
          context,
          '🧾',
          'Total Spent',
          '$cs${h.totalExpense.toStringAsFixed(0)}',
          Colors.blueAccent,
        ),
      ],
    );
  }

  Widget _statCard(
    BuildContext context,
    String emoji,
    String label,
    String value,
    Color valueColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Insight Cards ─────────────────────────────────────────────────────────
  Widget _buildInsights(
    BuildContext context,
    AsyncValue<String> aiAsync,
    _HealthData h,
    String cs,
  ) {
    return aiAsync.when(
      loading: () => _insightCard(
        context: context,
        icon: Icons.hourglass_top,
        title: 'Analyzing your data…',
        body: 'Aegis is reviewing your financial patterns.',
        color: Colors.grey,
      ),
      error: (_, __) => _insightCard(
        context: context,
        icon: Icons.cloud_off,
        title: 'Advisor Offline',
        body: 'AI analysis is temporarily unavailable.',
        color: Colors.grey,
      ),
      data: (advice) {
        if (advice == '__EMPTY__') {
          return _insightCard(
            context: context,
            icon: Icons.add_chart,
            title: 'No Data Yet',
            body:
                'Add your first transaction to get personalized advice from Aegis.',
            color: Colors.blue,
          );
        }

        return Column(
          children: [
            // Card 1: Balance
            _insightCard(
              context: context,
              icon: h.net >= 0
                  ? Icons.trending_up
                  : Icons.trending_down,
              title: h.net >= 0
                  ? '✅ Positive Cash Flow'
                  : '⚠️ Spending Exceeds Income',
              body: h.net >= 0
                  ? 'You\'ve built a net surplus of $cs${h.net.toStringAsFixed(0)}. '
                      'Saving rate: ${h.savingRate.toStringAsFixed(1)}%.'
                  : 'Expenses exceed income by $cs${h.net.abs().toStringAsFixed(0)}. '
                      'Review your variable spending to find savings.',
              color: h.net >= 0 ? Colors.green : Colors.redAccent,
            ),
            const SizedBox(height: 12),

            // Card 2: Top category
            if (h.topCategories.isNotEmpty) ...[
              _insightCard(
                context: context,
                icon: Icons.pie_chart_outline,
                title: '🔍 Top Spending Area',
                body: () {
                  final top = h.topCategories.entries.first;
                  final share = h.totalExpense > 0
                      ? (top.value / h.totalExpense * 100)
                          .toStringAsFixed(0)
                      : '0';
                  return '${top.key} accounts for $share% of expenses '
                      '($cs${top.value.toStringAsFixed(0)}). '
                      'Compare against your budget limit to see if it\'s on track.';
                }(),
                color: Colors.orangeAccent,
              ),
              const SizedBox(height: 12),
            ],

            // Card 3: Tip
            _insightCard(
              context: context,
              icon: Icons.lightbulb_outline,
              title: '💡 Aegis Tip',
              body: h.savingRate < 20
                  ? 'Try the 50/30/20 rule: 50% on needs, 30% on wants, '
                      '20% saved. Even saving a little extra each month compounds over time.'
                  : 'You\'re saving above 20% — excellent! Consider moving surplus '
                      'to an index fund or recurring deposit to grow wealth passively.',
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        );
      },
    );
  }

  Widget _insightCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String body,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        // ignore: deprecated_member_use
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: TextStyle(
                    // ignore: deprecated_member_use
                    color: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.color
                        // ignore: deprecated_member_use
                        ?.withOpacity(0.75),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Category Breakdown ────────────────────────────────────────────────────
  Widget _buildBreakdown(
    BuildContext context,
    ThemeData theme,
    _HealthData h,
    String cs,
  ) {
    const barColors = [
      Color(0xFF6C63FF),
      Color(0xFFFF8C42),
      Color(0xFF2196F3),
      Color(0xFF4CAF50),
      Color(0xFFE91E63),
    ];
    final maxVal = h.topCategories.values.reduce(math.max);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
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
        children: h.topCategories.entries
            .toList()
            .asMap()
            .entries
            .map((entry) {
          final i = entry.key;
          final cat = entry.value;
          final pct = maxVal > 0 ? cat.value / maxVal : 0.0;
          final color = barColors[i % barColors.length];
          final share = h.totalExpense > 0
              ? (cat.value / h.totalExpense * 100).toStringAsFixed(0)
              : '0';

          return Padding(
            padding: EdgeInsets.only(bottom: i < 4 ? 16 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          cat.key,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          '$cs${cat.value.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            // ignore: deprecated_member_use
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$share%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: pct),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, value, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Container(
                          height: 9,
                          // ignore: deprecated_member_use
                          color: color.withOpacity(0.12),
                        ),
                        FractionallySizedBox(
                          widthFactor: value.clamp(0.0, 1.0),
                          child: Container(height: 9, color: color),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
