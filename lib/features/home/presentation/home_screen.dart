
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  
  // Default position: Mexico City (or user's country)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(19.4326, -99.1332), 
    zoom: 14.4746,
  );

  bool _locationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor habilita la ubicación')));
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permiso de ubicación denegado')));
        }
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        showDialog(
          context: context, 
          builder: (context) => AlertDialog(
            title: const Text('Permiso necesario'),
            content: const Text('Para mostrar tu ubicación, habilita el permiso en la configuración de la app.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Geolocator.openAppSettings();
                }, 
                child: const Text('Ir a Configuración')
              ),
            ],
          )
        );
      }
      return;
    }

    setState(() {
      _locationPermissionGranted = true;
    });

    _goToCurrentLocation();
  }

  Future<void> _goToCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 17,
        ),
      ));
    } catch (e) {
      debugPrint("Error obteniendo ubicación: $e");
    }
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
                  )
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
                     child: const Icon(Icons.satellite_alt, color: Colors.green, size: 20),
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
                         "Señal GPS Estable",
                         style: TextStyle(
                           color: Colors.white.withOpacity(0.6), 
                           fontSize: 10,
                         ),
                       ),
                     ],
                   ),
                   const Spacer(),
                   // Optional: Simple compass or connection icon
                   Icon(Icons.wifi, color: Colors.white.withOpacity(0.5), size: 18),
                ],
              ),
            ),
          ),
          
          // 3. custom FAB for location (Higher up to avoid BottomBar)
          Positioned(
            bottom: 160, // Adjusted to clear the Custom Bottom Bar comfortably
            right: 20,
            child: FloatingActionButton(
              onPressed: _goToCurrentLocation,
              backgroundColor: const Color(0xFF0F172A), // Matches header
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Icon(Icons.gps_fixed),
            ),
          ),
        ],
      ),
    );
  }
}
