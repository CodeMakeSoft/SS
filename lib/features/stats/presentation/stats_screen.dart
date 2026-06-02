import 'package:flutter/material.dart';
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
          padding: const EdgeInsets.all(20.0),
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
                        value: "00:00:00",
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
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _raceHistory.length,
                  itemBuilder: (context, index) {
                    final run = _raceHistory[index];
                    final bool isDisqualified = run['isDisqualified'] == 1;
                    final int time = run['timeInSeconds'] ?? 0;
                    
                    return Card(
                      color: theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                            Text("Dorsal: ${userProvider.userData?.activeBibNumber ?? 'N/A'}"), // Solo de referencia
                            Text(isDisqualified 
                                ? "Motivo: Desviación de ruta" 
                                : "Tiempo Oficial: ${time ~/ 60}m ${time % 60}s"),
                          ],
                        ),
                        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
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
