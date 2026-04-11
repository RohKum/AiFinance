import 'package:aifin/core/db/database_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aifin/data/models/user_model.dart';
import 'package:aifin/core/services/auth_service.dart';

import 'package:aifin/core/services/firestore_service.dart';

final authServiceProvider = Provider((ref) => AuthService());
final firestoreServiceProvider = Provider((ref) => FirestoreService());

class UserNotifier extends Notifier<UserModel?> {
  @override
  UserModel? build() {
    // Listen to Firebase Auth state changes and persist automatically!
    final auth = ref.read(authServiceProvider);

    // Automatically trigger UI updates for token or auth state changes
    final authSubscription = auth.authStateChanges.listen((sessionUser) {
      // ✅ Update state even if null to trigger logout / login transitions
      if (state != sessionUser) {
        state = sessionUser;
      }
    });

    // Clean up subscription if the provider is disposed (though Notifier usually stays)
    ref.onDispose(() => authSubscription.cancel());

    // Synchronous initial check to avoid flash of login screen
    return auth.syncGetUser();
  }

  Future<void> login(String email, String password) async {
    final auth = ref.read(authServiceProvider);
    final user = await auth.loginWithEmail(email, password);
    state = user;
  }

  Future<void> loginWithGoogle() async {
    final auth = ref.read(authServiceProvider);
    final user = await auth.signInWithGoogle();
    state = user;
  }

  Future<void> signUp(String username, String email, String password) async {
    final auth = ref.read(authServiceProvider);
    final user = await auth.signUpWithEmail(username, email, password);
    state = user;

    await syncUserToCloud();
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
