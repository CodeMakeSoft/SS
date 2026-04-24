import 'package:flutter/material.dart';
import '../data/models/race_model.dart';

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
                  
                  // Título estilizado
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
            // --- FIN DE LA CABECERA ---

            // Barra de Búsqueda Premium
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
            
            // Área de la lista
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_run_rounded, size: 60, color: theme.dividerColor),
                    const SizedBox(height: 15),
                    const Text(
                      "Conectando base de datos...", 
                      style: TextStyle(color: Colors.grey)
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
