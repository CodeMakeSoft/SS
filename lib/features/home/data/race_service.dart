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
        .where('status', isEqualTo: 'finished') 
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
}
