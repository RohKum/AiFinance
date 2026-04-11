import 'package:aifin/core/db/database_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aifin/data/models/user_model.dart';
import 'package:aifin/core/services/auth_service.dart';

import 'package:aifin/core/services/firestore_service.dart';
import 'package:aifin/core/providers/theme_provider.dart';

final authServiceProvider = Provider((ref) => AuthService());
final firestoreServiceProvider = Provider((ref) => FirestoreService());

class UserNotifier extends Notifier<UserModel?> {
  @override
  UserModel? build() {
    // Listen to Firebase Auth state changes and persist automatically!
    final auth = ref.read(authServiceProvider);

    // Automatically trigger UI updates for token or auth state changes
    final authSubscription = auth.authStateChanges.listen((sessionUser) async {
      if (sessionUser == null) {
        state = null;
      } else {
        // Fetch custom data like preferences from Firestore to merge with the session
        final firestore = ref.read(firestoreServiceProvider);
        final userDoc = await firestore.getUserDoc(sessionUser.id);
        
        if (userDoc != null && userDoc['preferences'] != null) {
           final fetchedPrefs = Map<String, dynamic>.from(userDoc['preferences']);
           state = sessionUser.copyWith(preferences: fetchedPrefs);
           
           if (fetchedPrefs.containsKey('theme')) {
             ref.read(themeProvider.notifier).updateTheme(fetchedPrefs['theme'] as String);
           }
           if (fetchedPrefs.containsKey('themeAccent')) {
             ref.read(themeProvider.notifier).updateAccent(fetchedPrefs['themeAccent'] as String);
           }
        } else {
           state = sessionUser;
           await syncUserToCloud(); // Save the new default user metadata
        }
      }
    });

    // Clean up subscription if the provider is disposed (though Notifier usually stays)
    ref.onDispose(() => authSubscription.cancel());

    // Synchronous initial check to avoid flash of login screen
    return auth.syncGetUser();
  }

  Future<void> login(String email, String password) async {
    final auth = ref.read(authServiceProvider);
    await auth.loginWithEmail(email, password);
  }

  Future<void> loginWithGoogle() async {
    final auth = ref.read(authServiceProvider);
    await auth.signInWithGoogle();
  }

  Future<void> signUp(String username, String email, String password) async {
    final auth = ref.read(authServiceProvider);
    await auth.signUpWithEmail(username, email, password);
  }

  Future<void> logout() async {
    final auth = ref.read(authServiceProvider);
    await auth.logout();
    state = null;

    // CRITICAL: Wipe local user cache to prevent the next logged-in user
    // from seeing the previous user's balance!
    await DatabaseHelper.instance.clearAllTransactions();
  }

  Future<void> updateName(String newName) async {
    if (state != null) {
      state = state!.copyWith(username: newName);
      await syncUserToCloud();
    }
  }

  Future<void> updatePreference(String key, dynamic value) async {
    if (state != null) {
      if (key == 'theme') {
        ref.read(themeProvider.notifier).updateTheme(value as String);
      } else if (key == 'themeAccent') {
        ref.read(themeProvider.notifier).updateAccent(value as String);
      }
      
      final updatedPrefs = Map<String, dynamic>.from(state!.preferences);
      updatedPrefs[key] = value;
      state = state!.copyWith(preferences: updatedPrefs);
      await syncUserToCloud();
    }
  }

  Future<void> syncUserToCloud() async {
    if (state != null) {
      await ref.read(firestoreServiceProvider).saveUser(state!);
    }
  }
}

// Global provider for the user
final userProvider = NotifierProvider<UserNotifier, UserModel?>(() {
  return UserNotifier();
});

extension CategoryExtension on UserModel {
  List<Map<String, dynamic>> get customCategories {
    if (preferences['customCategories'] != null) {
      final list = preferences['customCategories'] as List;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    
    // Fallback to rich default categories if not configured in cloud yet
    return [
      {'name': 'Food & Dining', 'limit': 15000.0, 'type': 'expense'},
      {'name': 'Transportation', 'limit': 5000.0, 'type': 'expense'},
      {'name': 'Shopping', 'limit': 10000.0, 'type': 'expense'},
      {'name': 'Entertainment', 'limit': 4000.0, 'type': 'expense'},
      {'name': 'Bills & Utilities', 'limit': 6000.0, 'type': 'expense'},
      {'name': 'Health', 'limit': 3000.0, 'type': 'expense'},
      {'name': 'Other', 'limit': 2000.0, 'type': 'expense'},
      {'name': 'Salary', 'limit': 0.0, 'type': 'income'},
      {'name': 'Freelance', 'limit': 0.0, 'type': 'income'},
      {'name': 'Investment', 'limit': 0.0, 'type': 'income'},
      {'name': 'Gift', 'limit': 0.0, 'type': 'income'},
    ];
  }
}
