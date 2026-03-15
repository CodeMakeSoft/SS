import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartsync/features/profile/data/models/user_model.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _userData;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  UserModel? get userData => _userData;

  UserProvider() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        _userData = null;
        _userSubscription?.cancel();
        notifyListeners();
      } else {
        _startUserStream(user.uid);
      }
    });
  }

  void _startUserStream(String uid) {
    _userSubscription?.cancel();
    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        _userData = UserModel.fromMap(data, snapshot.id);
        
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null && currentUser.displayName != null && currentUser.displayName!.isNotEmpty) {
          bool alreadyCustomized = data['isNameCustomized'] ?? false;
          String dbName = data['displayName'] ?? '';

          if (!alreadyCustomized && (dbName == 'Usuario' || dbName.trim().isEmpty)) {
            FirebaseFirestore.instance.collection('users').doc(uid).update({
              'displayName': currentUser.displayName,
            });
          }
        }
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
