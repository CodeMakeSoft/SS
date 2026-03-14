import 'package:cloud_firestore/cloud_firestore.dart';

class RaceModel {
  final String raceId;
  final String status;
  final String currentWave;
  final DateTime? startTime;
  final DateTime? endTime;
  final Duration? duration;

  RaceModel({
    required this.raceId,
    required this.status,
    required this.currentWave,
    this.startTime,
    this.endTime,
    this.duration,
  });

  factory RaceModel.fromMap(Map<String, dynamic> data, String documentId) {
    return RaceModel(
      raceId: documentId,
      status: data['status'] ?? 'waiting',
      currentWave: data['currentWave'] ?? 'general',
      startTime: data['startTime'] != null ? (data['startTime'] as Timestamp).toDate() : null,
      endTime: data['endTime'] != null ? (data['endTime'] as Timestamp).toDate() : null,
      duration: data['duration'] != null ? Duration(milliseconds: data['duration']) : null,
    );
  }
}
