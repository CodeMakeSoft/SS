import 'package:flutter/material.dart';
import '../data/race_service.dart';
import '../data/models/race_model.dart';
import 'race_management_screen.dart'; 
import 'race_summary_screen.dart';

class RaceHistoryScreen extends StatefulWidget {
  const RaceHistoryScreen({super.key});

  @override
  State<RaceHistoryScreen> createState() => _RaceHistoryScreenState();
}

class _RaceHistoryScreenState extends State<RaceHistoryScreen> {
  int _visibleCount = 10;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
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
          "Historial de Carreras",
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<RaceModel>>(
        stream: RaceService.instance.getRaceHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error al cargar historial", style: TextStyle(color: Colors.red)));
          }

          final races = snapshot.data ?? [];
          races.sort((a, b) => b.date.compareTo(a.date));

          if (races.isEmpty) {
            return _buildEmptyState(theme);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: races.length > _visibleCount ? _visibleCount + 1 : races.length,
            itemBuilder: (context, index) {
              if (index == _visibleCount) {
                return Padding(
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
                );
              }

              final race = races[index];
              return _buildHistoryCard(context, race, theme, isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 80, color: theme.colorScheme.onSurface.withOpacity(0.1)),
          const SizedBox(height: 20),
          Text(
            "Aún no hay carreras finalizadas",
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, RaceModel race, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: theme.dividerColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.flag, color: Colors.grey),
        ),
        title: Text(
          race.name,
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          "${race.participants.length} participantes • FINALIZADA",
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (race.status != 'archived')
              IconButton(
                icon: const Icon(Icons.archive, color: Colors.purple, size: 20),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: theme.cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text("Archivar Carrera", style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                      content: const Text("Esto moverá la carrera al estado archivado para limpiar datos temporales. ¿Continuar?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await RaceService.instance.archiveRaceAndKeepPodium(race);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Carrera archivada")));
                            }
                          },
                          child: const Text("Archivar", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 20),
              onPressed: () => _showDeleteConfirmationDialog(context, race),
            ),
            const SizedBox(width: 8),
            Icon(Icons.visibility, color: theme.colorScheme.onSurface.withOpacity(0.3), size: 20),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RaceSummaryScreen(race: race)),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, RaceModel race) {
    showDialog(
      context: context,
      builder: (ctx1) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Paso 1: Borrado Definitivo", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text("¿Estás seguro de que quieres eliminar DEFINITIVAMENTE la carrera '${race.name}'? Se borrará por completo de la base de datos."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx1), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx1);
              showDialog(
                context: context,
                builder: (ctx2) => AlertDialog(
                  backgroundColor: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text("Paso 2: Confirmación Final", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  content: const Text("¡ADVERTENCIA! Esta acción no se puede deshacer. Se eliminarán permanentemente el historial de tiempos y la ruta. ¿Proceder?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () async {
                        Navigator.pop(ctx2);
                        showDialog(
                          context: context, barrierDismissible: false,
                          builder: (_) => const Center(child: CircularProgressIndicator()),
                        );
                        try {
                          await RaceService.instance.deleteRace(race.raceId);
                          if (context.mounted) {
                            Navigator.pop(context); // Cierra loading
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Carrera eliminada permanentemente')));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context); // Cierra loading
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.redAccent));
                          }
                        }
                      },
                      child: const Text("ELIMINAR PARA SIEMPRE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
