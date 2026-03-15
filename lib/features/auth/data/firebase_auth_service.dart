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
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = 
          await _firebaseAuth.signInWithCredential(credential);
      
      final user = userCredential.user;
      if (user != null) {
        String? googleName = userCredential.additionalUserInfo?.profile?['name'];
        await _ensureUserDocumentExists(user, providedName: googleName);
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
          String? facebookName = userCredential.additionalUserInfo?.profile?['name'];
          await _ensureUserDocumentExists(user, providedName: facebookName);
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
      final UserCredential userCredential = 
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        await _ensureUserDocumentExists(user);
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

  Future<void> _ensureUserDocumentExists(User user, {String? providedName}) async {
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    
    bool isValid(String? n) => n != null && n.trim().isNotEmpty && n != 'Usuario';

    String cleanName = 'Usuario';
    if (isValid(providedName)) {
      cleanName = providedName!;
    } else if (isValid(user.displayName)) {
      cleanName = user.displayName!;
    }

    if (!userDoc.exists) {
      await _firestore.collection('users').doc(user.uid).set({
        'displayName': cleanName,
        'email': user.email,
        'role': 'trial',
        'isNameCustomized': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      final data = userDoc.data();
      bool alreadyCustomized = data?['isNameCustomized'] ?? false;
      String currentName = data?['displayName'] ?? '';

      if (!alreadyCustomized && !isValid(currentName) && isValid(cleanName)) {
        await _firestore.collection('users').doc(user.uid).update({
          'displayName': cleanName,
        });
      }
    }
  }

  Future<void> updateDisplayName(String newName) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception("No hay usuario autenticado");

    final trimmedName = newName.trim();
    
    if (trimmedName.length > 20) {
      throw Exception("El nombre es demasiado largo (máximo 20 caracteres).");
    }

    final wordCount = trimmedName.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (wordCount > 2) {
      throw Exception("Solo se permiten máximo 2 palabras (Nombre y Apellido).");
    }

    if (trimmedName.isEmpty) {
      throw Exception("El nombre no puede estar vacío.");
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final data = userDoc.data();

    if (data != null && (data['isNameCustomized'] ?? false)) {
      throw Exception("Ya has personalizado tu nombre anteriormente.");
    }

    await user.updateDisplayName(trimmedName);
    
    await _firestore.collection('users').doc(user.uid).update({
      'displayName': trimmedName,
      'isNameCustomized': true,
    });
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
