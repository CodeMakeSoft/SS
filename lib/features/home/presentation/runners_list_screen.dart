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

  void _showDeleteConfirmation(BuildContext context, {
    required String title,
    required String description,
    required VoidCallback onConfirm,
  }) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 36),
              ),
              const SizedBox(height: 20),
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
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancelar', style: TextStyle(color: theme.colorScheme.onSurface)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
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

  void _showRunnerOptions(BuildContext context, String userId, String userName, String currentBib) {
    final TextEditingController bibController = TextEditingController(text: currentBib);
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) {
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
                    if (bibController.text.trim().isEmpty) return;
                    Navigator.pop(context); 
                    await RaceService.instance.linkUserToRace(widget.race.raceId, userId, bibController.text.trim());
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dorsal actualizado')));
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
                    Navigator.pop(context);
                    _showDeleteConfirmation(
                      context, 
                      title: '¿Expulsar corredor?', 
                      description: 'Estás a punto de desvincular a $userName de la carrera. Se liberará su dorsal.', 
                      onConfirm: () async {
                        await RaceService.instance.unlinkUserFromRace(widget.race.raceId, userId);
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Corredor desvinculado'), backgroundColor: Colors.red));
                      }
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
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
                            blurRadius: 10
                          )
                        ],
                      ),
                      child: Icon(Icons.arrow_back_ios_new, color: theme.colorScheme.onSurface, size: 20),
                    ),
                  ),
                  const SizedBox(width: 15),
                  
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05), 
                            blurRadius: 10
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "LISTA DE CORREDORES", 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                          ),
                          Text(
                            widget.race.name.toUpperCase(),
                            style: TextStyle(fontSize: 10, color: theme.colorScheme.primary, letterSpacing: 1.1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

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
                    // TODO: Filtro
                  },
                ),
              ),
            ),
            
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('activeRaceId', isEqualTo: widget.race.raceId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error al cargar corredores"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data?.docs ?? [];
                  
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_run_rounded, size: 60, color: theme.dividerColor),
                          const SizedBox(height: 15),
                          const Text("No hay corredores vinculados", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final userId = docs[index].id;
                      final userName = data['displayName'] ?? 'Desconocido';
                      final bibNumber = data['activeBibNumber'] ?? 'N/A';
                      final photoUrl = data['photoURL'];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                        color: theme.colorScheme.surface,
                        child: ListTile(
                          onTap: () => _showRunnerOptions(context, userId, userName, bibNumber),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                            child: photoUrl == null 
                              ? Text(userName[0].toUpperCase(), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)) 
                              : null,
                          ),
                          title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("ID: ${userId.substring(0, 8)}..."),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                            child: Text("#$bibNumber", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      );
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
}
