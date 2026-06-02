import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../home/providers/run_state_provider.dart';
import '../../home/providers/user_provider.dart';
import '../../home/data/local_database.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<Map<String, dynamic>> _raceHistory = [];
  bool _isLoadingHistory = true;
  int _visibleCount = 10;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await LocalDatabase.instance.getRaceHistory();
    if (mounted) {
      setState(() {
        _raceHistory = history;
        _isLoadingHistory = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final runState = Provider.of<RunStateProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final theme = Theme.of(context);
    
    // Si NO está en una carrera activa, consideramos que es entrenamiento libre (o simplemente no compitiendo)
    final isFreeTraining = userProvider.userData?.activeRaceId == null || userProvider.userData!.activeRaceId!.isEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const SizedBox(height: 20),
              
              if (isFreeTraining) ...[
                // TARJETA PRINCIPAL (Distancia y Estado)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withOpacity(0.8)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "ENTRENAMIENTO LIBRE",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          letterSpacing: 2,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        runState.distanceFormatted,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'RobotoMono', 
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(
                          color: runState.isTracking 
                              ? Colors.green.withOpacity(0.2) 
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: runState.isTracking ? Colors.green : Colors.white24,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              runState.isTracking ? Icons.directions_run : Icons.pause_circle_outline,
                              color: runState.isTracking ? Colors.greenAccent : Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              runState.isTracking ? "Corriendo..." : "Pausado",
                              style: TextStyle(
                                color: runState.isTracking ? Colors.greenAccent : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),

                // METRICAS SECUNDARIAS
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.speed,
                        title: "Velocidad",
                        value: runState.speedFormatted,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.timer_outlined,
                        title: "Duración",
                        value: runState.timeFormatted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
              
              Text(
                "Historial de Carreras",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              
              if (_isLoadingHistory)
                const Center(child: CircularProgressIndicator())
              else if (_raceHistory.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      "Aún no has completado ninguna carrera oficial.",
                      style: TextStyle(color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                  Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _raceHistory.length > _visibleCount ? _visibleCount : _raceHistory.length,
                        itemBuilder: (context, index) {
                    final run = _raceHistory[index];
                    final bool isDisqualified = run['isDisqualified'] == 1;
                    final int time = run['timeInSeconds'] ?? 0;
                    
                    return Card(
                      color: theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (ctx) => _buildRaceDetailsSheet(ctx, run, isDisqualified, time, theme),
                          );
                        },
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(15),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDisqualified ? Colors.red.withOpacity(0.1) : Colors.amber.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isDisqualified ? Icons.cancel : Icons.emoji_events,
                              color: isDisqualified ? Colors.red : Colors.amber,
                            ),
                          ),
                          title: Text(
                            run['raceName'] ?? 'Carrera Desconocida',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 5),
                              Text("Dorsal: ${run['bibNumber'] ?? 'N/A'}"),
                              Text(isDisqualified 
                                  ? "Motivo: Desviación de ruta" 
                                  : "Tiempo Oficial: ${time ~/ 60}m ${time % 60}s"),
                            ],
                          ),
                          trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
                        ),
                      ),
                    );
                  },
                ),
                if (_raceHistory.length > _visibleCount)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _visibleCount += 10;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          side: BorderSide(color: theme.colorScheme.primary),
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text("Ver más", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRaceDetailsSheet(BuildContext context, Map<String, dynamic> run, bool isDisqualified, int time, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 25),
          
          // Encabezado
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDisqualified ? Colors.red.withOpacity(0.1) : Colors.amber.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDisqualified ? Icons.cancel : Icons.emoji_events,
              color: isDisqualified ? Colors.red : Colors.amber,
              size: 40,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            run['raceName'] ?? 'Carrera Desconocida',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            isDisqualified ? "Descalificado - Desviación de ruta" : "Carrera Completada Exitosamente",
            style: TextStyle(
              color: isDisqualified ? Colors.red : Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 30),
          
          // Detalles Grid
          Row(
            children: [
              Expanded(
                child: _DetailTile(
                  icon: Icons.timer,
                  title: "Tiempo Oficial",
                  value: "${time ~/ 60}m ${time % 60}s",
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _DetailTile(
                  icon: Icons.straighten,
                  title: "Distancia",
                  value: run['distanceFormatted'] ?? 'N/A',
                  color: Colors.purpleAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _DetailTile(
                  icon: Icons.confirmation_number_outlined,
                  title: "Dorsal",
                  value: run['bibNumber'] ?? 'N/A',
                  color: Colors.orangeAccent,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _DetailTile(
                  icon: Icons.business,
                  title: "Organizador",
                  value: run['organizerName'] ?? 'Oficial',
                  color: Colors.teal,
                ),
              ),
            ],
          ),

          
          if (run['routeJson'] != null && run['routeJson'].toString().isNotEmpty && run['routeJson'] != '[]')
            ...[
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Ruta Recorrida", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: Builder(
                    builder: (context) {
                      try {
                        List<dynamic> parsed = jsonDecode(run['routeJson']);
                        List<LatLng> points = parsed.map((e) => LatLng(e['lat'], e['lng'])).toList();
                        if (points.isEmpty) return const Center(child: Text("Sin ruta"));
                        
                        LatLngBounds bounds;
                        if (points.length == 1) {
                          bounds = LatLngBounds(southwest: points.first, northeast: points.first);
                        } else {
                          double south = points.first.latitude;
                          double north = points.first.latitude;
                          double west = points.first.longitude;
                          double east = points.first.longitude;
                          for (var p in points) {
                            if (p.latitude < south) south = p.latitude;
                            if (p.latitude > north) north = p.latitude;
                            if (p.longitude < west) west = p.longitude;
                            if (p.longitude > east) east = p.longitude;
                          }
                          bounds = LatLngBounds(southwest: LatLng(south, west), northeast: LatLng(north, east));
                        }

                        return GoogleMap(
                          initialCameraPosition: CameraPosition(target: points.first, zoom: 14),
                          myLocationEnabled: false,
                          zoomControlsEnabled: false,
                          scrollGesturesEnabled: false,
                          polylines: {
                            Polyline(
                              polylineId: const PolylineId('history_route'),
                              points: points,
                              color: Colors.blueAccent,
                              width: 5,
                            )
                          },
                          onMapCreated: (controller) {
                            Future.delayed(const Duration(milliseconds: 300), () {
                              controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 20));
                            });
                          },
                        );
                      } catch (e) {
                        return Container(color: Colors.grey.withOpacity(0.1), child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)));
                      }
                    },
                  ),
                ),
              ),
            ],
          
          const SizedBox(height: 35),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Cerrar bottom sheet
                    showDialog(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        title: const Text("Borrar Historial", style: TextStyle(color: Colors.red)),
                        content: const Text("¿Estás seguro de que deseas eliminar este registro de tu historial local?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () async {
                              Navigator.pop(dialogCtx);
                              if (run['id'] != null) {
                                await LocalDatabase.instance.deleteRaceHistory(run['id']);
                                _loadHistory(); // Recargar historial
                              }
                            },
                            child: const Text("Sí, Eliminar", style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text("Borrar", style: TextStyle(color: Colors.redAccent, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    backgroundColor: theme.colorScheme.primary,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cerrar", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatCard({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
          const SizedBox(height: 15),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 20, 
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _DetailTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: theme.brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
