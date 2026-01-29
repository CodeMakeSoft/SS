import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthService {
  Stream<User?> get authStateChanges;
  User? get currentUser;
  
  Future<User?> signInWithGoogle();
  Future<User?> signInWithFacebook();
  Future<User?> signInWithEmailAndPassword(String email, String password);
  Future<void> signOut();
  Future<User?> linkCurrentUser(AuthCredential credential);
}

class AuthLinkingException implements Exception {
  final String email;
  final AuthCredential credential;
  final String existingProviderId;

  AuthLinkingException({
    required this.email,
    required this.credential,
    required this.existingProviderId,
  });
}
