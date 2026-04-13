import 'package:aifin/data/models/user_model.dart';
import 'package:aifin/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aifin/core/providers/user_provider.dart';
import 'package:aifin/core/constants/app_constants.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Premium Header ───────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                alignment: Alignment.center,
                children: [
                  // Decorative background element
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryColor, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: primaryColor.withOpacity(0.1),
                          child: Icon(Icons.person_rounded, 
                              size: 50, color: primaryColor),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.username ?? 'Guest User',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user?.email ?? 'No email linked',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Settings Content ─────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 10),
                
                // Account Section
                _buildModernSection(
                  context,
                  'Account Settings',
                  [
                    _buildModernTile(
                      context,
                      Icons.person_outline_rounded,
                      'Edit Profile',
                      subtitle: 'Change your display name',
                      onTap: () => _showEditProfile(context, ref, user?.username ?? ''),
                    ),
                    _buildModernTile(
                      context,
                      Icons.security_rounded,
                      'Security',
                      subtitle: 'Privacy and password',
                      onTap: () {},
                    ),
                    _buildModernTile(
                      context,
                      Icons.notifications_none_rounded,
                      'Notifications',
                      subtitle: 'Alerts and reminders',
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Preferences Section
                _buildModernSection(
                  context,
                  'Finances & Preferences',
                  [
                    _buildModernTile(
                      context,
                      Icons.account_balance_wallet_outlined,
                      'Monthly Budget',
                      subtitle: user?.preferences['monthlyBudget'] != null 
                          ? '${AppConstants.currencySymbol}${user?.preferences['monthlyBudget']}' 
                          : 'Not set',
                      onTap: () {
                        final val = user?.preferences['monthlyBudget'];
                        final currentBudget = (val != null)
                            ? double.tryParse(val.toString()) ?? 0.0
                            : 0.0;
                        _showSetBudget(context, ref, currentBudget);
                      },
                    ),
                    _buildModernTile(
                      context,
                      Icons.calendar_month_outlined,
                      'Financial Cycle',
                      subtitle: user?.preferences['cycleStartDate'] == -1 
                          ? 'Starts on Last Day' 
                          : 'Starts on Day ${user?.preferences['cycleStartDate'] ?? '1'}',
                      onTap: () {
                        final dayStr = user?.preferences['cycleStartDate']?.toString() ?? '1';
                        final cycleDay = int.tryParse(dayStr) ?? 1;
                        _showCyclePicker(context, ref, cycleDay);
                      },
                    ),
                    _buildModernTile(
                      context,
                      Icons.currency_exchange_rounded,
                      'Currency',
                      subtitle: 'Active: ${user?.preferences['currency'] ?? '₹'}',
                      onTap: () => _showCurrencyPicker(context, ref, user?.preferences['currency'] ?? '₹'),
                    ),
                     _buildModernTile(
                      context,
                      Icons.color_lens_outlined,
                      'Theme Accent',
                      subtitle: user?.preferences['themeAccent'] ?? 'Deep Purple',
                      onTap: () => _showAccentPicker(context, ref, user?.preferences['themeAccent']?.toString() ?? 'Deep Purple'),
                    ),
                    _buildModernTile(
                      context,
                      Icons.dark_mode_outlined,
                      'Dark Mode',
                      subtitle: 'Switch application theme',
                      trailing: Switch(
                        value: user?.preferences['theme'] == 'dark',
                        onChanged: (v) => ref.read(userProvider.notifier).updatePreference('theme', v ? 'dark' : 'light'),
                        activeColor: primaryColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Logout Button
                OutlinedButton(
                  onPressed: () => _handleLogout(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Version 1.2.4 (Stable)',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12, letterSpacing: 1),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSection(BuildContext context, String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: tiles,
          ),
        ),
      ],
    );
  }

  Widget _buildModernTile(
    BuildContext context,
    IconData icon,
    String title, {
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }

  void _showEditProfile(BuildContext context, WidgetRef ref, String currentName) {
     final controller = TextEditingController(text: currentName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit Profile Name', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Display Name', border: OutlineInputBorder())),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { ref.read(userProvider.notifier).updateName(controller.text.trim()); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary), child: const Text('SAVE CHANGES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showSetBudget(BuildContext context, WidgetRef ref, double currentBudget) {
    final controller = TextEditingController(text: currentBudget > 0 ? currentBudget.toStringAsFixed(0) : '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Set Monthly Budget', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), autofocus: true, decoration: const InputDecoration(labelText: 'Budget Amount', border: OutlineInputBorder())),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { final budgetValue = double.tryParse(controller.text.trim()); if (budgetValue != null) { ref.read(userProvider.notifier).updatePreference('monthlyBudget', budgetValue); } Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary), child: const Text('SAVE BUDGET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, WidgetRef ref, String currentCurrency) {
    final currencies = [
      {'name': 'US Dollar', 'symbol': '\$'},
      {'name': 'Euro', 'symbol': '€'},
      {'name': 'British Pound', 'symbol': '£'},
      {'name': 'Indian Rupee', 'symbol': '₹'},
      {'name': 'Japanese Yen', 'symbol': '¥'},
    ];
    showModalBottomSheet(context: context, builder: (context) => Column(mainAxisSize: MainAxisSize.min, children: [
      const Padding(padding: EdgeInsets.all(20), child: Text('Select Currency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      ...currencies.map((c) => ListTile(
        title: Text(c['name']!),
        trailing: currentCurrency == c['symbol'] ? const Icon(Icons.check, color: Colors.green) : null,
        onTap: () { ref.read(userProvider.notifier).updatePreference('currency', c['symbol']); Navigator.pop(context); },
      )),
      const SizedBox(height: 20),
    ]));
  }

  void _showCyclePicker(BuildContext context, WidgetRef ref, int currentDay) {
    showModalBottomSheet(context: context, builder: (context) => Column(mainAxisSize: MainAxisSize.min, children: [
      const Padding(padding: EdgeInsets.all(20), child: Text('Monthly Cycle Start', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      ListTile(title: const Text('1st of Month'), onTap: () { ref.read(userProvider.notifier).updatePreference('cycleStartDate', 1); Navigator.pop(context); }),
      ListTile(title: const Text('Last Day of Month'), onTap: () { ref.read(userProvider.notifier).updatePreference('cycleStartDate', -1); Navigator.pop(context); }),
      const SizedBox(height: 20),
    ]));
  }

  void _showAccentPicker(BuildContext context, WidgetRef ref, String currentAccent) {
    final accents = [
      {'name': 'Deep Purple', 'color': Colors.deepPurpleAccent},
      {'name': 'Emerald Green', 'color': Colors.teal},
      {'name': 'Midnight Blue', 'color': const Color(0xFF191970)},
      {'name': 'Ruby Red', 'color': Colors.redAccent},
    ];
    showModalBottomSheet(context: context, builder: (context) => Column(mainAxisSize: MainAxisSize.min, children: [
      const Padding(padding: EdgeInsets.all(20), child: Text('Theme Accent', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      ...accents.map((a) => ListTile(
        leading: CircleAvatar(backgroundColor: a['color'] as Color),
        title: Text(a['name'] as String),
        onTap: () { ref.read(userProvider.notifier).updatePreference('themeAccent', a['name']); Navigator.pop(context); },
      )),
      const SizedBox(height: 20),
    ]));
  }

  void _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(userProvider.notifier).logout();
      if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, RouteNames.login, (r) => false);
    }
  }
}
