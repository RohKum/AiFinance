import 'package:aifin/data/models/transaction_model.dart';
import 'package:aifin/core/constants/app_constants.dart';

class AIService {
  // Kept for compatibility so we don't break existing provider code,
  // but it is no longer used for network calls.

  AIService();

  Future<String> getFinancialAdvice(
    List<TransactionModel> transactions,
    String username,
  ) async {
    // Artificial delay to simulate "thinking" for visual effect
    await Future.delayed(const Duration(seconds: 1));

    if (transactions.isEmpty) {
      return "Hi $username! Start adding your transactions so I can analyze your habits.";
    }

    double totalIncome = 0;
    double totalExpense = 0;
    Map<String, double> categorySpending = {};

    for (var t in transactions) {
      if (t.type == TransactionType.income) {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
        categorySpending[t.category] =
            (categorySpending[t.category] ?? 0) + t.amount;
      }
    }

    final balance = totalIncome - totalExpense;
    final savingRate = totalIncome > 0
        ? ((balance / totalIncome) * 100).toStringAsFixed(1)
        : "0.0";

    // Find top spending category
    String topCategory = "None";
    double topCategoryAmount = 0;
    categorySpending.forEach((key, value) {
      if (value > topCategoryAmount) {
        topCategoryAmount = value;
        topCategory = key;
      }
    });

    final String balanceSummary = balance > 0
        ? "You have a **positive balance** of ${AppConstants.currencySymbol}${balance.toStringAsFixed(2)}. You're saving **$savingRate%** of your tracked income!"
        : "Your tracked expenses exceed your income by **${AppConstants.currencySymbol}${balance.abs().toStringAsFixed(2)}**. Watch your budget closely.";

    final String spendingInsight = topCategory != "None"
        ? "Your biggest spending category is **$topCategory**, making up **${AppConstants.currencySymbol}${topCategoryAmount.toStringAsFixed(2)}** of your expenses. Keep an eye on this area to maximize savings."
        : "You haven't logged any expenses yet, Great start!";

    final prompt =
        """
Hi **$username**, I am Aegis, your local AI financial advisor. Based on my analysis of your data:

### 1. Balance Status
$balanceSummary

### 2. Spending Analysis
$spendingInsight

### 3. Actionable Wealth Tips
* **The 50/30/20 Rule**: Aim to spend 50% on needs, 30% on wants, and save 20%.
* **Audit Subscriptions**: Review your recurring costs this month to catch unused services.
* **Emergency Fund**: Try setting up an automatic transfer on payday to build a cushion.
""";

    return prompt;
  }

  Future<Map<String, dynamic>?> parseTransactionFromVoice(String text) async {
    // Simulate parsing delay for user experience
    await Future.delayed(const Duration(milliseconds: 800));

    final lowerText = text.toLowerCase();

    // 1. Extract Amount using Regex
    final amountMatch = RegExp(r'\d+(\.\d+)?').firstMatch(lowerText);
    if (amountMatch == null) return null; // Couldn't find a number

    final amount = double.tryParse(amountMatch.group(0) ?? '0.0') ?? 0.0;

    // 2. Determine Type (Expense vs Income)
    String type = 'expense';
    if (lowerText.contains('earn') ||
        lowerText.contains('receiv') ||
        lowerText.contains('got') ||
        lowerText.contains('salary') ||
        lowerText.contains('income')) {
      type = 'income';
    }

    // 3. Determine Category based on keywords
    String category = 'Other';
    if (type == 'expense') {
      if (lowerText.contains('food') ||
          lowerText.contains('dinner') ||
          lowerText.contains('lunch') ||
          lowerText.contains('mcdonald') ||
          lowerText.contains('restaurant') ||
          lowerText.contains('grocery'))
        category = 'Food & Dining';
      else if (lowerText.contains('uber') ||
          lowerText.contains('cab') ||
          lowerText.contains('train') ||
          lowerText.contains('bus') ||
          lowerText.contains('transport') ||
          lowerText.contains('flight') ||
          lowerText.contains('ticket'))
        category = 'Transportation';
      else if (lowerText.contains('shop') ||
          lowerText.contains('bought') ||
          lowerText.contains('shoe') ||
          lowerText.contains('cloth') ||
          lowerText.contains('amazon'))
        category = 'Shopping';
      else if (lowerText.contains('movie') ||
          lowerText.contains('game') ||
          lowerText.contains('netflix') ||
          lowerText.contains('spotify') ||
          lowerText.contains('fun'))
        category = 'Entertainment';
      else if (lowerText.contains('bill') ||
          lowerText.contains('electric') ||
          lowerText.contains('water') ||
          lowerText.contains('internet') ||
          lowerText.contains('wifi') ||
          lowerText.contains('rent'))
        category = 'Bills & Utilities';
      else if (lowerText.contains('doctor') ||
          lowerText.contains('medicin') ||
          lowerText.contains('health') ||
          lowerText.contains('gym') ||
          lowerText.contains('pharmacy'))
        category = 'Health';
    } else {
      if (lowerText.contains('salary') || lowerText.contains('pay'))
        category = 'Salary';
      else if (lowerText.contains('freelance') || lowerText.contains('client'))
        category = 'Freelance';
      else if (lowerText.contains('invest') ||
          lowerText.contains('dividend') ||
          lowerText.contains('stock'))
        category = 'Investment';
      else if (lowerText.contains('gift') || lowerText.contains('birthday'))
        category = 'Gift';
    }

    // 4. Extract Noun/Subject for Title
    // Remove the amount from the text
    String nounPhrase = lowerText.replaceAll(amountMatch.group(0) ?? '', '');

    // Remove common stop words, verbs, prepositions, and currencies
    final stopWords = [
      'i',
      'my',
      'me',
      'we',
      'he',
      'she',
      'they',
      'it',
      'spent',
      'paid',
      'bought',
      'cost',
      'gave',
      'sent',
      'spend',
      'pay',
      'buy',
      'earned',
      'received',
      'got',
      'made',
      'took',
      'earn',
      'receive',
      'get',
      'make',
      'on',
      'for',
      'at',
      'to',
      'in',
      'of',
      'with',
      'about',
      'from',
      'a',
      'an',
      'the',
      'some',
      'any',
      'this',
      'that',
      'rupees',
      'rupee',
      'rs',
      'inr',
      'dollars',
      'dollar',
      'bucks',
      'cents',
      'euro',
    ];

    final words = nounPhrase.split(RegExp(r'\s+'));
    final filteredWords = words.where((w) {
      final cleanWord = w.replaceAll(RegExp(r'[^a-z]'), '');
      return cleanWord.isNotEmpty && !stopWords.contains(cleanWord);
    }).toList();

    String title = filteredWords.join(' ');

    if (title.trim().isEmpty) {
      title = category; // Fallback to category name if everything was stripped
    } else {
      title = title[0].toUpperCase() + title.substring(1);
    }

    if (title.length > 30) {
      title = '${title.substring(0, 27)}...'; // Truncate long titles
    }

    return {
      "title": title,
      "amount": amount,
      "category": category,
      "type": type,
    };
  }
}
