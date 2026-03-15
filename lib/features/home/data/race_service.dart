import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/race_model.dart';

class RaceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern
  static final RaceService instance = RaceService._internal();
  RaceService._internal();

  /// Crea una nueva carrera en Firestore
  Future<void> createRace(RaceModel race) async {
    await _firestore.collection('races').doc(race.raceId).set(race.toMap());
  }

  /// Obtiene un stream de las carreras activas u próximas
  Stream<List<RaceModel>> getActiveRaces() {
    return _firestore
        .collection('races')
        .where('status', whereIn: ['upcoming', 'ongoing'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RaceModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Actualiza el estado de una carrera
  Future<void> updateRaceStatus(String raceId, String newStatus) async {
    await _firestore.collection('races').doc(raceId).update({
      'status': newStatus,
      if (newStatus == 'ongoing') 'startTime': FieldValue.serverTimestamp(),
      if (newStatus == 'finished') 'endTime': FieldValue.serverTimestamp(),
    });
  }
}
