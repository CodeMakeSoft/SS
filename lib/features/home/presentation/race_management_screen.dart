import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smartsync/features/home/presentation/create_race_screen.dart';
import '../data/models/race_model.dart';
import '../data/race_service.dart';
import 'runners_list_screen.dart';
import 'qr_scanner_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:widget_to_marker/widget_to_marker.dart';
import 'home_screen.dart';

class RaceManagementScreen extends StatefulWidget {
  final RaceModel race;
  const RaceManagementScreen({super.key, required this.race});

  @override
  State<RaceManagementScreen> createState() => _RaceManagementScreenState();
}

class _RaceManagementScreenState extends State<RaceManagementScreen> {
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();
  
  final Set<Marker> _runnersMarkers = {};
  final Map<String, BitmapDescriptor> _runnersMarkersIcons = {};
  StreamSubscription<QuerySnapshot>? _runnersSubscription;

  @override
  void initState() {
    super.initState();
    _startTrackingRunners();
  }

  @override
  void dispose() {
    _runnersSubscription?.cancel();
    super.dispose();
  }

  void _startTrackingRunners() {
    _runnersSubscription = FirebaseFirestore.instance
        .collection('races')
        .doc(widget.race.raceId)
        .collection('live_locations')
        .snapshots()
        .listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        final doc = change.doc;
        
        if (change.type == DocumentChangeType.removed) {
          if (mounted) {
            setState(() {
              _runnersMarkers.removeWhere((m) => m.markerId.value == 'runner_${doc.id}');
              _runnersMarkersIcons.remove(doc.id);
            });
          }
          continue;
        }

        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        
        final lat = data['latitude'] as double?;
        final lng = data['longitude'] as double?;
        final photoUrl = data['photoUrl'] as String?;
        
        if (lat == null || lng == null) continue;
        
        if (!_runnersMarkersIcons.containsKey(doc.id)) {
           try {
             final icon = await RunnerMarkerWidget(photoUrl: photoUrl).toBitmapDescriptor(
                logicalSize: const Size(60, 60), 
                imageSize: const Size(60, 60),
             );
             _runnersMarkersIcons[doc.id] = icon;
           } catch (e) {
             debugPrint("Error generating photo marker for ${doc.id}: $e");
             _runnersMarkersIcons[doc.id] = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
           }
        }

        if (mounted) {
          setState(() {
            _runnersMarkers.removeWhere((m) => m.markerId.value == 'runner_${doc.id}');
            _runnersMarkers.add(
              Marker(
                markerId: MarkerId('runner_${doc.id}'),
                position: LatLng(lat, lng),
                icon: _runnersMarkersIcons[doc.id]!,
                anchor: const Offset(0.5, 0.5),
              )
            );
          });
        }
      }
    });
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final myLocation = LatLng(position.latitude, position.longitude);
    
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(myLocation, 15));
  }

   void _showBibAssignmentModal(String scannedUid, String runnerName) {
    final TextEditingController bibController = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              mainAxisSize: MainAxisSize.min, 
              children: [
                Text("ASIGNAR DORSAL", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 20),
                
                // Perfil Cargado
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    children: [
                      CircleAvatar(backgroundColor: theme.colorScheme.primary, child: Text(runnerName.isNotEmpty ? runnerName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 15),
                      Expanded(child: Text(runnerName, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface))),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                TextField(
                  controller: bibController,
                  keyboardType: TextInputType.number,
                  autofocus: true, 
                  decoration: InputDecoration(
                    labelText: 'Dorsal',
                    prefixIcon: const Icon(Icons.confirmation_number_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                const SizedBox(height: 20),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent, 
                      padding: const EdgeInsets.symmetric(vertical: 15), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                    ),
                    onPressed: () async {
                      final bib = bibController.text.trim();
                      if (bib.isEmpty) return;
                      
                      showDialog(
                        context: context, barrierDismissible: false,
                        builder: (_) => const Center(child: CircularProgressIndicator()),
                      );
                      final nav = Navigator.of(context, rootNavigator: true);

                      try {
                        final isTaken = await RaceService.instance.isBibNumberTaken(widget.race.raceId, bib, excludeUserId: scannedUid);
                        if (isTaken) {
                          nav.pop();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Este dorsal ya está asignado a otro corredor'), backgroundColor: Colors.red));
                          }
                          return;
                        }
                        
                        await RaceService.instance.linkUserToRace(widget.race.raceId, scannedUid, bib);
                        nav.pop();
                        
                        if (context.mounted) {
                          Navigator.pop(context); 
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$runnerName vinculado (Dorsal #$bib)'), backgroundColor: Colors.green));
                        }
                      } catch (e) {
                        nav.pop();
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                      }
                    },
                    child: const Text('Confirmar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  void _showActionConfirmation(BuildContext context, {
    required String title,
    required String description,
    required String confirmText,
    required Color color,
    required IconData icon,
    required VoidCallback onConfirm,
  }) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Círculo con ícono gigante en el centro
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 36),
              ),
              const SizedBox(height: 20),
              
              // Título
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 10),
              
              // Descripción / Advertencia
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 14),
              ),
              const SizedBox(height: 24),
              
              // Botones Cancelar / Confirmar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        side: BorderSide(color: theme.dividerColor),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancelar', style: TextStyle(color: theme.colorScheme.onSurface)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Cierra el modal
                        onConfirm(); // Ejecuta la función que le pasemos
                      },
                      child: Text(confirmText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('races').doc(widget.race.raceId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final currentRace = RaceModel.fromMap(snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);
        return _buildContent(context, currentRace);
      }
    );
  }

  Widget _buildContent(BuildContext context, RaceModel race) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    double distanceTotalMeters = 0;
    for (int i = 0; i < race.route.length - 1; i++) {
      final p1 = race.route[i];
      final p2 = race.route[i + 1];
      distanceTotalMeters += Geolocator.distanceBetween(p1.latitude, p1.longitude, p2.latitude, p2.longitude);
    }
    int distanceKm = (distanceTotalMeters / 1000).ceil();
    String raceDistanceLabel = "$distanceKm KM";

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: race.route.isNotEmpty 
                  ? LatLng(race.route.first.latitude, race.route.first.longitude)
                  : const LatLng(19.4326, -99.1332),
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController.complete(controller),
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            
            polylines: {
              if (race.route.isNotEmpty)
                Polyline(
                  polylineId: const PolylineId('race_route'),
                  points: race.route.map((p) => LatLng(p.latitude, p.longitude)).toList(),
                  color: Colors.blueAccent,
                  width: 5,
                  jointType: JointType.round,
                ),
            },
            
            markers: {
              if (race.route.isNotEmpty)
                Marker(
                  markerId: const MarkerId('start'),
                  position: LatLng(race.route.first.latitude, race.route.first.longitude),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                  infoWindow: const InfoWindow(title: 'Punto de Partida'),
                ),
              if (race.route.length > 1)
                Marker(
                  markerId: const MarkerId('end'),
                  position: LatLng(race.route.last.latitude, race.route.last.longitude),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  infoWindow: const InfoWindow(title: 'Meta'),
                ),
              ..._runnersMarkers,
            },
          ),

          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.1), blurRadius: 10)],
                    ),
                    child: Icon(Icons.arrow_back_ios_new, color: theme.colorScheme.onSurface, size: 20),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10)],
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.analytics_outlined, color: Colors.blueAccent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "${race.name.toUpperCase()} - $raceDistanceLabel",
                            style: TextStyle(
                              color: theme.colorScheme.onSurface, 
                              fontWeight: FontWeight.bold, 
                              letterSpacing: 1.1,
                              fontSize: 14
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: theme.scaffoldBackgroundColor,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                              ),
                              builder: (context) {
                                return SafeArea(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [

                                        Container(
                                          width: 40,
                                          height: 5,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        
                                        Text(
                                          "Gestión de la carrera",
                                          style: TextStyle(
                                            fontSize: 18, 
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 15),
                                        ListTile(
                                          leading: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), shape: BoxShape.circle),
                                            child: const Icon(Icons.people_alt, color: Colors.blueAccent),
                                          ),
                                          title: const Text("Lista de Corredores", style: TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: const Text("Ver y administrar participantes"),
                                          onTap: () {
                                            Navigator.pop(context);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => RunnersListScreen(race: race),
                                              ),
                                            );
                                          },
                                        ),
                                        if (race.status == 'upcoming')
                                          ListTile(
                                            leading: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                                              child: const Icon(Icons.edit, color: Colors.orange),
                                            ),
                                            title: const Text("Editar Carrera", style: TextStyle(fontWeight: FontWeight.bold)),
                                            subtitle: const Text("Modificar detalles y configuración"),
                                            onTap: () {
                                              Navigator.pop(context);
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => CreateRaceScreen(raceToEdit: race),
                                                ),
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          child: SizedBox(
                            width: 34,
                            height: 34,
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit, color: Colors.white, size: 18),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            right: 20,
            bottom: 140, 
            child: FloatingActionButton(
              mini: true,
              backgroundColor: theme.cardColor,
              onPressed: _getUserLocation,
              child: Icon(Icons.my_location, color: theme.colorScheme.primary),
            ),
          ),

          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.4 : 0.15), blurRadius: 20)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(race.status.toUpperCase(), 
                        style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 10)),
                      Text("GESTIÓN EN VIVO", 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface)),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: theme.scaffoldBackgroundColor,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                            ),
                            builder: (context) {
                              return SafeArea(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      
                                      Text(
                                        "Control de Carrera",
                                        style: TextStyle(
                                          fontSize: 18, 
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 15),

                                      ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                                          child: const Icon(Icons.play_arrow, color: Colors.green),
                                        ),
                                        title: const Text("Iniciar Carrera", style: TextStyle(fontWeight: FontWeight.bold)),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _showActionConfirmation(
                                            context,
                                            title: '¿Iniciar Carrera?',
                                            description: 'Esta acción comenzará el cronómetro oficial y cambiará el estado de la carrera a "En Curso".',
                                            confirmText: 'Iniciar',
                                            color: Colors.green,
                                            icon: Icons.play_arrow,
                                            onConfirm: () async {
                                              await RaceService.instance.updateRaceStatus(race.raceId, 'ongoing');
                                              await RaceService.instance.sendGlobalAlert(
                                                race.raceId, 
                                                'countdown_start', 
                                                '¡Preparados! La carrera comienza en', 
                                                countdownSeconds: 3,
                                              );
                                              Future.delayed(const Duration(seconds: 7), () {
                                                RaceService.instance.clearGlobalAlert(race.raceId);
                                              });
                                            },
                                          );
                                        }
                                      ),
                                      
                                      ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(color: (race.status == 'paused' ? Colors.green : Colors.orange).withOpacity(0.1), shape: BoxShape.circle),
                                          child: Icon(race.status == 'paused' ? Icons.play_arrow : Icons.pause, color: race.status == 'paused' ? Colors.green : Colors.orange),
                                        ),
                                        title: Text(race.status == 'paused' ? "Reanudar Carrera" : "Pausar Carrera", style: const TextStyle(fontWeight: FontWeight.bold)),
                                        onTap: () {
                                          Navigator.pop(context); 
                                          
                                          if (race.status == 'paused') {
                                            _showActionConfirmation(
                                              context,
                                              title: '¿Reanudar Carrera?',
                                              description: 'El cronómetro continuará su marcha.',
                                              confirmText: 'Reanudar',
                                              color: Colors.green,
                                              icon: Icons.play_arrow,
                                              onConfirm: () async {
                                                await RaceService.instance.updateRaceStatus(race.raceId, 'ongoing');
                                                await RaceService.instance.sendGlobalAlert(
                                                  race.raceId, 
                                                  'countdown_start', 
                                                  '¡La carrera se reanuda en', 
                                                  countdownSeconds: 3,
                                                );
                                                Future.delayed(const Duration(seconds: 7), () {
                                                  RaceService.instance.clearGlobalAlert(race.raceId);
                                                });
                                              },
                                            );
                                          } else {
                                            _showActionConfirmation(
                                              context,
                                              title: '¿Pausar Carrera?',
                                              description: 'Se detendrá el cronómetro temporalmente. Podrás reanudarlo después.',
                                              confirmText: 'Pausar',
                                              color: Colors.orange,
                                              icon: Icons.pause,
                                              onConfirm: () async {
                                                await RaceService.instance.updateRaceStatus(race.raceId, 'paused');
                                                await RaceService.instance.sendGlobalAlert(
                                                  race.raceId, 
                                                  'paused', 
                                                  'Carrera Pausada', 
                                                );
                                              },
                                            );
                                          }
                                        }
                                      ),
                                      ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                                          child: const Icon(Icons.stop, color: Colors.red),
                                        ),
                                        title: const Text("Terminar Carrera", style: TextStyle(fontWeight: FontWeight.bold)),
                                        onTap: () {
                                          Navigator.pop(context); 
                                          
                                          _showActionConfirmation(
                                            context,
                                            title: '¿Terminar Carrera?',
                                            description: '¡Atención! Esta acción es irreversible. Finalizará la recolección de tiempos.',
                                            confirmText: 'Finalizar',
                                            color: Colors.red,
                                            icon: Icons.stop,
                                            onConfirm: () async {
                                              await RaceService.instance.updateRaceStatus(race.raceId, 'finished');
                                              await RaceService.instance.sendGlobalAlert(
                                                race.raceId, 
                                                'countdown_finish', 
                                                'La carrera termina en', 
                                                countdownSeconds: 5,
                                              );
                                              Future.delayed(const Duration(seconds: 8), () {
                                                RaceService.instance.clearGlobalAlert(race.raceId);
                                              });
                                            },
                                          );
                                        },
                                      ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 20),
                                          child: Divider(), 
                                        ),

                                        ListTile(
                                          leading: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), shape: BoxShape.circle),
                                            child: const Icon(Icons.campaign, color: Colors.blueAccent),
                                          ),
                                          title: const Text("Crear Aviso", style: TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: const Text("Enviar notificación push a todos"),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _showCustomMessageDialog(context, race.raceId);
                                          },
                                        ),
                                        
                                        if (race.status == 'finished')
                                          ListTile(
                                            leading: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), shape: BoxShape.circle),
                                              child: const Icon(Icons.archive, color: Colors.purple),
                                            ),
                                            title: const Text("Archivar Carrera (Borrar)", style: TextStyle(fontWeight: FontWeight.bold)),
                                            subtitle: const Text("Limpiará datos y guardará el Podio de 3", style: TextStyle(fontSize: 11)),
                                            onTap: () {
                                              Navigator.pop(context);
                                              _showDoubleConfirmationDialog(
                                                context, 
                                                onConfirm: () async {
                                                  await RaceService.instance.archiveRaceAndKeepPodium(race);
                                                  if (context.mounted) Navigator.pop(context); // Cierra Admin Screen
                                                }
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.all(14),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Icon(Icons.route),
                      ),
                      
                      const SizedBox(width: 10),
                      
                      ElevatedButton(
                        onPressed: () async {
                          final scannedUid = await showDialog(
                            context: context,
                            builder: (context) => const QrScannerScreen(),
                          );
                          if (scannedUid != null && scannedUid is String) {
                            showDialog(
                              context: context, barrierDismissible: false,
                              builder: (_) => const Center(child: CircularProgressIndicator()),
                            );
                            try {
                              final doc = await FirebaseFirestore.instance.collection('users').doc(scannedUid).get();
                              
                              if (context.mounted) Navigator.pop(context); 
                              if (!doc.exists) {
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario no encontrado'), backgroundColor: Colors.redAccent));
                                return;
                              }
                              final userData = doc.data() as Map<String, dynamic>;
                              final runnerName = userData['displayName'] ?? 'Sin nombre';
                              if (context.mounted) {
                                _showBibAssignmentModal(scannedUid, runnerName);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                Navigator.pop(context); 
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de conexión')));
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.all(14),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Icon(Icons.qr_code_scanner),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
  
  void _showCustomMessageDialog(BuildContext context, String raceId) {
    final TextEditingController _messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Anuncio Global"),
        content: TextField(
          controller: _messageController,
          decoration: const InputDecoration(
            hintText: "Escribe tu mensaje aquí...",
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () async {
              if (_messageController.text.trim().isNotEmpty) {
                Navigator.pop(ctx);
                await RaceService.instance.sendGlobalAlert(
                  raceId, 
                  'custom_message', 
                  _messageController.text.trim(),
                );
                // Hide the message after 10 seconds
                Future.delayed(const Duration(seconds: 10), () {
                  RaceService.instance.clearGlobalAlert(raceId);
                });
              }
            },
            child: const Text("Enviar a Todos", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDoubleConfirmationDialog(BuildContext context, {required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (ctx1) => AlertDialog(
        title: const Text("Paso 1: Confirmación de Borrado", style: TextStyle(color: Colors.red)),
        content: const Text("¿Estás seguro de que quieres archivar esta carrera? Los datos pesados se eliminarán para ahorrar espacio, conservando únicamente el top 3 del podio."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx1), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx1);
              showDialog(
                context: context,
                builder: (ctx2) => AlertDialog(
                  title: const Text("Paso 2: Confirmación Definitiva", style: TextStyle(color: Colors.red)),
                  content: const Text("¡ATENCIÓN! Esta acción NO se puede deshacer. ¿Proceder con el borrado/archivado?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        Navigator.pop(ctx2);
                        onConfirm();
                      },
                      child: const Text("Archivar Definitivamente", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
            child: const Text("Siguiente Paso", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
