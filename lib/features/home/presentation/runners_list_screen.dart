import 'package:flutter/material.dart';
import '../data/models/race_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/race_service.dart';

class RunnersListScreen extends StatefulWidget {
  final RaceModel race;
  
  const RunnersListScreen({super.key, required this.race});

  @override
  State<RunnersListScreen> createState() => _RunnersListScreenState();
}

class _RunnersListScreenState extends State<RunnersListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDeleteConfirmation(BuildContext outerContext, {
    required String title,
    required String description,
    required VoidCallback onConfirm,
  }) {
    final theme = Theme.of(outerContext);
    
    showDialog(
      context: outerContext,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 50),
              const SizedBox(height: 15),
              Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 10),
              Text(description, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 14)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        side: BorderSide(color: theme.dividerColor),
                      ),
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text('Cancelar', style: TextStyle(color: theme.colorScheme.onSurface)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        onConfirm();
                      },
                      child: const Text("Eliminar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRunnerOptions(BuildContext outerContext, String userId, String userName, String currentBib, RaceModel race) {
    final TextEditingController bibController = TextEditingController(text: currentBib);
    final theme = Theme.of(outerContext);
    
    showDialog(
      context: outerContext,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Opciones de Corredor", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 5),
              Text(userName, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              TextField(
                controller: bibController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Dorsal Actual',
                  prefixIcon: const Icon(Icons.confirmation_number_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 20),
              
              // Botón Actualizar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent, 
                    padding: const EdgeInsets.symmetric(vertical: 15), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                  ),
                  onPressed: () async {
                    final bib = bibController.text.trim();
                    if (bib.isEmpty) return;
                    
                    showDialog(
                      context: outerContext, barrierDismissible: false,
                      builder: (_) => const Center(child: CircularProgressIndicator()),
                    );
                    final nav = Navigator.of(outerContext, rootNavigator: true);
                    
                    try {
                      final isTaken = await RaceService.instance.isBibNumberTaken(race.raceId, bib, excludeUserId: userId);
                      if (isTaken) {
                        nav.pop();
                        if (outerContext.mounted) ScaffoldMessenger.of(outerContext).showSnackBar(const SnackBar(content: Text('Error: Este dorsal ya está asignado a otro corredor'), backgroundColor: Colors.red));
                        return;
                      }
                      
                      await RaceService.instance.linkUserToRace(race.raceId, userId, bib);
                      nav.pop();
                      if (outerContext.mounted) Navigator.pop(dialogContext); 
                      if (outerContext.mounted) ScaffoldMessenger.of(outerContext).showSnackBar(const SnackBar(content: Text('Dorsal actualizado')));
                    } catch (e) {
                      nav.pop();
                      if (outerContext.mounted) ScaffoldMessenger.of(outerContext).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                    }
                  },
                  child: const Text('Actualizar Dorsal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  icon: const Icon(Icons.person_remove),
                  label: const Text('Eliminar de la carrera'),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _showDeleteConfirmation(
                      outerContext, 
                      title: '¿Expulsar corredor?', 
                      description: 'Estás a punto de desvincular a $userName de la carrera. Se liberará su dorsal.', 
                      onConfirm: () async {
                        showDialog(
                          context: outerContext, barrierDismissible: false,
                          builder: (_) => const Center(child: CircularProgressIndicator()),
                        );
                        final nav = Navigator.of(outerContext, rootNavigator: true);
                        try {
                          await RaceService.instance.unlinkUserFromRace(race.raceId, userId);
                          nav.pop();
                          if (outerContext.mounted) ScaffoldMessenger.of(outerContext).showSnackBar(const SnackBar(content: Text('Corredor desvinculado'), backgroundColor: Colors.red));
                        } catch (e) {
                          nav.pop();
                          if (outerContext.mounted) ScaffoldMessenger.of(outerContext).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                        }
                      }
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('races').doc(widget.race.raceId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final race = RaceModel.fromMap(snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);
        final isFinishedOrArchived = race.status == 'finished' || race.status == 'archived';

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                // 1. Cabecera con Botón de Atrás y Título
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05), 
                                blurRadius: 10,
                              )
                            ],
                          ),
                          child: Icon(Icons.arrow_back_ios_new, color: theme.colorScheme.onSurface, size: 20),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          isFinishedOrArchived ? "Resultados de la Carrera" : "Corredores en Vivo",
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Barra de búsqueda
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Buscar por nombre o dorsal...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                ),
                
                // 3. Lista de Corredores (Estática si finalizó, en vivo si no)
                Expanded(
                  child: isFinishedOrArchived
                      ? _buildStaticFinishersList(theme, race)
                      : _buildLiveRunnersStream(theme, race),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildLiveRunnersStream(ThemeData theme, RaceModel race) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('activeRaceId', isEqualTo: race.raceId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Error al cargar corredores"));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final query = _searchController.text.toLowerCase().trim();
        final docs = (snapshot.data?.docs ?? []).where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final userName = (data['displayName'] ?? 'Desconocido').toString().toLowerCase();
          final bibNumber = (data['activeBibNumber'] ?? 'N/A').toString().toLowerCase();
          return userName.contains(query) || bibNumber.contains(query);
        }).toList();

        if (docs.isEmpty) return _buildNoRunnersPlaceholder(theme);

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final userId = docs[index].id;
            final userName = data['displayName'] ?? 'Desconocido';
            final bibNumber = data['activeBibNumber'] ?? 'N/A';
            final photoUrl = data['photoURL'];
            return _buildRunnerCard(userId, userName, bibNumber, photoUrl, null, theme, race: race);
          },
        );
      },
    );
  }

  Widget _buildStaticFinishersList(ThemeData theme, RaceModel race) {
    final query = _searchController.text.toLowerCase().trim();
    
    // Deduplicar corredores por userId, priorizando el resultado completado (no descalificado)
    final Map<String, dynamic> uniqueFinishersMap = {};
    for (final finisher in race.finishers) {
      final String uId = finisher['userId']?.toString() ?? '';
      if (uId.isEmpty) continue;
      
      final bool currentIsDisq = finisher['isDisqualified'] == true;
      if (!uniqueFinishersMap.containsKey(uId)) {
        uniqueFinishersMap[uId] = finisher;
      } else {
        final bool existingIsDisq = uniqueFinishersMap[uId]['isDisqualified'] == true;
        if (existingIsDisq && !currentIsDisq) {
          uniqueFinishersMap[uId] = finisher;
        }
      }
    }

    final finishers = uniqueFinishersMap.values.where((data) {
      final userName = (data['displayName'] ?? 'Desconocido').toString().toLowerCase();
      final bibNumber = (data['bibNumber'] ?? 'N/A').toString().toLowerCase();
      return userName.contains(query) || bibNumber.contains(query);
    }).toList();

    if (finishers.isEmpty) return _buildNoRunnersPlaceholder(theme);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: finishers.length,
      itemBuilder: (context, index) {
        final data = finishers[index];
        final userId = data['userId'] ?? '';
        final userName = data['displayName'] ?? 'Desconocido';
        final bibNumber = data['bibNumber'] ?? 'N/A';
        final photoUrl = data['photoUrl'];
        final isDisqualified = data['isDisqualified'] == true;
        final timeInSecs = data['timeInSeconds'] as int? ?? 0;
        
        String subtitleText = isDisqualified 
            ? "DESCALIFICADO" 
            : "Tiempo: ${Duration(seconds: timeInSecs).toString().split('.').first}";

        return _buildRunnerCard(userId, userName, bibNumber, photoUrl, subtitleText, theme, isDisqualified: isDisqualified, race: race);
      },
    );
  }

  Widget _buildNoRunnersPlaceholder(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_run_rounded, size: 60, color: theme.dividerColor),
          const SizedBox(height: 15),
          const Text("No hay corredores registrados", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildRunnerCard(String userId, String userName, String bibNumber, String? photoUrl, String? customSubtitle, ThemeData theme, {bool isDisqualified = false, required RaceModel race}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 0,
      color: theme.colorScheme.surface,
      child: ListTile(
        onTap: (race.status == 'finished' || race.status == 'archived') 
            ? null
            : () => _showRunnerOptions(context, userId, userName, bibNumber, race),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
          child: (photoUrl == null || photoUrl.isEmpty)
              ? Text(userName[0].toUpperCase(), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)) 
              : null,
        ),
        title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(customSubtitle ?? "ID: ${userId.length > 8 ? userId.substring(0, 8) : userId}..."),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDisqualified ? Colors.redAccent.withOpacity(0.2) : Colors.amber.withOpacity(0.2), 
            borderRadius: BorderRadius.circular(10)
          ),
          child: Text(
            isDisqualified ? "DESC" : "#$bibNumber", 
            style: TextStyle(
              color: isDisqualified ? Colors.redAccent : Colors.amber, 
              fontWeight: FontWeight.bold, 
              fontSize: 16
            )
          ),
        ),
      ),
    );
  }
}
