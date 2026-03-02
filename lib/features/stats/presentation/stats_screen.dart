import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../home/providers/run_state_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Aquí nos "enganchamos" al cerebro para escuchar los cambios en vivo
    final runState = Provider.of<RunStateProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent, // Background comes from Main Skeleton
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                "Tus Estadísticas",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A), // Dark Tech
                ),
              ),
              const SizedBox(height: 30),
              
              // 1. TARJETA PRINCIPAL (Distancia y Estado)
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
                      "DISTANCIA OFICIAL",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 2,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // AQUÍ ESTÁ EL DATO MÁGICO
                    Text(
                      runState.distanceFormatted,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'RobotoMono', // Fuente tech
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Estado de la carrera (Conectado al Map Play/Stop)
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
                            runState.isTracking ? "Corriendo..." : "Carrera Pausada",
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

              // 2. METRICAS SECUNDARIAS (Velocidad, etc)
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
                      value: "00:00:00", // El cronómetro lo haremos en un paso futuro
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
}

// Widget auxiliar para hacer cajitas de métricas bonitas
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatCard({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
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
            style: const TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 20, 
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
