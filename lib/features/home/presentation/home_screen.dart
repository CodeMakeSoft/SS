import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartsync/features/home/data/location_sync_service.dart';
import '../data/local_database.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/run_state_provider.dart';
import 'package:widget_to_marker/widget_to_marker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/race_model.dart';
import '../data/race_service.dart';
import '../../../core/services/notification_service.dart';

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
    zoom: 16,
  );

  bool _locationPermissionGranted = true;
  StreamSubscription<Position>? _positionStreamSubscription;
  final List<LatLng> _routePoints = [];
  double _totalDistanceMeters = 0.0;
  double _currentSpeed = 0.0;
  Set<Polyline> _polylines = {};
  bool _isTracking = false;
  Set<Marker> _markers = {};
  BitmapDescriptor? _customMarkerIcon;
  String _activeRaceName = "Sin carrera activa";
  String _activeRaceStatus = "upcoming";
  
  // Global Alert State
  String? _globalAlertType;
  String? _globalAlertMessage;
  DateTime? _globalAlertTargetTime;
  String? _currentRaceId;
  StreamSubscription<DocumentSnapshot>? _raceDataSubscription;
  StreamSubscription<QuerySnapshot>? _liveLocationsSubscription;
  final Map<String, BitmapDescriptor> _otherUsersMarkersIcons = {};
  
  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    if (_customMarkerIcon == null) {
      final String? myPhotoUrl = FirebaseAuth.instance.currentUser?.photoURL;
      _customMarkerIcon = await const RunnerMarkerWidget(
        photoUrl: null,
      ).toBitmapDescriptor(
        logicalSize: const Size(60, 60), 
        imageSize: const Size(60, 60),
      );
      
      RunnerMarkerWidget(photoUrl: myPhotoUrl).toBitmapDescriptor(
        logicalSize: const Size(60, 60), 
        imageSize: const Size(60, 60),
      ).then((icon) => _customMarkerIcon = icon);
    }
  }

  void _fetchActiveRaceData(String raceId) {
    _raceDataSubscription?.cancel();
    _raceDataSubscription = FirebaseFirestore.instance.collection('races').doc(raceId).snapshots().listen((doc) {
      if (doc.exists && mounted) {
        final race = RaceModel.fromMap(doc.data()!, doc.id);
        setState(() {
          _activeRaceName = race.name;
          _activeRaceStatus = race.status;
          
          final previousAlert = _globalAlertType;
          
          _globalAlertType = race.alertType;
          _globalAlertMessage = race.alertMessage;
          _globalAlertTargetTime = race.alertTargetTime;
          
          if (_globalAlertType != null && _globalAlertType != previousAlert) {
            NotificationService.instance.showNotification(
              id: 0,
              title: "Aviso de Carrera",
              body: _globalAlertMessage ?? "Alerta importante",
            );
          }
          
          _polylines.removeWhere((p) => p.polylineId.value == 'official_race_route');
          _markers.removeWhere((m) => m.markerId.value == 'start_checkpoint' || m.markerId.value == 'end_checkpoint');
        });
        _drawRaceRoute(race);
      }
    });
    _startLiveLocationsStream(raceId);
  }

  void _startLiveLocationsStream(String raceId) {
    _liveLocationsSubscription?.cancel();
    _liveLocationsSubscription = FirebaseFirestore.instance
        .collection('races')
        .doc(raceId)
        .collection('live_locations')
        .snapshots()
        .listen((snapshot) async {
      final String? myUid = FirebaseAuth.instance.currentUser?.uid;
      
      for (var change in snapshot.docChanges) {
        final doc = change.doc;
        if (doc.id == myUid) continue; // No dibujarnos a nosotros mismos dos veces
        
        if (change.type == DocumentChangeType.removed) {
          if (mounted) {
            setState(() {
              _markers.removeWhere((m) => m.markerId.value == 'runner_${doc.id}');
              _otherUsersMarkersIcons.remove(doc.id);
            });
          }
          continue;
        }

        final data = doc.data();
        if (data == null) continue;

        final lat = data['latitude'] as double?;
        final lng = data['longitude'] as double?;
        final photoUrl = data['photoUrl'] as String?;
        
        if (lat == null || lng == null) continue;
        
        if (!_otherUsersMarkersIcons.containsKey(doc.id)) {
           try {
             final icon = await RunnerMarkerWidget(photoUrl: photoUrl).toBitmapDescriptor(
                logicalSize: const Size(60, 60), 
                imageSize: const Size(60, 60),
             );
             _otherUsersMarkersIcons[doc.id] = icon;
           } catch (e) {
             debugPrint("Error generating photo marker for ${doc.id}: $e");
             _otherUsersMarkersIcons[doc.id] = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
           }
        }

        if (mounted) {
          setState(() {
            _markers.removeWhere((m) => m.markerId.value == 'runner_${doc.id}');
            _markers.add(
              Marker(
                markerId: MarkerId('runner_${doc.id}'),
                position: LatLng(lat, lng),
                icon: _otherUsersMarkersIcons[doc.id]!,
                anchor: const Offset(0.5, 0.5),
              )
            );
          });
        }
      }
    });
  }

  void _drawRaceRoute(RaceModel race) {
    if (race.route.isEmpty) return;

    final List<LatLng> racePoints = race.route.map((p) => LatLng(p.latitude, p.longitude)).toList();

    final Polyline predefinedRoute = Polyline(
      polylineId: const PolylineId('official_race_route'),
      points: racePoints,
      color: Colors.orangeAccent.withOpacity(0.8),
      width: 6,
      patterns: [PatternItem.dash(20), PatternItem.gap(10)],
    );

    final Marker startCheckpoint = Marker(
      markerId: const MarkerId('start_checkpoint'),
      position: racePoints.first,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(title: 'Salida'),
    );

    final Marker endCheckpoint = Marker(
      markerId: const MarkerId('end_checkpoint'),
      position: racePoints.last,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(title: 'Meta'),
    );

    setState(() {
      _polylines.add(predefinedRoute);
      _markers.addAll([startCheckpoint, endCheckpoint]);
    });
  }

  Future<void> _updateMarker(LatLng point) async {
    if (mounted) {
      setState(() {
        _markers.removeWhere((m) => m.markerId.value == 'runner_me');
        _markers.add(
          Marker(
            markerId: const MarkerId('runner_me'),
            position: point,
            icon: _customMarkerIcon ?? BitmapDescriptor.defaultMarker,
            anchor: const Offset(0.5, 0.5),
          )
        );
      });
    }
  }

  Future<void> _goToCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      final point = LatLng(position.latitude, position.longitude);
      await _updateMarker(point);
      
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: point,
            zoom: 20,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error obteniendo ubicación: $e");
    }
  }

  void _startTracking(bool isTrialUser, String? raceId) async {
    setState(() => _isTracking = true);
      
    Provider.of<RunStateProvider>(
      context,
      listen: false,
    ).setTrackingStatus(true);

    final runStateProvider = Provider.of<RunStateProvider>(context, listen: false);

    try {
      Position? initialPos = await Geolocator.getLastKnownPosition();
      if (initialPos == null) {
        initialPos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      }
      await LocalDatabase.instance.insertLocation(initialPos.latitude, initialPos.longitude, initialPos.speed);
      if (raceId != null) {
        debugPrint("DEBUG Runner Map: Sincronizando ubicación inicial a Firebase...");
        LocationSyncService.instance.syncLocations(raceId);
      } else {
        debugPrint("DEBUG Runner Map: No se sincronizó la ubicación. isTrialUser=$isTrialUser, raceId=$raceId");
      }
    } catch (e) {
      debugPrint("Error obteniendo ubicacion inicial: $e");
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 1,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) async {
            final newPoint = LatLng(position.latitude, position.longitude);
            if (_routePoints.isNotEmpty) {
              final lastPoint = _routePoints.last;
              final distanceChunk = Geolocator.distanceBetween(
                lastPoint.latitude,
                lastPoint.longitude,
                position.latitude,
                position.longitude,
              );
              _totalDistanceMeters += distanceChunk;
            }
            _currentSpeed = position.speed;
            if (mounted) {
              runStateProvider.updateStats(distance: _totalDistanceMeters, speed: _currentSpeed);
            }
            await LocalDatabase.instance.insertLocation(
              position.latitude,
              position.longitude,
              position.speed,
            );
            if(raceId != null) {
              debugPrint("DEBUG Runner Map: Sincronizando ubicación en movimiento...");
              LocationSyncService.instance.syncLocations(raceId);
            }

            if (!mounted) return;
            setState(() {
              _routePoints.add(newPoint);
            });
            await _updateMarker(newPoint);
            
            final GoogleMapController controller = await _controller.future;
            controller.animateCamera(CameraUpdate.newLatLng(newPoint));
          },
        );
  }

  void _stopTracking() {
    if (!mounted) return;
    setState(() => _isTracking = false);
    Provider.of<RunStateProvider>(
      context,
      listen: false,
    ).setTrackingStatus(false);
    _positionStreamSubscription?.cancel();
  }

  @override
  void dispose() {
    _stopTracking();
    _raceDataSubscription?.cancel();
    _liveLocationsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.userData;
    bool isAdmin = user?.role == 'admin' || user?.role == 'super_admin' || user?.role == 'sudo';
    bool hasActiveRace = user?.activeRaceId != null;
    bool isTrial = user?.role == 'trial' || (!isAdmin && !hasActiveRace);

    if (user?.activeRaceId != _currentRaceId) {
      _currentRaceId = user?.activeRaceId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_currentRaceId != null) {
          _fetchActiveRaceData(_currentRaceId!);
          if (!_isTracking) {
             _startTracking(isTrial, _currentRaceId);
          }
        } else {
          if (mounted) {
            if (_isTracking) {
               _stopTracking();
            }
            setState(() {
              _activeRaceName = "CARRERA OFICIAL";
              _polylines.removeWhere((p) => p.polylineId.value == 'official_race_route');
              _markers.removeWhere((m) => m.markerId.value == 'start_checkpoint' || 
                                          m.markerId.value == 'end_checkpoint' || 
                                          (m.markerId.value.startsWith('runner_') && m.markerId.value != 'runner_me'));
              _liveLocationsSubscription?.cancel();
              _otherUsersMarkersIcons.clear();
            });
          }
        }
      });
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialPosition,
            myLocationEnabled: false,
            markers: _markers,
            polylines: _polylines,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              if (_locationPermissionGranted) {
                _goToCurrentLocation();
              }
            },
          ),

          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.9),
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
                      Text(
                        hasActiveRace ? _activeRaceName.toUpperCase() : "ENTRENAMIENTO LIBRE",
                        style: const TextStyle(
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
                          fontFamily: 'Courier', 
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (hasActiveRace)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.exit_to_app, color: Colors.redAccent, size: 24),
                      onPressed: () => _showLeaveRaceDialog(user!.activeRaceId!),
                    )
                  else
                    Icon(
                      Icons.wifi,
                      color: Colors.white.withOpacity(0.5),
                      size: 18,
                    ),
                ],
              ),
            ),
          ),
          
          if (_globalAlertType != null)
            _buildGlobalAlertOverlay(),
            
          if (!hasActiveRace)
            Positioned(
              bottom: 120,
              right: 20,
              child: FloatingActionButton(
                onPressed: () {
                  if (_isTracking) {
                    _showTrackingDialog(isTrial, user?.activeRaceId);
                  } else {
                    _showTrainingOptions(isTrial, user?.activeRaceId);
                  }
                },
                backgroundColor: _isTracking ? Colors.red : Colors.blueAccent,
                foregroundColor: Colors.white,
                elevation: 8,
                child: Icon(_isTracking ? Icons.stop : Icons.directions_run, size: 30),
              ),
            )
          else if (user?.activeBibNumber != null)
            Positioned(
              bottom: 120,
              right: 20,
              child: Container(
                width: 65,
                height: 55,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          user!.activeBibNumber!,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showTrainingOptions(bool isTrialUser, String? raceId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: const Color(0xFF0F172A),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Elige tu Entrenamiento",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.directions_run, color: Colors.blueAccent, size: 30),
                  title: const Text("Entrenamiento Libre", style: TextStyle(color: Colors.white)),
                  subtitle: const Text("Corre sin límites", style: TextStyle(color: Colors.white54)),
                  onTap: () {
                    Navigator.pop(context);
                    _startTracking(isTrialUser, raceId);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.timer, color: Colors.grey, size: 30),
                  title: const Text("Por Tiempo", style: TextStyle(color: Colors.grey)),
                  subtitle: const Text("Próximamente", style: TextStyle(color: Colors.white38)),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.map, color: Colors.grey, size: 30),
                  title: const Text("Por Distancia", style: TextStyle(color: Colors.grey)),
                  subtitle: const Text("Próximamente", style: TextStyle(color: Colors.white38)),
                  onTap: () {},
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTrackingDialog(bool isTrialUser, String? raceId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(_isTracking ? Icons.warning_amber_rounded : Icons.directions_run, 
                 color: _isTracking ? Colors.red : Colors.blueAccent, size: 30),
            const SizedBox(width: 10),
            Expanded(child: Text(_isTracking ? "Detener Ruta" : "Nuevo Entrenamiento")),
          ],
        ),
        content: Text(
          _isTracking 
            ? "¿Estás seguro de que deseas detener tu entrenamiento actual? Se guardará tu progreso." 
            : "¿Deseas iniciar un nuevo recorrido de entrenamiento libre?",
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isTracking ? Colors.red : Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (_isTracking) {
                _stopTracking();
              } else {
                _startTracking(isTrialUser, raceId);
              }
            },
            child: Text(_isTracking ? "Sí, Detener" : "Sí, Iniciar", style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLeaveRaceDialog(String raceId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Abandonar Carrera", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text("¿Estás seguro de que deseas salir de esta carrera? Ya no serás visible en el mapa ni se medirán tus tiempos.", style: TextStyle(fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final userId = FirebaseAuth.instance.currentUser?.uid;
              if (userId != null) {
                 await RaceService.instance.unlinkUserFromRace(raceId, userId);
              }
            },
            child: const Text("Sí, Salir", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalAlertOverlay() {
    return Positioned.fill(
      child: StreamBuilder(
        stream: Stream.periodic(const Duration(seconds: 1)),
        builder: (context, snapshot) {
          int? secondsLeft;
          if (_globalAlertTargetTime != null) {
            final now = DateTime.now();
            final difference = _globalAlertTargetTime!.difference(now);
            secondsLeft = difference.inSeconds;
            
            if (secondsLeft != null && secondsLeft < -2 && _globalAlertType != 'paused') {
              // Auto hide countdowns shortly after reaching zero
              return const SizedBox();
            }
          }

          IconData icon;
          Color color;
          if (_globalAlertType == 'paused') {
            icon = Icons.pause_circle_filled;
            color = Colors.orangeAccent;
          } else if (_globalAlertType == 'custom_message') {
            icon = Icons.campaign_rounded;
            color = Colors.purpleAccent;
          } else {
            icon = Icons.warning_rounded;
            color = Colors.redAccent;
          }

          return Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 80),
                    const SizedBox(height: 20),
                  Text(
                    _globalAlertMessage ?? "Alerta de Carrera",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (secondsLeft != null && secondsLeft >= 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        secondsLeft.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 100,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  else if (secondsLeft != null && secondsLeft < 0 && _globalAlertType == 'countdown_start')
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Text(
                        "¡GO!",
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 100,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class RunnerMarkerWidget extends StatelessWidget {
  final String? photoUrl;
  const RunnerMarkerWidget({super.key, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(color: Colors.black38, blurRadius: 4, offset: const Offset(0, 2))
              ],
            ),
          ),
          if (photoUrl != null && photoUrl!.isNotEmpty)
            ClipOval(
              child: Image.network(
                photoUrl!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 30, color: Colors.white),
              ),
            )
          else
            const Icon(Icons.directions_run, size: 30, color: Colors.white),
        ],
      ),
    );
  }
}
