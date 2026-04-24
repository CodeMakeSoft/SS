import 'package:flutter/material.dart';
import '../data/race_service.dart';
import '../data/models/race_model.dart';
import 'race_management_screen.dart'; 
import 'race_summary_screen.dart';

class RaceHistoryScreen extends StatelessWidget {
  const RaceHistoryScreen({super.key});

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

          if (races.isEmpty) {
            return _buildEmptyState(theme);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: races.length,
            itemBuilder: (context, index) {
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
        trailing: Icon(Icons.visibility, color: theme.colorScheme.onSurface.withOpacity(0.3), size: 20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RaceSummaryScreen(race: race)),
          );
        },
      ),
    );
  }
}
