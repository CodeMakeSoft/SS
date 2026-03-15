import 'package:flutter/material.dart';
import '../data/race_service.dart';
import '../data/models/race_model.dart';
import 'package:intl/intl.dart';

class AdminRacesScreen extends StatelessWidget {
  const AdminRacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    "EVENTOS",
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Radar en Vivo",
                    style: TextStyle(
                      color: Color(0xFF263238),
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<RaceModel>>(
                stream: RaceService.instance.getActiveRaces(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final races = snapshot.data ?? [];
                  
                  if (races.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.radar_outlined, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            "Sin eventos activos o próximos",
                            style: TextStyle(color: Colors.grey[500], fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: races.length,
                    itemBuilder: (context, index) {
                      return _buildRaceCard(context, races[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRaceCard(BuildContext context, RaceModel race) {
    final theme = Theme.of(context);
    final bool isOngoing = race.status == 'ongoing';
    final String statusText = isOngoing ? 'En Curso' : 'Programada';
    final Color statusColor = isOngoing ? Colors.green : Colors.blue;
    final String dateStr = DateFormat('dd MMM yyyy').format(race.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navegar al mapa detallado de esta carrera
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isOngoing ? Icons.flash_on_rounded : Icons.calendar_today_rounded, 
                    color: statusColor, 
                    size: 24
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        race.name,
                        style: const TextStyle(
                          color: Color(0xFF263238),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$statusText • $dateStr",
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isOngoing ? "VER RADAR" : "GESTIONAR",
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
