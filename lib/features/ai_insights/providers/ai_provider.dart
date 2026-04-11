import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aifin/core/services/ai_service.dart';
import 'package:aifin/core/providers/transaction_provider.dart';
import 'package:aifin/core/providers/user_provider.dart';
import 'package:aifin/core/constants/api_constants.dart';

final aiServiceProvider = Provider((ref) => AIService(ApiConstants.geminiApiKey));

final aiInsightsProvider = FutureProvider.autoDispose<String>((ref) async {
  final aiService = ref.read(aiServiceProvider);
  final transactions = ref.read(transactionProvider).value ?? [];
  final user = ref.read(userProvider);
  
  if (user == null) return "Please log in to receive AI insights.";
  if (transactions.isEmpty) return "I need at least one transaction to analyze.";
  
  return await aiService.getFinancialAdvice(transactions, user.username);
});
