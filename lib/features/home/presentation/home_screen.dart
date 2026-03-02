import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../data/local_database.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  // Default position: Mexico City (or user's country)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(19.4326, -99.1332),
    zoom: 14.4746,
  );

  bool _locationPermissionGranted = true;
  StreamSubscription<Position>? _positionStreamSubscription;
  final List<LatLng> _routePoints = [];
  double _totalDistanceMeters = 0.0;
  double _currentSpeed = 0.0;
  Set<Polyline> _polylines = {};
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _goToCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 17,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error obteniendo ubicación: $e");
    }
  }

  void _startTracking() {
    setState(() => _isTracking = true);

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 3,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) async {
      final newPoint = LatLng(position.latitude, position.longitude);
      if (_routePoints.isNotEmpty) {
        final lastPoint = _routePoints.last;
        // Calculamos la distancia entre el último punto y este nuevo:
        final distanceChunk = Geolocator.distanceBetween(
          lastPoint.latitude,
          lastPoint.longitude,
          position.latitude,
          position.longitude,
        );
        _totalDistanceMeters += distanceChunk; // Sumamos a nuestro total
      }
      _currentSpeed = position.speed;
      await LocalDatabase.instance.insertLocation(
        position.latitude, 
        position.longitude, 
        position.speed,
      );

      setState(() {
        _routePoints.add(newPoint);
        _polylines = {
          Polyline(
            polylineId: const PolylineId('runner_route'),
            color: Theme.of(context).colorScheme.primary,
            width: 6,
            points: _routePoints,
            jointType: JointType.round,
            endCap: Cap.roundCap,
          )
        };
      });
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLng(newPoint));
    });
  }

  // --- DETENER RASTREO (Al terminar la carrera o pausar) ---
  void _stopTracking() {
    setState(() => _isTracking = false);
    _positionStreamSubscription?.cancel();
  }
  
  @override
  void dispose() {  
    _stopTracking();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      // No AppBar, using custom header
      body: Stack(
        children: [
          // 1. MAP (Full Screen)
          GoogleMap(
            mapType: MapType.normal, // Or hybrid/dark if Tech theme requires
            initialCameraPosition: _initialPosition,
            myLocationEnabled: _locationPermissionGranted,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              if (_locationPermissionGranted) {
                _goToCurrentLocation();
              }
            },
            polylines: _polylines,
          ),

          // 2. TECH GLASS HEADER
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.9), // Dark Tech
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.satellite_alt,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "RASTREO ACTIVO",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        _isTracking 
                          ? "${(_totalDistanceMeters / 1000).toStringAsFixed(2)} km  |  ${(_currentSpeed * 3.6).toStringAsFixed(1)} km/h"
                          : "Señal GPS Estable",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8), 
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Courier', // Un toque de cuentakilómetros
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Optional: Simple compass or connection icon
                  Icon(
                    Icons.wifi,
                    color: Colors.white.withOpacity(0.5),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          // 3. custom FAB for location (Higher up to avoid BottomBar)
          Positioned(
            bottom: 160, // Adjusted to clear the Custom Bottom Bar comfortably
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                if (_isTracking) {
                  _stopTracking();
                } else {
                  _startTracking();
                }
              },
              backgroundColor: _isTracking ? Colors.red : const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              elevation: 4,
              child: Icon(_isTracking ? Icons.stop : Icons.play_arrow), // Círculo de poder
            ),
          ),
        ],
      ),
    );
  }
}
