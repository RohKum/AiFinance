import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:aifin/core/constants/app_constants.dart';
import 'package:aifin/data/models/transaction_model.dart';
import 'package:aifin/core/providers/transaction_provider.dart';
import 'package:aifin/core/providers/user_provider.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Food & Dining';
  TransactionType _selectedType = TransactionType.expense;

  // Dynamic categories will be loaded from UserProvider in build()

  void _presentDatePicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );

    if (pickedDate != null) setState(() => _selectedDate = pickedDate);
  }

  void _submitData() {
    final amount = double.tryParse(_amountController.text);
    if (_titleController.text.isEmpty || amount == null || amount <= 0) return;

    final transaction = TransactionModel(
      id: const Uuid().v4(),
      title: _titleController.text,
      amount: amount,
      category: _selectedCategory,
      date: _selectedDate,
      type: _selectedType,
    );

    ref.read(transactionProvider.notifier).addTransaction(transaction);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final rawCategories = user?.customCategories ?? [];
    
    final typeString = _selectedType == TransactionType.expense ? 'expense' : 'income';
    // Use a LinkedHashSet keyed on trimmed name to eliminate true and near-duplicate strings
    final seen = <String>{};
    final categories = rawCategories
        .where((c) => c['type'] == typeString)
        .map((c) => (c['name'] as String).trim())
        .where((name) => seen.add(name))  // only adds if not already in set
        .toList();

    // Synchronously reset selection if current value is no longer valid
    final safeValue = categories.contains(_selectedCategory)
        ? _selectedCategory
        : (categories.isNotEmpty ? categories.first : null);
    if (safeValue != null && safeValue != _selectedCategory) {
      // Schedule for next frame to avoid setState-during-build error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedCategory = safeValue);
      });
    }

    final currencySymbol = user?.preferences['currency'] ?? AppConstants.currencySymbol;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_selectedType == TransactionType.expense ? 'New Expense' : 'New Income'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Type Selector
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Expense', style: TextStyle(fontWeight: FontWeight.bold))),
                    selected: _selectedType == TransactionType.expense,
                    onSelected: (v) => setState(() {
                       _selectedType = TransactionType.expense;
                    }),
                    selectedColor: Colors.redAccent.withOpacity(0.2),
                    backgroundColor: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Income', style: TextStyle(fontWeight: FontWeight.bold))),
                    selected: _selectedType == TransactionType.income,
                    onSelected: (v) => setState(() {
                       _selectedType = TransactionType.income;
                    }),
                    selectedColor: Colors.greenAccent.withOpacity(0.2),
                    backgroundColor: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Amount Input
            Center(
              child: Column(
                children: [
                  Text(
                    'How much?',
                    style: TextStyle(color: Colors.grey[600], fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  IntrinsicWidth(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _selectedType == TransactionType.expense ? Colors.redAccent : Colors.green,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '0.00',
                        prefixText: '$currencySymbol ',
                        prefixStyle: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: _selectedType == TransactionType.expense ? Colors.redAccent : Colors.green,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Form Container
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusCard),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Item Name
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'What is this for?',
                      prefixIcon: Icon(Icons.title, color: Theme.of(context).colorScheme.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Category Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: categories.contains(_selectedCategory) ? _selectedCategory : null,
                        isExpanded: true,
                        dropdownColor: Theme.of(context).cardColor,
                        icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.primary),
                        items: categories.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Row(
                              children: [
                                const Icon(Icons.category, size: 20, color: Colors.grey),
                                const SizedBox(width: 12),
                                Text(category),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedCategory = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date Picker
                  InkWell(
                    onTap: _presentDatePicker,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Spacer(),
                          const Icon(Icons.edit, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedType == TransactionType.expense ? Colors.redAccent : Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'SAVE',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
