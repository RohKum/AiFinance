import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aifin/data/models/transaction_model.dart';
import 'package:aifin/core/db/database_helper.dart';
import 'package:aifin/core/services/firestore_service.dart';
import 'package:aifin/core/providers/user_provider.dart';

final firestoreServiceProvider = Provider((ref) => FirestoreService());

// Reactive Cloud Stream that watches the user session
final cloudTransactionProvider = StreamProvider<List<TransactionModel>>((ref) {
  final user = ref.watch(userProvider);
  if (user == null) return Stream.value([]);

  final stream = ref
      .watch(firestoreServiceProvider)
      .getTransactionsStream(user.id);

  // ⚡ Sync Cloud data into Local SQLite on-the-fly!
  final subscription = stream.listen((transactions) async {
    for (var t in transactions) {
      await DatabaseHelper.instance.insertTransaction(t);
    }
  });
  
  ref.onDispose(() {
    subscription.cancel();
  });

  return stream;
});

class TransactionNotifier extends AsyncNotifier<List<TransactionModel>> {
  @override
  Future<List<TransactionModel>> build() async {
    // 1. Initial Load from fast local DB (Available instantly! offline friendly)
    final localTransactions = await DatabaseHelper.instance
        .getAllTransactions();

    // 2. Watch the cloud stream effortlessly!
    final cloudTransactions = ref.watch(cloudTransactionProvider);

    // 3. Source of Truth logic
    return cloudTransactions.when(
      data: (cloudData) {
        // If we have cloud data, it's the ultimate truth
        return cloudData.isNotEmpty ? cloudData : localTransactions;
      },
      loading: () =>
          localTransactions, // Fallback to local while cloud is fetching
      error: (_, __) => localTransactions, // Offline fallback
    );
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    // 1. Optimistic UI update (Instant feedback & prevent async duplication)
    final current = state.value ?? [];
    // Only add if it doesn't already exist to be safe against double-taps
    if (!current.any((t) => t.id == transaction.id)) {
      state = AsyncValue.data([transaction, ...current]);
    }

    // 2. Local Write
    await DatabaseHelper.instance.insertTransaction(transaction);

    // 3. Cloud Sync (Background)
    final user = ref.read(userProvider);
    if (user != null) {
      await ref
          .read(firestoreServiceProvider)
          .saveTransaction(user.id, transaction);
    }
  }

  Future<void> deleteTransaction(String id) async {
    // 1. Optimistic UI update
    state = AsyncValue.data(
      state.value?.where((t) => t.id != id).toList() ?? [],
    );

    // 2. Local Clean
    await DatabaseHelper.instance.deleteTransaction(id);

    // 3. Cloud Sync
    final user = ref.read(userProvider);
    if (user != null) {
      await ref.read(firestoreServiceProvider).deleteTransaction(user.id, id);
    }
  }
}

final transactionProvider =
    AsyncNotifierProvider<TransactionNotifier, List<TransactionModel>>(() {
      return TransactionNotifier();
    });
