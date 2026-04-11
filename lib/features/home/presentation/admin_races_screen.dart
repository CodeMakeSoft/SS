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
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CABECERA ESTANDARIZADA
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 35, 25, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Radar Maestro",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            
            // LISTA DE CARRERAS
            Expanded(
              child: StreamBuilder<List<RaceModel>>(
                stream: RaceService.instance.getActiveRaces(),
                builder: (context, snapshot) {
                  final races = snapshot.data ?? [];

                  if (races.isEmpty) {
                    return _buildEmptyState(theme);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: races.length + 1,
                    itemBuilder: (context, index) {
                      if (index == races.length) {
                        return const SizedBox(height: 120);
                      }
                      
                      final race = races[index];
                      return races.length == 1 
                        ? _buildRaceLargeCard(race, theme, isDark)
                        : _buildRaceListCard(race, theme, isDark);
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

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.radar, size: 80, color: theme.colorScheme.onSurface.withOpacity(0.1)),
          const SizedBox(height: 20),
          Text(
            "No hay carreras activas",
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildRaceListCard(RaceModel race, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
        border: isDark ? Border.all(color: Colors.white10) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.directions_run, color: theme.colorScheme.primary),
        ),
        title: Text(
          race.name,
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          "${race.participants.length} participantes • ${race.status.toUpperCase()}",
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: theme.colorScheme.onSurface.withOpacity(0.2), size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RaceManagementScreen(race: race)),
          );
        },
      ),
    );
  }

  Widget _buildRaceLargeCard(RaceModel race, ThemeData theme, bool isDark) {
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
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(isDark ? 0.4 : 0.1),
              blurRadius: 30,
              offset: const Offset(0, 15),
            )
          ],
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
          gradient: isDark ? LinearGradient(
            colors: [theme.colorScheme.primary.withOpacity(0.1), Colors.transparent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("CARRERA ACTIVA", 
                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 10)),
                Icon(Icons.online_prediction, color: isDark ? Colors.greenAccent : Colors.green, size: 18),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              race.name,
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 32, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              "Toca para abrir el panel de control completo y ver el mapa en tiempo real.",
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                _buildStatItem(Icons.people, race.participants.length.toString(), "Corredores", theme),
                const SizedBox(width: 40),
                _buildStatItem(Icons.timer, "00:00", "Tiempo", theme),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 14),
            const SizedBox(width: 8),
            Text(value, style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        Text(label, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 11)),
      ],
    );
  }
}
