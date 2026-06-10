import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../data/models/race_model.dart';
import 'package:intl/intl.dart';
import 'runners_list_screen.dart';

class RaceSummaryScreen extends StatelessWidget {
  final RaceModel race;
  
  const RaceSummaryScreen({super.key, required this.race});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calcular duración real si existen startTime y endTime en la base de datos
    String actualDuration = "No registrada";
    if (race.startTime != null && race.endTime != null) {
      final diff = race.endTime!.difference(race.startTime!);
      actualDuration = "${diff.inHours}h ${(diff.inMinutes % 60)}m";
    } else if (race.estimatedDuration != null && race.estimatedDuration!.isNotEmpty) {
      actualDuration = "${race.estimatedDuration} (Est.)";
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Resumen de Evento",
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. CABECERA CON TROFEO
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emoji_events, size: 60, color: Colors.amber),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    race.name,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat("dd 'de' MMMM, yyyy").format(race.date),
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 2. ESTADÍSTICAS
            Row(
              children: [
                Expanded(child: _buildStatCard("Duración Final", actualDuration, Icons.timer, theme, isDark)),
                const SizedBox(width: 15),
                Expanded(child: _buildStatCard("Participantes", "${race.participants.length}", Icons.people, theme, isDark)),
              ],
            ),
            
            if (race.tags.isNotEmpty) ...[
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                children: race.tags.map((tag) => Chip(
                  label: Text(tag, style: const TextStyle(fontSize: 12, color: Colors.white)),
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: BorderSide.none,
                )).toList(),
              ),
            ],

            const SizedBox(height: 30),

            // 3. EL PODIO (Diseño visual listo para integrar los ganadores)
            _buildSectionTitle("Podio Oficial", theme),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildPodiumPosition(2, "2do", 80, Colors.grey[400]!, theme),
                      _buildPodiumPosition(1, "1ero", 120, Colors.amber, theme),
                      _buildPodiumPosition(3, "3ro", 60, Colors.brown[300]!, theme),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Resultados oficiales del evento.",
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5), fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 4. MAPA DE LA RUTA (Recuadro visual preparado para el mapa estático)
            _buildSectionTitle("Ruta Recorrida", theme),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: race.route.isEmpty 
                  ? Container(
                      color: theme.colorScheme.primary.withOpacity(0.05),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map, size: 40, color: theme.colorScheme.primary.withOpacity(0.5)),
                            const SizedBox(height: 10),
                            Text("No se registró ruta", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    )
                  : Builder(
                      builder: (context) {
                        List<LatLng> points = race.route.map((p) => LatLng(p.latitude, p.longitude)).toList();
                        
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
                      },
                    ),
              ),
            ),

            const SizedBox(height: 30),

            // 5. BOTÓN HACIA LA LISTA DE CORREDORES
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Reutilizamos tu vista existente de la lista de corredores
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RunnersListScreen(race: race)),
                  );
                },
                icon: const Icon(Icons.format_list_numbered),
                label: const Text("Ver Lista Oficial de Corredores", style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(color: theme.colorScheme.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
        ],
      ),
    );
  }

  Widget _buildPodiumPosition(int position, String label, double height, Color color, ThemeData theme) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: theme.colorScheme.surface,
          child: Icon(Icons.person, color: theme.colorScheme.onSurface.withOpacity(0.5)),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
