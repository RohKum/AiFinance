import 'package:aifin/data/models/user_model.dart';
import 'package:aifin/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aifin/core/providers/user_provider.dart';
import 'package:aifin/core/constants/app_constants.dart';
import 'package:aifin/data/models/user_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // User Avatar Section
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.username ?? 'Guest User',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              user?.email ?? 'No email linked',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            // Settings Section
            _buildSectionHeader('Account Settings'),
            _buildSettingsTile(
              context,
              Icons.person_outline,
              'Edit Profile',
              () {
                _showEditProfile(context, ref, user?.username ?? '');
              },
            ),
            _buildSettingsTile(context, Icons.lock_outline, 'Security', () {}),
            _buildSettingsTile(
              context,
              Icons.notifications_none,
              'Notifications',
              () {},
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('Preferences'),
            _buildSettingsTile(
              context,
              Icons.account_balance_wallet_outlined,
              'Monthly Budget (${user?.preferences['monthlyBudget'] != null ? '${AppConstants.currencySymbol}${user?.preferences['monthlyBudget']}' : 'Not Set'})',
              () {
                final val = user?.preferences['monthlyBudget'];
                final currentBudget = (val != null)
                    ? double.tryParse(val.toString()) ?? 0.0
                    : 0.0;
                _showSetBudget(context, ref, currentBudget);
              },
            ),
            _buildSettingsTile(
              context,
              Icons.autorenew,
              'Financial Cycle Starts (Day ${user?.preferences['cycleStartDate'] ?? '1'})',
              () {
                final dayStr =
                    user?.preferences['cycleStartDate']?.toString() ?? '1';
                final cycleDay = int.tryParse(dayStr) ?? 1;
                _showCyclePicker(context, ref, cycleDay);
              },
            ),
            _buildSettingsTile(context, Icons.language, 'Language', () {}),
            _buildSettingsTile(
              context,
              Icons.currency_exchange,
              'Currency (${user?.preferences['currency'] ?? '₹'})',
              () => _showCurrencyPicker(
                context,
                ref,
                user?.preferences['currency'] ?? '₹',
              ),
            ),
            _buildSettingsTile(
              context,
              Icons.category_outlined,
              'Manage Categories',
              () => _showManageCategories(context, ref, user),
            ),
            _buildSettingsTile(
              context,
              Icons.color_lens_outlined,
              'Theme Accent (${user?.preferences['themeAccent'] ?? 'Deep Purple'})',
              () => _showAccentPicker(
                context,
                ref,
                user?.preferences['themeAccent']?.toString() ?? 'Deep Purple',
              ),
            ),
            _buildSettingsTile(
              context,
              Icons.dark_mode_outlined,
              'Dark Mode',
              () {},
              trailing: Switch(
                value: user?.preferences['theme'] == 'dark',
                onChanged: (v) => ref
                    .read(userProvider.notifier)
                    .updatePreference('theme', v ? 'dark' : 'light'),
                activeThumbColor: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 48),
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _handleLogout(context, ref),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Version 1.0.0 (Beta)',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfile(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) {
    final controller = TextEditingController(text: currentName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Profile Name',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref
                      .read(userProvider.notifier)
                      .updateName(controller.text.trim());
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: const Text(
                  'SAVE CHANGES',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showSetBudget(
    BuildContext context,
    WidgetRef ref,
    double currentBudget,
  ) {
    final controller = TextEditingController(
      text: currentBudget > 0 ? currentBudget.toStringAsFixed(0) : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set Monthly Budget',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Budget Amount',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final budgetValue = double.tryParse(controller.text.trim());
                  if (budgetValue != null) {
                    ref
                        .read(userProvider.notifier)
                        .updatePreference('monthlyBudget', budgetValue);
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: const Text(
                  'SAVE BUDGET',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker(
    BuildContext context,
    WidgetRef ref,
    String currentCurrency,
  ) {
    final currencies = [
      {'name': 'US Dollar', 'symbol': '\$'},
      {'name': 'Euro', 'symbol': '€'},
      {'name': 'British Pound', 'symbol': '£'},
      {'name': 'Indian Rupee', 'symbol': '₹'},
      {'name': 'Japanese Yen', 'symbol': '¥'},
      {'name': 'Australian Dollar', 'symbol': 'A\$'},
      {'name': 'Canadian Dollar', 'symbol': 'C\$'},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Select Currency',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            ...currencies.map((currency) {
              final isSelected = currentCurrency == currency['symbol'];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Text(
                    currency['symbol']!,
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  currency['name']!,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  ref
                      .read(userProvider.notifier)
                      .updatePreference('currency', currency['symbol']);
                  Navigator.pop(context);
                },
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showCyclePicker(BuildContext context, WidgetRef ref, int currentDay) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Financial Month Start',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  'Your budget limit and charts will reset starting on this date every month.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: 28, // Max 28 to safely fit all calendar months
                  itemBuilder: (context, index) {
                    final day = index + 1;
                    final isSelected = currentDay == day;

                    String suffix = 'th';
                    if (day >= 11 && day <= 13)
                      suffix = 'th';
                    else if (day % 10 == 1)
                      suffix = 'st';
                    else if (day % 10 == 2)
                      suffix = 'nd';
                    else if (day % 10 == 3)
                      suffix = 'rd';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSelected
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.2)
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Text(
                          day.toString(),
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        day == 1 ? '1st of the month (Default)' : '$day$suffix',
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        ref
                            .read(userProvider.notifier)
                            .updatePreference('cycleStartDate', day);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccentPicker(
    BuildContext context,
    WidgetRef ref,
    String currentAccent,
  ) {
    final accents = [
      {'name': 'Deep Purple', 'color': Colors.deepPurpleAccent},
      {'name': 'Emerald Green', 'color': Colors.teal},
      {'name': 'Midnight Blue', 'color': const Color(0xFF191970)},
      {'name': 'Ruby Red', 'color': Colors.redAccent},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Theme Accent',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            ...accents.map((accent) {
              final isSelected = currentAccent == accent['name'];
              final color = accent['color'] as Color;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color,
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
                title: Text(
                  accent['name'] as String,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  ref
                      .read(userProvider.notifier)
                      .updatePreference('themeAccent', accent['name']);
                  Navigator.pop(context);
                },
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showManageCategories(
    BuildContext context,
    WidgetRef ref,
    UserModel? user,
  ) {
    if (user == null) return;
    final categories = user.customCategories;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Manage Categories',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cat['type'] == 'expense'
                          ? Colors.redAccent.withOpacity(0.2)
                          : Colors.greenAccent.withOpacity(0.2),
                      child: Icon(
                        Icons.category,
                        color: cat['type'] == 'expense'
                            ? Colors.redAccent
                            : Colors.green,
                      ),
                    ),
                    title: Text(
                      cat['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${cat['type'].toString().toUpperCase()} • Limit: ${user.preferences['currency'] ?? '₹'}${cat['limit']}',
                    ),
                    trailing: const Icon(
                      Icons.edit,
                      size: 20,
                      color: Colors.grey,
                    ),
                    onTap: () =>
                        _showEditCategory(context, ref, user, index, cat),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddCategory(context, ref, user),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'New Category',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategory(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
    int index,
    Map<String, dynamic> cat,
  ) {
    final nameCtrl = TextEditingController(text: cat['name']);
    final limitCtrl = TextEditingController(text: cat['limit'].toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Category',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (cat['type'] == 'expense')
              TextField(
                controller: limitCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Monthly Limit',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final cats = List<Map<String, dynamic>>.from(
                        user.customCategories,
                      );
                      cats.removeAt(index);
                      ref
                          .read(userProvider.notifier)
                          .updatePreference('customCategories', cats);
                      Navigator.pop(context);
                      Navigator.pop(context); // close manager to refresh
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    child: const Text(
                      'DELETE',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final cats = List<Map<String, dynamic>>.from(
                        user.customCategories,
                      );
                      cats[index] = {
                        'name': nameCtrl.text.trim(),
                        'limit': double.tryParse(limitCtrl.text.trim()) ?? 0.0,
                        'type': cat['type'],
                      };
                      ref
                          .read(userProvider.notifier)
                          .updatePreference('customCategories', cats);
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: const Text(
                      'SAVE',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showAddCategory(BuildContext context, WidgetRef ref, UserModel user) {
    final nameCtrl = TextEditingController();
    final limitCtrl = TextEditingController();
    String type = 'expense';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New Category',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Expense'),
                      selected: type == 'expense',
                      onSelected: (_) => setStateSB(() => type = 'expense'),
                      selectedColor: Colors.redAccent.withOpacity(0.3),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Income'),
                      selected: type == 'income',
                      onSelected: (_) => setStateSB(() => type = 'income'),
                      selectedColor: Colors.greenAccent.withOpacity(0.3),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                if (type == 'expense')
                  TextField(
                    controller: limitCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Monthly Limit',
                      border: OutlineInputBorder(),
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty) return;
                      final cats = List<Map<String, dynamic>>.from(
                        user.customCategories,
                      );
                      cats.add({
                        'name': nameCtrl.text.trim(),
                        'limit': double.tryParse(limitCtrl.text.trim()) ?? 0.0,
                        'type': type,
                      });
                      ref
                          .read(userProvider.notifier)
                          .updatePreference('customCategories', cats);
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: const Text(
                      'ADD CATEGORY',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to end your current session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(userProvider.notifier).logout();
      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(RouteNames.login, (route) => false);
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing:
            trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
