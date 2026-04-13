import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aifin/core/services/ai_service.dart';
import 'package:aifin/core/providers/transaction_provider.dart';
import 'package:aifin/core/providers/user_provider.dart';

final aiServiceProvider = Provider((ref) => AIService());

final aiInsightsProvider = FutureProvider.autoDispose<String>((ref) async {
  final aiService = ref.read(aiServiceProvider);
  final transactions = ref.watch(transactionProvider).value ?? [];
  final user = ref.read(userProvider);

  if (user == null) return "Please log in to receive AI insights.";
  if (transactions.isEmpty) return "__EMPTY__";

  return await aiService.getFinancialAdvice(transactions, user.username);
});
