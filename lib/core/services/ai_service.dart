import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:aifin/data/models/transaction_model.dart';
import 'package:aifin/core/constants/app_constants.dart';
import 'package:aifin/core/constants/api_constants.dart';

class AIService {
  final String _apiKey;
  late final GenerativeModel _model;

  AIService(this._apiKey) {
    _model = GenerativeModel(model: ApiConstants.geminiModel, apiKey: _apiKey);
  }

  Future<String> getFinancialAdvice(
    List<TransactionModel> transactions,
    String username,
  ) async {
    if (transactions.isEmpty) {
      return "Hi $username! Start adding your transactions so I can analyze your habits.";
    }

    final transactionJson = jsonEncode(
      transactions.take(30).map((t) => t.toMap()).toList(),
    );

    final prompt =
        """
    You are a professional financial advisor AI.
    User's name: $username
    Analyzing this Transaction JSON:
    $transactionJson

    Analyze these transactions (both income and expenses) and provide:
    1. A summary of their current balance status.
    2. Where most money is being spent.
    3. Three tips to grow wealth.
    Keep the tone premium and use markdown.
    """;

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? "Unable to generate insights.";
    } catch (e) {
      return "Error generating insights: $e.";
    }
  }

  Future<Map<String, dynamic>?> parseTransactionFromVoice(String text) async {
    final prompt =
        """
    You are a financial parsing assistant. 
    Task: Extract transaction details from this text: "$text"
    
    Rules:
    1. Extract: Title, Amount, Category, Type.
    2. Valid Categories for Expenses: ${AppConstants.expenseCategories.join(", ")}
    3. Valid Categories for Income: ${AppConstants.incomeCategories.join(", ")}
    4. Type must be exactly 'income' or 'expense'.
    5. Return ONLY a valid JSON object. No explanation.
    
    Example Input: "Spent 500 on dinner with friends"
    Example JSON: {"title": "Dinner with friends", "amount": 500.0, "category": "Food & Dining", "type": "expense"}

    Example Input: "Received 20000 salary for October"
    Example JSON: {"title": "Salary for October", "amount": 20000.0, "category": "Salary", "type": "income"}
    """;

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final jsonStr = response.text
          ?.replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      if (jsonStr == null) return null;
      return jsonDecode(jsonStr);
    } catch (e) {
      return null;
    }
  }
}
