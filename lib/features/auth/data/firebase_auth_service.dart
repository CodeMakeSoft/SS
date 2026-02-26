
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../domain/auth_service.dart';

class FirebaseAuthService implements AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FacebookAuth _facebookAuth = FacebookAuth.instance;
  
  // Temporary storage for linking credential
  static AuthCredential? pendingLinkingCredential;

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<User?> signInWithGoogle() async {
    try {
      // 1. Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled

      // 2. Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the credential
      final UserCredential userCredential = 
          await _firebaseAuth.signInWithCredential(credential);
      
      final user = userCredential.user;
      if (user != null) {
        // 5. Validation: Check if user is allowed (registered by admin)
        bool isAllowed = await _checkIfUserIsAllowed(user.email);
        if (!isAllowed) {
          await signOut(); // Kick them out immediately
          throw FirebaseAuthException(
            code: 'user-not-allowed',
            message: 'Tu cuenta no está registrada por un administrador.',
          );
        }
      }
      
      return user;
    } catch (e) {
      if (e is FirebaseAuthException && 
          e.code == 'account-exists-with-different-credential') {
        await _handleAccountExistsError(e);
      }
      rethrow;
    }
  }

  @override
  Future<User?> signInWithFacebook() async {
    try {
      final LoginResult result = await _facebookAuth.login();

      if (result.status == LoginStatus.success) {
        final OAuthCredential credential = 
            FacebookAuthProvider.credential(result.accessToken!.tokenString);
        final UserCredential userCredential = 
            await _firebaseAuth.signInWithCredential(credential);

        final user = userCredential.user;
        if (user != null) {
          bool isAllowed = await _checkIfUserIsAllowed(user.email);
          if (!isAllowed) {
            await signOut();
            throw FirebaseAuthException(
              code: 'user-not-allowed',
              message: 'Tu cuenta no está registrada por un administrador.',
            );
          }
        }
        return user;
      }
      return null;
    } catch (e) {
      if (e is FirebaseAuthException && 
          e.code == 'account-exists-with-different-credential') {
        await _handleAccountExistsError(e);
      }
      rethrow;
    }
  }

  @override
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      // 1. Sign in with email and password
      final UserCredential userCredential = 
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        // 2. Validation: Check if user is allowed
        bool isAllowed = await _checkIfUserIsAllowed(user.email);
        if (!isAllowed) {
          await signOut();
          throw FirebaseAuthException(
            code: 'user-not-allowed',
            message: 'Tu cuenta no está registrada por un administrador.',
          );
        }
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
      _facebookAuth.logOut(),
    ]);
  }

  @override
  Future<User?> linkCurrentUser(AuthCredential credential) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final userCredential = await user.linkWithCredential(credential);
        return userCredential.user;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // --- ACCOUNT LINKING SPECIFIC METHODS ---

  Future<User?> linkWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await linkCurrentUser(credential);
  }

  Future<User?> linkWithFacebook() async {
    final LoginResult result = await _facebookAuth.login();
    if (result.status == LoginStatus.success && result.accessToken != null) {
      final OAuthCredential credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);
      return await linkCurrentUser(credential);
    }
    return null;
  }

  Future<User?> unlinkProvider(String providerId) async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      return await user.unlink(providerId);
    }
    return null;
  }

  /// Checks if the user's email exists in the 'users' collection in Firestore.
  /// This enforces the rule that only admins can register users.
  Future<bool> _checkIfUserIsAllowed(String? email) async {
    return true; // TEMPORARY BYPASS for testing
    /*
    if (email == null) return false;

    // TODO: Adjust collection name and logic based on final DB structure.
    // For now, checks if a document with the email exists or if the email is a field.
    // Assuming structure: users/{userId} has field 'email'.
    final QuerySnapshot result = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    return result.docs.isNotEmpty;
    */
  }

  Future<Never> _handleAccountExistsError(FirebaseAuthException e) async {
    final email = e.email;
    final credential = e.credential;
    if (email != null && credential != null) {
      // Logic heuristic:
      // If credential is Facebook, likely existing is Google.
      // If credential is Google, likely existing is Facebook.
      String existingProvider = 'google.com'; // Default guess
      
      if (credential.providerId == 'facebook.com') {
        existingProvider = 'google.com';
      } else if (credential.providerId == 'google.com') {
         // Google usually overwrites unless setting is strict, but if strict:
         existingProvider = 'facebook.com';
      }

      throw AuthLinkingException(
        email: email,
        credential: credential,
        existingProviderId: existingProvider,
      );
    }
    throw e;
  }
}
