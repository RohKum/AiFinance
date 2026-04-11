import 'package:aifin/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aifin/routes/route_names.dart';
import 'package:aifin/core/providers/user_provider.dart';
import 'package:aifin/core/providers/transaction_provider.dart';
import 'package:aifin/features/dashboard/widgets/voice_assistant_sheet.dart';
import 'package:aifin/data/models/transaction_model.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  List<FlSpot> _getWeeklySpendingData(List<TransactionModel> transactions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final Map<int, double> dailySpending = {for (int i = 0; i < 7; i++) i: 0.0};

    for (var t in transactions) {
      if (t.type == TransactionType.expense) {
        final tDate = DateTime(t.date.year, t.date.month, t.date.day);
        final difference = today.difference(tDate).inDays;

        if (difference >= 0 && difference < 7) {
          // Map to 0-6 where 6 is today, 0 is 6 days ago
          final index = 6 - difference;
          dailySpending[index] = (dailySpending[index] ?? 0) + t.amount;
        }
      }
    }

    return dailySpending.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
  }

  Widget _buildSpendingChart(List<TransactionModel> transactions) {
    final spots = _getWeeklySpendingData(transactions);
    final maxSpending = spots.isEmpty
        ? 0.0
        : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final totalWeeklySpending = spots.fold<double>(
      0.0,
      (sum, spot) => sum + spot.y,
    );

    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Spending This Week',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${AppConstants.currencySymbol}${totalWeeklySpending.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurpleAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) =>
                        Colors.deepPurple.shade700,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        return LineTooltipItem(
                          '${AppConstants.currencySymbol}${touchedSpot.y.toStringAsFixed(0)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxSpending <= 0 ? 10 : maxSpending / 3,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      // ignore: deprecated_member_use
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final daysAgo = 6 - value.toInt();
                        if (daysAgo == 0) {
                          return const Text(
                            'Today',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }
                        if (daysAgo == 6) {
                          return const Text(
                            '7d ago',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxSpending == 0 ? 50 : maxSpending * 1.3,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.deepPurpleAccent,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, barData) => spot.y > 0,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 5,
                            color: Colors.white,
                            strokeWidth: 3,
                            strokeColor: Colors.deepPurpleAccent,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          // ignore: deprecated_member_use
                          Colors.deepPurpleAccent.withOpacity(0.35),
                          // ignore: deprecated_member_use
                          Colors.deepPurpleAccent.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(
                milliseconds: 800,
              ), // Smooth entry animation
              curve: Curves.easeInOutCubic,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(userProvider);
    final transactionsAsync = ref.watch(transactionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pushNamed(RouteNames.profile),
              child: const CircleAvatar(
                backgroundColor: Colors.deepPurpleAccent,
                child: Icon(Icons.person, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  user?.username ?? 'Guest User',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text(
                    'Are you sure you want to end your session?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(userProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    RouteNames.login,
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (transactions) {
          final totalIncome = transactions
              .where((t) => t.type == TransactionType.income)
              .fold(0.0, (sum, t) => sum + t.amount);
          final totalExpenses = transactions
              .where((t) => t.type == TransactionType.expense)
              .fold(0.0, (sum, t) => sum + t.amount);
          final balance = totalIncome - totalExpenses;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total Balance Card
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Balance',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${AppConstants.currencySymbol}${balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildIncomeExpensePill(
                            'Income',
                            '${AppConstants.currencySymbol}${totalIncome.toStringAsFixed(0)}',
                            Icons.arrow_downward,
                            Colors.greenAccent,
                          ),
                          _buildIncomeExpensePill(
                            'Expense',
                            '${AppConstants.currencySymbol}${totalExpenses.toStringAsFixed(0)}',
                            Icons.arrow_upward,
                            Colors.redAccent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Interactive Spending Chart
                _buildSpendingChart(transactions),
                const SizedBox(height: 32),

                // AI Insights Banner
                GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, RouteNames.aiInsights),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: Colors.grey.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Colors.deepPurpleAccent,
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Financial Insights',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Analyze your spending patterns...',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionCard(
                      context,
                      Icons.account_balance_wallet,
                      'Budget',
                      onTap: () =>
                          Navigator.pushNamed(context, RouteNames.budget),
                    ),
                    _buildActionCard(
                      context,
                      Icons.receipt_long,
                      'History',
                      onTap: () =>
                          Navigator.pushNamed(context, RouteNames.expenseList),
                    ),
                    _buildActionCard(
                      context,
                      Icons.mic,
                      'AI Voice',
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const VoiceAssistantSheet(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, RouteNames.addExpense),
        backgroundColor: Colors.deepPurpleAccent,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,

        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.home, color: Colors.deepPurpleAccent),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.pie_chart_outline, color: Colors.grey),
              onPressed: () => Navigator.pushNamed(context, RouteNames.budget),
            ),
            const SizedBox(width: 48),
            IconButton(
              icon: const Icon(Icons.auto_awesome_outlined, color: Colors.grey),
              onPressed: () =>
                  Navigator.pushNamed(context, RouteNames.aiInsights),
            ),
            IconButton(
              icon: const Icon(Icons.person_outline, color: Colors.grey),
              onPressed: () => Navigator.pushNamed(context, RouteNames.profile),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeExpensePill(
    String title,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                // ignore: deprecated_member_use
                BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10),
              ],
            ),
            child: Icon(icon, color: Colors.deepPurpleAccent, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
