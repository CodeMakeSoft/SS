import 'local_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LocationSyncService {
  final LocalDatabase _localDatabase;

  LocationSyncService(this._localDatabase);

  Future<void> syncLocations(String raceId) async {
    final unsynced = await _localDatabase.getUnsyncedLocations();
    if(unsynced.isEmpty) return;
    try {
      final batch = FirebaseFirestore.instance.batch();
      final raceRef = FirebaseFirestore.instance.collection('races').doc(raceId).collection('tracking_points');
      for(var point in unsynced) {
        final newDoc = raceRef.doc();
        batch.set(newDoc, {
          'latitude': point['latitude'],
          'longitude': point['longitude'],
          'timestamp': point['timestamp'],
          'speed': point['speed'],
          }
        );
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