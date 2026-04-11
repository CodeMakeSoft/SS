import 'package:cloud_firestore/cloud_firestore.dart';

class RaceModel {
  final String raceId;
  final String name;
  final String status; // 'upcoming', 'ongoing', 'finished'
  final DateTime date;
  final String? description;
  final String creatorUid;
  final String currentWave;
  final List<String> tags;
  final String? estimatedDuration;
  final DateTime? startTime;
  final DateTime? endTime;

  final List<String> participants;

  RaceModel({
    required this.raceId,
    required this.name,
    required this.status,
    required this.date,
    this.description,
    required this.creatorUid,
    this.currentWave = 'general',
    this.tags = const [],
    this.estimatedDuration,
    this.startTime,
    this.endTime,
    this.participants = const [],
  });

  factory RaceModel.fromMap(Map<String, dynamic> data, String documentId) {
    return RaceModel(
      raceId: documentId,
      name: data['name'] ?? 'Carrera sin nombre',
      status: data['status'] ?? 'upcoming',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: data['description'],
      creatorUid: data['creatorUid'] ?? '',
      currentWave: data['currentWave'] ?? 'general',
      tags: List<String>.from(data['tags'] ?? []),
      estimatedDuration: data['estimatedDuration'],
      startTime: (data['startTime'] as Timestamp?)?.toDate(),
      endTime: (data['endTime'] as Timestamp?)?.toDate(),
      participants: List<String>.from(data['participants'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'status': status,
      'date': date,
      'description': description,
      'creatorUid': creatorUid,
      'currentWave': currentWave,
      'tags': tags,
      'estimatedDuration': estimatedDuration,
      'startTime': startTime,
      'endTime': endTime,
      'participants': participants,
    };
  }
}
