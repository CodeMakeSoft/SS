import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class RouteDesignerScreen extends StatefulWidget {
  final List<LatLng> initialRoute;
  
  const RouteDesignerScreen({super.key, this.initialRoute = const []});

  @override
  State<RouteDesignerScreen> createState() => _RouteDesignerScreenState();
}

class _RouteDesignerScreenState extends State<RouteDesignerScreen> {
  late List<LatLng> _points;
  final List<LatLng> _redoPoints = []; 
  GoogleMapController? _mapController;
  
  LatLng _initialLocation = const LatLng(19.4326, -99.1332); 

  @override
  void initState() {
    super.initState();
    _points = List.from(widget.initialRoute);
    _getUserLocation();
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
    
    if (mounted) {
      setState(() {
        _initialLocation = myLocation;
      });
    }

    if (_mapController != null && _points.isEmpty) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(myLocation, 15));
    }
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _points.add(location);
      _redoPoints.clear();
    });
  }

  void _undoLastPoint() {
    if (_points.isNotEmpty) {
      setState(() {
        _redoPoints.add(_points.removeLast());
      });
    }
  }

  void _redoLastPoint() {
    if (_redoPoints.isNotEmpty) {
      setState(() {
        _points.add(_redoPoints.removeLast());
      });
    }
  }

  void _saveRoute() {
    Navigator.pop(context, _points);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: theme.cardColor.withOpacity(0.9),
            child: IconButton(
              icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _points.isNotEmpty ? _points.first : _initialLocation,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              if (_points.isNotEmpty) {
                Future.delayed(const Duration(milliseconds: 300), () => _fitRouteBounds());
              } else {
                _getUserLocation();
              }
            },
            onTap: _onMapTap,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            
            polylines: {
              if (_points.isNotEmpty)
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: _points,
                  color: Colors.blueAccent,
                  width: 5,
                  jointType: JointType.round,
                ),
            },
            
            markers: {
              if (_points.isNotEmpty)
                Marker(
                  markerId: const MarkerId('start'),
                  position: _points.first,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                  infoWindow: const InfoWindow(title: 'Inicio'),
                ),
              if (_points.length > 1)
                Marker(
                  markerId: const MarkerId('end'),
                  position: _points.last,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  infoWindow: const InfoWindow(title: 'Fin'),
                ),
            },
          ),
          
          Positioned(
            right: 20,
            bottom: 120, 
            child: FloatingActionButton(
              mini: true,
              backgroundColor: theme.cardColor,
              onPressed: _getUserLocation,
              child: Icon(Icons.my_location, color: theme.colorScheme.primary),
            ),
          ),

          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: theme.cardColor.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.1), blurRadius: 15, offset: const Offset(0, 5))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.place, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          "${_points.length}",
                          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 16),
                        ),
                      ],
                    ),
                  ),

                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.undo),
                        color: _points.isNotEmpty ? theme.colorScheme.onSurface : Colors.grey,
                        onPressed: _points.isNotEmpty ? _undoLastPoint : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.redo),
                        color: _redoPoints.isNotEmpty ? theme.colorScheme.onSurface : Colors.grey,
                        onPressed: _redoPoints.isNotEmpty ? _redoLastPoint : null,
                      ),
                    ],
                  ),
                  
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text("Guardar", style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _points.length >= 2 ? _saveRoute : null, 
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  void _fitRouteBounds() {
    if (_points.isEmpty || _mapController == null) return;
    
    double minLat = _points.first.latitude;
    double maxLat = _points.first.latitude;
    double minLng = _points.first.longitude;
    double maxLng = _points.first.longitude;

    for (var p in _points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)),
        50.0,
      ),
    );
  }
}
