import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:aifin/data/models/user_model.dart';
import 'package:aifin/core/constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // Firebase Real backend signup endpoint
  Future<UserModel> signUpWithEmail(String username, String email, String password) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    final firebaseUser = userCredential.user!;
    await firebaseUser.updateDisplayName(username); 
    
    final token = await firebaseUser.getIdToken();
    
    return UserModel(
      id: firebaseUser.uid,
      username: username,
      email: firebaseUser.email ?? email,
      jwtToken: token,
      createdAt: firebaseUser.metadata.creationTime,
      preferences: {'currency': AppConstants.currencySymbol, 'theme': 'light'},
    );
  }

  // Firebase Real backend login endpoint
  Future<UserModel> loginWithEmail(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    final firebaseUser = userCredential.user!;
    final token = await firebaseUser.getIdToken();
    
    return UserModel(
      id: firebaseUser.uid,
      username: firebaseUser.displayName ?? email.split('@')[0],
      email: firebaseUser.email ?? email,
      jwtToken: token,
      createdAt: firebaseUser.metadata.creationTime,
      preferences: {'currency': AppConstants.currencySymbol, 'theme': 'light'},
    );
  }

  // Firebase Google Sign-In pipeline
  Future<UserModel> signInWithGoogle() async {
    // Escalate the request down to the Android Native Google layer
    final GoogleSignInAccount googleUser;
    
    try {
      googleUser = await _googleSignIn.authenticate();
    } catch (e) {
      throw Exception('Google Sign-In aborted by user or failed: $e');
    }
    
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    
    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    
    // Pass the Google OAuth tokens back into the pure Firebase pipeline
    final userCredential = await _auth.signInWithCredential(credential);
    final firebaseUser = userCredential.user!;
    final token = await firebaseUser.getIdToken();
    
    return UserModel(
      id: firebaseUser.uid,
      username: firebaseUser.displayName ?? googleUser.displayName ?? 'Google User',
      email: firebaseUser.email ?? googleUser.email,
      jwtToken: token,
      createdAt: firebaseUser.metadata.creationTime,
      preferences: {'currency': AppConstants.currencySymbol, 'theme': 'light'},
    );
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<UserModel?> getCachedUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      final token = await firebaseUser.getIdToken();
      return UserModel(
        id: firebaseUser.uid,
        username: firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'User',
        email: firebaseUser.email ?? '',
        jwtToken: token,
        createdAt: firebaseUser.metadata.creationTime,
        preferences: {'currency': AppConstants.currencySymbol, 'theme': 'light'},
      );
    }
    return null;
  }

  // Fast synchronous retrieve if Firebase has a live state stored locally
  UserModel? syncGetUser() {
    final user = _auth.currentUser;
    if (user != null) {
      return UserModel(
        id: user.uid,
        username: user.displayName ?? user.email?.split('@')[0] ?? 'User',
        email: user.email ?? '',
        jwtToken: '',
        createdAt: user.metadata.creationTime,
        preferences: {'currency': AppConstants.currencySymbol, 'theme': 'light'},
      );
    }
    return null;
  }

  // Real-time Auth State Stream for persistent login tracking
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      final token = await firebaseUser.getIdToken();
      return UserModel(
        id: firebaseUser.uid,
        username: firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'User',
        email: firebaseUser.email ?? '',
        jwtToken: token,
        createdAt: firebaseUser.metadata.creationTime,
        preferences: {'currency': AppConstants.currencySymbol, 'theme': 'light'},
      );
    });
  }

  Future<void> updateDisplayName(String newName) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(newName);
    }
  }
}
