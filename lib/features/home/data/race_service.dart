import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/race_model.dart';

class RaceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern
  static final RaceService instance = RaceService._internal();
  RaceService._internal();

  Future<void> createRace(RaceModel race) async {
    await _firestore.collection('races').doc(race.raceId).set(race.toMap());
  }

  Future<void> updateRace(RaceModel race) async {
    await _firestore.collection('races').doc(race.raceId).update(race.toMap());
  }

    Stream<List<RaceModel>> getActiveRaces() {
    return _firestore
        .collection('races')
        .where('status', whereIn: ['upcoming', 'ongoing'])
        .snapshots()
        .map((snapshot) {
          final now = DateTime.now();
          List<RaceModel> activeRaces = [];

          for (var doc in snapshot.docs) {
            final race = RaceModel.fromMap(doc.data(), doc.id);
            if (race.date.add(const Duration(hours: 24)).isBefore(now)) {
              updateRaceStatus(race.raceId, 'finished');              
            } else {
              activeRaces.add(race);
            }
          }
          
          return activeRaces;
        });
  }


  Stream<List<RaceModel>> getRaceHistory() {
    return _firestore
        .collection('races')
        .where('status', whereIn: ['finished', 'archived']) 
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RaceModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> updateRaceStatus(String raceId, String newStatus) async {
    await _firestore.collection('races').doc(raceId).update({
      'status': newStatus,
      if (newStatus == 'ongoing') 'startTime': FieldValue.serverTimestamp(),
      if (newStatus == 'finished') 'endTime': FieldValue.serverTimestamp(),
    });

    if (newStatus == 'finished') {
      try {
        final doc = await _firestore.collection('races').doc(raceId).get();
        if (doc.exists) {
          final data = doc.data()!;
          final List<dynamic> participants = data['participants'] ?? [];
          final List<dynamic> finishers = data['finishers'] ?? [];
          
          final Set<String> finishedUserIds = finishers.map((f) => f['userId'].toString()).toSet();
          final List<String> unfinishedUserIds = participants
              .map((p) => p.toString())
              .where((p) => !finishedUserIds.contains(p))
              .toList();
          
          if (unfinishedUserIds.isNotEmpty) {
            final List<Map<String, dynamic>> resultsToAdd = [];
            for (final userId in unfinishedUserIds) {
              final userDoc = await _firestore.collection('users').doc(userId).get();
              if (userDoc.exists) {
                final userData = userDoc.data()!;
                final displayName = userData['displayName'] ?? 'Runner';
                final photoUrl = userData['photoURL'] ?? '';
                final bibNumber = userData['activeBibNumber'];
                
                resultsToAdd.add({
                  'userId': userId,
                  'displayName': displayName,
                  'photoUrl': photoUrl,
                  'timeInSeconds': 0,
                  'isDisqualified': true, // DNF / DESC
                  'completedAt': Timestamp.now(),
                  if (bibNumber != null) 'bibNumber': bibNumber,
                });
              }
            }
            if (resultsToAdd.isNotEmpty) {
              await _firestore.collection('races').doc(raceId).update({
                'finishers': FieldValue.arrayUnion(resultsToAdd),
              });
            }
          }
        }
      } catch (e) {
        // En caso de error, continuar de forma segura
        debugPrint("Error guardando competidores no finalizados: $e");
      }
    }
  }

  Future<bool> isBibNumberTaken(String raceId, String bibNumber, {String? excludeUserId}) async {
    final query = await _firestore
        .collection('users')
        .where('activeRaceId', isEqualTo: raceId)
        .where('activeBibNumber', isEqualTo: bibNumber)
        .get();
        
    if (excludeUserId != null) {
      return query.docs.any((doc) => doc.id != excludeUserId);
    }
    return query.docs.isNotEmpty;
  }

  Future<void> linkUserToRace(String raceId, String userId, String bibNumber) async {
    final batch = _firestore.batch();
    
    batch.update(_firestore.collection('races').doc(raceId), {
      'participants': FieldValue.arrayUnion([userId]),
    });
    
    batch.update(_firestore.collection('users').doc(userId), {
      'activeRaceId': raceId,
      'activeBibNumber': bibNumber,
    });
    await batch.commit();
  }

  Future<void> unlinkUserFromRace(String raceId, String userId) async {
    final batch = _firestore.batch();
    
    batch.update(_firestore.collection('races').doc(raceId), {
      'participants': FieldValue.arrayRemove([userId]),
    });
    
    batch.update(_firestore.collection('users').doc(userId), {
      'activeRaceId': null,
      'activeBibNumber': null,
    });
    
    batch.delete(
      _firestore.collection('races').doc(raceId).collection('live_locations').doc(userId)
    );

    await batch.commit();
  }

  Future<void> sendGlobalAlert(String raceId, String type, String message, {int? countdownSeconds}) async {
    DateTime? targetTime;
    if (countdownSeconds != null) {
      targetTime = DateTime.now().add(Duration(seconds: countdownSeconds));
    }
    
    await _firestore.collection('races').doc(raceId).update({
      'alertType': type,
      'alertMessage': message,
      'alertTargetTime': targetTime != null ? Timestamp.fromDate(targetTime) : null,
    });
  }

  Future<void> clearGlobalAlert(String raceId) async {
    await _firestore.collection('races').doc(raceId).update({
      'alertType': FieldValue.delete(),
      'alertMessage': FieldValue.delete(),
      'alertTargetTime': FieldValue.delete(),
    });
  }

  Future<void> submitRaceResult(String raceId, String userId, String displayName, String photoUrl, int timeInSeconds, bool isDisqualified, String? bibNumber) async {
    final result = {
      'userId': userId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'timeInSeconds': timeInSeconds,
      'isDisqualified': isDisqualified,
      'completedAt': Timestamp.now(),
      if (bibNumber != null) 'bibNumber': bibNumber,
    };
    
    await _firestore.collection('races').doc(raceId).update({
      'finishers': FieldValue.arrayUnion([result]),
    });
  }

  Future<void> archiveRaceAndKeepPodium(RaceModel race) async {
    final batch = _firestore.batch();
    
    // 1. Obtener la carrera para saber los participantes y desvincularlos
    final doc = await _firestore.collection('races').doc(race.raceId).get();
    if (doc.exists) {
      final data = doc.data()!;
      final List<dynamic> participants = data['participants'] ?? [];
      for (final userId in participants) {
        batch.update(_firestore.collection('users').doc(userId.toString()), {
          'activeRaceId': null,
          'activeBibNumber': null,
        });
      }
    }

    // 2. Archivar la carrera
    batch.update(_firestore.collection('races').doc(race.raceId), {
      'status': 'archived',
      'participants': [],
      'alertType': FieldValue.delete(),
      'alertMessage': FieldValue.delete(),
      'alertTargetTime': FieldValue.delete(),
    });

    await batch.commit();
  }

  Future<void> deleteRace(String raceId) async {
    final batch = _firestore.batch();
    
    // 1. Obtener la carrera para saber los participantes
    final doc = await _firestore.collection('races').doc(raceId).get();
    if (doc.exists) {
      final data = doc.data()!;
      final List<dynamic> participants = data['participants'] ?? [];
      
      // 2. Desvincular a todos los participantes
      for (final userId in participants) {
        batch.update(_firestore.collection('users').doc(userId.toString()), {
          'activeRaceId': null,
          'activeBibNumber': null,
        });
        batch.delete(
          _firestore.collection('races').doc(raceId).collection('live_locations').doc(userId.toString())
        );
      }
    }
    
    // 3. Borrar el documento de la carrera
    batch.delete(_firestore.collection('races').doc(raceId));
    
    await batch.commit();
  }
}
