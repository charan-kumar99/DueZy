import 'package:firebase_auth/firebase_auth.dart';

// Handles anonymous authentication to scope user data.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user.
  User? get currentUser => _auth.currentUser;

  // Get current user's UID.
  String? get uid => _auth.currentUser?.uid;

  // Sign in anonymously, reusing active session if available.
  Future<User?> signInAnonymously() async {
    if (_auth.currentUser != null) {
      return _auth.currentUser;
    }
    try {
      final credential = await _auth.signInAnonymously();
      return credential.user;
    } catch (e) {
      return null;
    }
  }
}
