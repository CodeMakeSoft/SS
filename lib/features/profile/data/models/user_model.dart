import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String role;
  final bool isNameCustomized;
  final String? activeBibNumber;
  final String? activeRaceId;
  final List<String> friends;
  final List<String> history;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.role,
    this.isNameCustomized = false,
    this.activeBibNumber,
    this.activeRaceId,
    this.friends = const [],
    this.history = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      displayName: data['displayName'] ?? 'Usuario',
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      isNameCustomized: data['isNameCustomized'] ?? false,
      activeBibNumber: data['activeBibNumber'],
      activeRaceId: data['activeRaceId'],
      friends:List<String>.from(data['friends'] ?? []),
      history:List<String>.from(data['history'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'role': role,
      'isNameCustomized': isNameCustomized,
      'activeBibNumber': activeBibNumber,
      'activeRaceId': activeRaceId,
      'friends': friends,
      'history': history,
    };
  }
}