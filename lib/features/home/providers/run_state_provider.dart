import 'package:flutter/material.dart';

class RunStateProvider extends ChangeNotifier {
  double _totalDistanceMeters = 0.0;
  double _currentSpeed = 0.0;
  bool _isTracking = false;

  // Getters para que las pantallas puedan leer los valores
  double get totalDistanceMeters => _totalDistanceMeters;
  double get currentSpeed => _currentSpeed;
  bool get isTracking => _isTracking;

  // Setters para actualizar los valores (y avisar a todas las pantallas)
  void updateStats({required double distance, required double speed}) {
    _totalDistanceMeters = distance;
    _currentSpeed = speed;
    notifyListeners(); // <--- ¡La magia! Avisa a la UI que debe redibujarse
  }

  void setTrackingStatus(bool status) {
    _isTracking = status;
    notifyListeners();
  }

  // Utilidades para mostrar en pantalla ya formateadas
  String get distanceFormatted => "${(_totalDistanceMeters / 1000).toStringAsFixed(2)} km";
  String get speedFormatted => "${(_currentSpeed * 3.6).toStringAsFixed(1)} km/h";
}
