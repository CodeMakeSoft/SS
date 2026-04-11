import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../data/race_service.dart';
import '../data/models/race_model.dart';
import 'race_management_screen.dart';

class AdminRacesScreen extends StatefulWidget {
  const AdminRacesScreen({super.key});

  @override
  State<AdminRacesScreen> createState() => _AdminRacesScreenState();
}

class _AdminRacesScreenState extends State<AdminRacesScreen> {
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Fondo oscuro para que resalten los cards
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CABECERA LIMPIA
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ADMINISTRACIÓN",
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Radar Maestro",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            
            // LISTA DE CARRERAS (VISTA COMPLETA)
            Expanded(
              child: StreamBuilder<List<RaceModel>>(
                stream: RaceService.instance.getActiveRaces(),
                builder: (context, snapshot) {
                  final races = snapshot.data ?? [];

                  if (races.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: races.length + 1, // +1 para compensar el bottom bar
                    itemBuilder: (context, index) {
                      if (index == races.length) {
                        return const SizedBox(height: 120); // Margen para la barra de navegación
                      }
                      
                      final race = races[index];
                      // Si hay una sola, destaque en grande. Si hay varias, lista adaptable.
                      return races.length == 1 
                        ? _buildRaceLargeCard(race)
                        : _buildRaceListCard(race);
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.radar, size: 80, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 20),
          const Text(
            "No hay carreras activas",
            style: TextStyle(color: Colors.white38, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // Card para cuando hay múltiples carreras
  Widget _buildRaceListCard(RaceModel race) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.directions_run, color: Colors.blueAccent),
        ),
        title: Text(
          race.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          "${race.participants.length} participantes • ${race.status.toUpperCase()}",
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RaceManagementScreen(race: race)),
          );
        },
      ),
    );
  }

  // Card prominente para una sola carrera activa
  Widget _buildRaceLargeCard(RaceModel race) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RaceManagementScreen(race: race)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent.withOpacity(0.2), Colors.transparent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("CARRERA ACTIVA", 
                  style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 10)),
                const Icon(Icons.online_prediction, color: Colors.greenAccent, size: 18),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              race.name,
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              "Toca para abrir el panel de control completo y ver el mapa en tiempo real sin obstrucciones.",
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                _buildStatItem(Icons.people, race.participants.length.toString(), "Corredores"),
                const SizedBox(width: 40),
                _buildStatItem(Icons.timer, "00:00", "Tiempo"),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white38, size: 14),
            const SizedBox(width: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }
}
