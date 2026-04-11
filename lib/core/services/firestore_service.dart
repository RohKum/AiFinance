import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aifin/data/models/transaction_model.dart';
import 'package:aifin/data/models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Scoped Rule: Users can ONLY see and edit their own data!
  CollectionReference _transactions(String userId) {
    return _firestore.collection('users').doc(userId).collection('transactions');
  }

  // Update user profile metadata (preferences, name, etc.)
  Future<void> saveUser(UserModel user) async {
    await _firestore.collection('users').doc(user.id).set({
      'username': user.username,
      'email': user.email,
      'preferences': user.preferences,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveTransaction(String userId, TransactionModel transaction) async {
    await _transactions(userId).doc(transaction.id).set(transaction.toMap());
  }

  Future<void> deleteTransaction(String userId, String transactionId) async {
    await _transactions(userId).doc(transactionId).delete();
  }

  Stream<List<TransactionModel>> getTransactionsStream(String userId) {
    return _transactions(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return TransactionModel.fromMap(data);
      }).toList();
    });
  }
}
