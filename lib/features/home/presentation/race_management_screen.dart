import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../data/models/race_model.dart';
import '../data/race_service.dart';

class RaceManagementScreen extends StatefulWidget {
  final RaceModel race;
  const RaceManagementScreen({super.key, required this.race});

  @override
  State<RaceManagementScreen> createState() => _RaceManagementScreenState();
}

class _RaceManagementScreenState extends State<RaceManagementScreen> {
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // MAPA EN PANTALLA COMPLETA
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(19.4326, -99.1332),
              zoom: 14,
            ),
            onMapCreated: (controller) => _mapController.complete(controller),
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
          ),

          // CABECERA FLOTANTE CLARA
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 20),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.analytics_outlined, color: Colors.blueAccent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.race.name.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF0F172A), 
                              fontWeight: FontWeight.bold, 
                              letterSpacing: 1.1,
                              fontSize: 14
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // PANEL DE CONTROL INFERIOR CLARO
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.race.status.toUpperCase(), 
                        style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 10)),
                      const Text("GESTIÓN EN VIVO", 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Lógica de escaneo QR aquí
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text("VINCULAR"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
