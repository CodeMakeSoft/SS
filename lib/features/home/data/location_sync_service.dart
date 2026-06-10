import 'local_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationSyncService {
  static final LocationSyncService instance = LocationSyncService(
    LocalDatabase.instance,
  );
  final LocalDatabase _localDatabase;

  LocationSyncService(this._localDatabase);

  Future<void> syncLocations(String raceId) async {
    final unsynced = await _localDatabase.getUnsyncedLocations();
    if (unsynced.isEmpty) return;
    try {
      final batch = FirebaseFirestore.instance.batch();
      final raceRef = FirebaseFirestore.instance
          .collection('races')
          .doc(raceId)
          .collection('tracking_points');
      for (var point in unsynced) {
        final newDoc = raceRef.doc();
        batch.set(newDoc, {
          'latitude': point['latitude'],
          'longitude': point['longitude'],
          'timestamp': point['timestamp'],
          'speed': point['speed'],
        });
      }
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final photoUrl = FirebaseAuth.instance.currentUser?.photoURL;
      final userName = FirebaseAuth.instance.currentUser?.displayName;

      if (userId != null) {
        final lastPoint = unsynced.last;
        final liveDoc = FirebaseFirestore.instance
            .collection('races')
            .doc(raceId)
            .collection('live_locations')
            .doc(userId);

        batch.set(liveDoc, {
          'latitude': lastPoint['latitude'],
          'longitude': lastPoint['longitude'],
          'speed': lastPoint['speed'],
          'photoUrl': photoUrl,
          'name': userName,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      final ids = unsynced.map((e) => e['id'] as int).toList();
      await _localDatabase.markAsSynced(ids);
      debugPrint("Sincronización exitosa: ${ids.length} puntos enviados.");
    } catch (e) {
      debugPrint('Error al sincronizar puntos: $e');
    }
  }
}
