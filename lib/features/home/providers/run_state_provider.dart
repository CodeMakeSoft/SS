import 'dart:async';
import 'package:flutter/material.dart';

class RunStateProvider extends ChangeNotifier {
  double _totalDistanceMeters = 0.0;
  double _currentSpeed = 0.0;
  bool _isTracking = false;
  int _durationInSeconds = 0;
  Timer? _timer;
  String? _lastFinishedRaceId;

  // Getters para que las pantallas puedan leer los valores
  double get totalDistanceMeters => _totalDistanceMeters;
  double get currentSpeed => _currentSpeed;
  bool get isTracking => _isTracking;
  int get durationInSeconds => _durationInSeconds;
  String? get lastFinishedRaceId => _lastFinishedRaceId;

  // Setters para actualizar los valores (y avisar a todas las pantallas)
  void setLastFinishedRaceId(String? id) {
    _lastFinishedRaceId = id;
    notifyListeners();
  }

  void updateStats({required double distance, required double speed}) {
    _totalDistanceMeters = distance;
    _currentSpeed = speed;
    notifyListeners(); 
  }

  void setTrackingStatus(bool status) {
    if (_isTracking == status) return;
    _isTracking = status;
    
    if (status) {
      _startTimer();
    } else {
      _stopTimer();
    }
    notifyListeners();
  }

  void reset() {
    _totalDistanceMeters = 0;
    _currentSpeed = 0;
    _durationInSeconds = 0;
    _stopTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _durationInSeconds++;
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // Utilidades para mostrar en pantalla ya formateadas
  String get distanceFormatted => "${(_totalDistanceMeters / 1000).toStringAsFixed(2)} km";
  String get speedFormatted => "${(_currentSpeed * 3.6).toStringAsFixed(1)} km/h";
  
  String get timeFormatted {
    int h = _durationInSeconds ~/ 3600;
    int m = (_durationInSeconds % 3600) ~/ 60;
    int s = _durationInSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
