import 'package:aifin/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aifin/routes/route_names.dart';
import 'package:aifin/core/providers/user_provider.dart';
import 'package:aifin/core/providers/transaction_provider.dart';
import 'package:aifin/features/dashboard/widgets/voice_assistant_sheet.dart';
import 'package:aifin/data/models/transaction_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:aifin/features/budget/screens/budget_screen.dart';
import 'package:aifin/features/ai_insights/screens/ai_insights_screen.dart';
import 'package:aifin/features/profile/screens/profile_screen.dart';
import 'package:aifin/features/payments/screens/upi_payment_screen.dart';


// ── Models ────────────────────────────────────────────────────────────────────
class GoalModel {
  final String title;
  final double current;
  final double target;
  final IconData icon;
  final Color color;

  GoalModel({
    required this.title,
    required this.current,
    required this.target,
    required this.icon,
    required this.color,
  });

  double get percent => (current / target).clamp(0.0, 1.0);
}

class BillModel {
  final String title;
  final double amount;
  final DateTime dueDate;
  final IconData icon;

  BillModel({
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.icon,
  });

  int get daysLeft => dueDate.difference(DateTime.now()).inDays;
}
// ──────────────────────────────────────────────────────────────────────────────

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 4) return 'Good Night,';
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



  Widget _buildDashboardContent(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(userProvider);
    final transactionsAsync = ref.watch(transactionProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pushNamed(RouteNames.profile),
              child: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.person, color: Colors.white),
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
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ],
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
        //     onPressed: () async {
        //       final confirmed = await showDialog<bool>(
        //         context: context,
        //         builder: (context) => AlertDialog(
        //           title: const Text('Logout'),
        //           content: const Text(
        //             'Are you sure you want to end your session?',
        //           ),
        //           actions: [
        //             TextButton(
        //               onPressed: () => Navigator.pop(context, false),
        //               child: const Text('Cancel'),
        //             ),
        //             TextButton(
        //               onPressed: () => Navigator.pop(context, true),
        //               child: const Text(
        //                 'Logout',
        //                 style: TextStyle(color: Colors.red),
        //               ),
        //             ),
        //           ],
        //         ),
        //       );
        //       if (confirmed == true) {
        //         await ref.read(userProvider.notifier).logout();
        //         if (context.mounted) {
        //           Navigator.pushNamedAndRemoveUntil(
        //             context,
        //             RouteNames.login,
        //             (route) => false,
        //           );
        //         }
        //       }
        //     },
        //   ),
        // ],
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
          final currencySymbol =
              user?.preferences['currency'] ?? AppConstants.currencySymbol;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMoneyLeak(context),
                const SizedBox(height: 16),
                // Total Balance Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                          // ignore: deprecated_member_use
                        ).colorScheme.primary.withOpacity(0.3),
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
                        '$currencySymbol${balance.toStringAsFixed(2)}',
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
                            '$currencySymbol${totalIncome.toStringAsFixed(0)}',
                            Icons.arrow_downward,
                            Colors.greenAccent,
                          ),
                          _buildIncomeExpensePill(
                            'Expense',
                            '$currencySymbol${totalExpenses.toStringAsFixed(0)}',
                            Icons.arrow_upward,
                            Colors.redAccent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
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
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BudgetScreen()),
                      ),
                    ),
                    _buildActionCard(
                      context,
                      Icons.receipt_long,
                      'Transactions',
                      onTap: () =>
                          Navigator.pushNamed(context, RouteNames.expenseList),
                    ),
                    _buildActionCard(
                      context,
                      Icons.mic,
                      'Voice Ledger',
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const VoiceAssistantSheet(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionCard(
                      context,
                      Icons.call_split,
                      'Split Bill',
                      onTap: () {}, // TODO
                    ),
                    _buildActionCard(
                      context,
                      Icons.document_scanner_outlined,
                      'Scan Slip',
                      onTap: () {}, // TODO
                    ),
                    _buildActionCard(
                      context,
                      Icons.bolt_rounded,
                      'UPI Pay',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UpiPaymentScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                _buildSavingsGoals(context),
                const SizedBox(height: 32),
                // Interactive Spending Chart
                _buildSpendingChart(context, transactions, currencySymbol),
                const SizedBox(height: 32),
                _buildUpcomingBills(context, currencySymbol),
                const SizedBox(height: 32),
                // AI Insights Banner
                GestureDetector(
                  onTap: () {
                    setState(() => _currentIndex = 1);
                    _pageController.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
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
                        Icon(
                          Icons.auto_awesome,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Financial Insights',
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
                const SizedBox(height: 70),

              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: [
          _buildDashboardContent(context, ref),
          const AiInsightsScreen(),
          const ProfileScreen(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              shape: const CircleBorder(),
              elevation: 6,
              onPressed: () =>
                  Navigator.pushNamed(context, RouteNames.addExpense),
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 65,
            child: Row(
              children: [
                _buildNavItem(context, Icons.home, Icons.home_outlined, 0),
                _buildNavItem(
                  context,
                  Icons.auto_awesome,
                  Icons.auto_awesome_outlined,
                  1,
                ),
                _buildNavItem(context, Icons.person, Icons.person_outline, 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData activeIcon,
    IconData inactiveIcon,
    int index,
  ) {
    final isSelected = _currentIndex == index;
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() => _currentIndex = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? primaryColor : Colors.grey,
              size: 26,
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              height: 3,
              width: isSelected ? 22 : 0,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 1. Money Leak Alert ──────────────────────────────────────────────────
  Widget _buildMoneyLeak(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: Colors.amber, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Money Leak Detected',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                      fontSize: 13),
                ),
                Text(
                  'Spent 30% more on Food this weekend.',
                  style: TextStyle(color: Colors.amber, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.amber, size: 20),
        ],
      ),
    );
  }

  // ── 2. Weekly Comparison Line Chart ──────────────────────────────────────
  Widget _buildWeeklyComparison(
      BuildContext context, List<TransactionModel> tx) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Weekly Comparison',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('↓ 12%',
                  style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 100,
          padding: const EdgeInsets.only(right: 16, top: 12),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: _getWeeklySpendingData(tx),
                  isCurved: true,
                  color: theme.colorScheme.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    // ignore: deprecated_member_use
                    color: theme.colorScheme.primary.withOpacity(0.1),
                  ),
                ),
                LineChartBarData(
                  spots: [
                    const FlSpot(0, 4),
                    const FlSpot(1, 4),
                    const FlSpot(2, 4),
                    const FlSpot(3, 4),
                    const FlSpot(4, 4),
                    const FlSpot(5, 4),
                    const FlSpot(6, 4),
                  ],
                  isCurved: true,
                  // ignore: deprecated_member_use
                  color: Colors.grey.withOpacity(0.3),
                  barWidth: 2,
                  dashArray: [5, 5],
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── 3. Savings Goals ──────────────────────────────────────────────────────
  Widget _buildSavingsGoals(BuildContext context) {
    final theme = Theme.of(context);
    final goals = [
      GoalModel(
          title: 'New iPhone',
          current: 45000,
          target: 120000,
          icon: Icons.phone_iphone,
          color: const Color(0xFF6366F1)),
      GoalModel(
          title: 'MacBook Pro',
          current: 110000,
          target: 180000,
          icon: Icons.laptop_mac_rounded,
          color: const Color(0xFF10B981)),
      GoalModel(
          title: 'Bali Trip',
          current: 40000,
          target: 150000,
          icon: Icons.beach_access_rounded,
          color: const Color(0xFFF59E0B)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Savings Goals',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('New Goal', style: TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: goals.length,
            padding: const EdgeInsets.only(right: 20),
            itemBuilder: (context, index) {
              final goal = goals[index];
              return Container(
                width: 150,
                margin: const EdgeInsets.only(right: 16, bottom: 8, top: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 50,
                          height: 50,
                            child: CircularProgressIndicator(
                              value: goal.percent,
                              // ignore: deprecated_member_use
                              backgroundColor: goal.color.withOpacity(0.1),
                              color: goal.color,
                              strokeWidth: 4,
                              strokeCap: StrokeCap.round,
                            ),
                        ),
                        Icon(goal.icon, color: goal.color, size: 20),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      goal.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${(goal.percent * 100).toInt()}%',
                      style: TextStyle(
                        color: goal.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── 4. Upcoming Bills ─────────────────────────────────────────────────────
  Widget _buildUpcomingBills(BuildContext context, String cs) {
    final bills = [
      BillModel(
          title: 'Netflix Premium',
          amount: 649,
          dueDate: DateTime.now().add(const Duration(days: 1)),
          icon: Icons.movie_filter_rounded),
      BillModel(
          title: 'Monthly Rent',
          amount: 18000,
          dueDate: DateTime.now().add(const Duration(days: 4)),
          icon: Icons.home_work_rounded),
      BillModel(
          title: 'Cloud Storage',
          amount: 199,
          dueDate: DateTime.now().add(const Duration(days: 6)),
          icon: Icons.cloud_done_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Bills',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...bills.map((b) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(b.icon,
                        color: Theme.of(context).colorScheme.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.title,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          b.daysLeft == 0
                              ? 'Due Today'
                              : 'Due in ${b.daysLeft} days',
                          style: TextStyle(
                            color: b.daysLeft == 1 ? Colors.orange : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$cs${b.amount.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    final color = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.28,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeExpensePill(
    String label,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
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
      ),
    );
  }

  Widget _buildSpendingChart(
    BuildContext context,
    List<TransactionModel> transactions,
    String currencySymbol,
  ) {
    final theme = Theme.of(context);
    final expenseTransactions = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    // Group by category for the chart
    final Map<String, double> categorySums = {};
    for (var t in expenseTransactions) {
      categorySums[t.category] = (categorySums[t.category] ?? 0) + t.amount;
    }

    final sortedEntries = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final chartData = sortedEntries.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Spending Breakdown',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          height: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: chartData.isEmpty
              ? const Center(child: Text('Add transactions to see analysis'))
              : PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 50,
                    sections: chartData.asMap().entries.map((entry) {
                      final index = entry.key;
                      final category = entry.value;
                      final color = AppColors.chartColors[
                          index % AppColors.chartColors.length];

                      return PieChartSectionData(
                        color: color,
                        value: category.value,
                        title: '',
                        radius: 50,
                        badgeWidget: _Badge(
                          category.key,
                          size: 40,
                          borderColor: color,
                        ),
                        badgePositionPercentageOffset: 1.3,
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(
    this.label, {
    required this.size,
    required this.borderColor,
  });
  final String label;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 3,
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.15),
      child: Center(
        child: Icon(
          _getCategoryIcon(label),
          size: size * 0.5,
          color: borderColor,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food & Dining':
        return Icons.restaurant;
      case 'Transportation':
        return Icons.directions_car;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Entertainment':
        return Icons.movie;
      case 'Bills & Utilities':
        return Icons.receipt;
      case 'Health':
        return Icons.medical_services;
      case 'Salary':
        return Icons.payments;
      case 'Freelance':
        return Icons.work;
      case 'Investment':
        return Icons.trending_up;
      case 'Gift':
        return Icons.card_giftcard;
      default:
        return Icons.category;
    }
  }
}
