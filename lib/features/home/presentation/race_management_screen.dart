import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../data/models/race_model.dart';
import '../data/race_service.dart';
import 'runners_list_screen.dart';
import 'qr_scanner_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RaceManagementScreen extends StatefulWidget {
  final RaceModel race;
  const RaceManagementScreen({super.key, required this.race});

  @override
  State<RaceManagementScreen> createState() => _RaceManagementScreenState();
}

class _RaceManagementScreenState extends State<RaceManagementScreen> {
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();

   void _showBibAssignmentModal(String scannedUid, String runnerName) {
    final TextEditingController bibController = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              mainAxisSize: MainAxisSize.min, 
              children: [
                Text("ASIGNAR DORSAL", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 20),
                
                // Perfil Cargado
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    children: [
                      CircleAvatar(backgroundColor: theme.colorScheme.primary, child: Text(runnerName.isNotEmpty ? runnerName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 15),
                      Expanded(child: Text(runnerName, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface))),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                TextField(
                  controller: bibController,
                  keyboardType: TextInputType.number,
                  autofocus: true, 
                  decoration: InputDecoration(
                    labelText: 'Dorsal',
                    prefixIcon: const Icon(Icons.confirmation_number_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                const SizedBox(height: 20),
                
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
                      
                      await RaceService.instance.linkUserToRace(widget.race.raceId, scannedUid, bibController.text.trim());
                      
                      if (context.mounted) {
                        Navigator.pop(context); 
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$runnerName vinculado (Dorsal #${bibController.text.trim()})'), backgroundColor: Colors.green));
                      }
                    },
                    child: const Text('Confirmar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  void _showActionConfirmation(BuildContext context, {
    required String title,
    required String description,
    required String confirmText,
    required Color color,
    required IconData icon,
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
              // Círculo con ícono gigante en el centro
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 36),
              ),
              const SizedBox(height: 20),
              
              // Título
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 10),
              
              // Descripción / Advertencia
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 14),
              ),
              const SizedBox(height: 24),
              
              // Botones Cancelar / Confirmar
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
                        backgroundColor: color,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Cierra el modal
                        onConfirm(); // Ejecuta la función que le pasemos
                      },
                      child: Text(confirmText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(19.4326, -99.1332),
              zoom: 14,
            ),
            onMapCreated: (controller) => _mapController.complete(controller),
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
          ),

          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.1), blurRadius: 10)],
                    ),
                    child: Icon(Icons.arrow_back_ios_new, color: theme.colorScheme.onSurface, size: 20),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10)],
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.analytics_outlined, color: Colors.blueAccent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.race.name.toUpperCase(),
                            style: TextStyle(
                              color: theme.colorScheme.onSurface, 
                              fontWeight: FontWeight.bold, 
                              letterSpacing: 1.1,
                              fontSize: 14
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: theme.scaffoldBackgroundColor,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                              ),
                              builder: (context) {
                                return SafeArea(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [

                                        Container(
                                          width: 40,
                                          height: 5,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        
                                        Text(
                                          "Gestión de la carrera",
                                          style: TextStyle(
                                            fontSize: 18, 
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 15),
                                        ListTile(
                                          leading: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), shape: BoxShape.circle),
                                            child: const Icon(Icons.people_alt, color: Colors.blueAccent),
                                          ),
                                          title: const Text("Lista de Corredores", style: TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: const Text("Ver y administrar participantes"),
                                          onTap: () {
                                            Navigator.pop(context);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => RunnersListScreen(race: widget.race),
                                              ),
                                            );
                                          },
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 20),
                                          child: Divider(),
                                        ),
                                        ListTile(
                                          leading: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(color: Colors.deepPurple.withOpacity(0.1), shape: BoxShape.circle),
                                            child: const Icon(Icons.settings, color: Colors.deepPurple),
                                          ),
                                          title: const Text("Opciones de Carrera", style: TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: const Text("Editar detalles"),
                                          onTap: () {
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          child: SizedBox(
                            width: 34,
                            height: 34,
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit, color: Colors.white, size: 18),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.4 : 0.15), blurRadius: 20)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.race.status.toUpperCase(), 
                        style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 10)),
                      Text("GESTIÓN EN VIVO", 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface)),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: theme.scaffoldBackgroundColor,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                            ),
                            builder: (context) {
                              return SafeArea(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      
                                      Text(
                                        "Control de Carrera",
                                        style: TextStyle(
                                          fontSize: 18, 
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 15),

                                      ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                                          child: const Icon(Icons.play_arrow, color: Colors.green),
                                        ),
                                        title: const Text("Iniciar Carrera", style: TextStyle(fontWeight: FontWeight.bold)),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _showActionConfirmation(
                                            context,
                                            title: '¿Iniciar Carrera?',
                                            description: 'Esta acción comenzará el cronómetro oficial y cambiará el estado de la carrera a "En Curso".',
                                            confirmText: 'Iniciar',
                                            color: Colors.green,
                                            icon: Icons.play_arrow,
                                            onConfirm: () {
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Carrera Iniciada')));
                                            },
                                          );
                                        }
                                      ),
                                      
                                      ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                                          child: const Icon(Icons.pause, color: Colors.orange),
                                        ),
                                        title: const Text("Pausar Carrera", style: TextStyle(fontWeight: FontWeight.bold)),
                                        onTap: () {
                                          Navigator.pop(context); 
                                          
                                          _showActionConfirmation(
                                            context,
                                            title: '¿Pausar Carrera?',
                                            description: 'Se detendrá el cronómetro temporalmente. Podrás reanudarlo después.',
                                            confirmText: 'Pausar',
                                            color: Colors.orange,
                                            icon: Icons.pause,
                                            onConfirm: () {
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Carrera Pausada')));
                                            },
                                          );
                                        }
                                      ),
                                      ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                                          child: const Icon(Icons.stop, color: Colors.red),
                                        ),
                                        title: const Text("Terminar Carrera", style: TextStyle(fontWeight: FontWeight.bold)),
                                        onTap: () {
                                          Navigator.pop(context); 
                                          
                                          _showActionConfirmation(
                                            context,
                                            title: '¿Terminar Carrera?',
                                            description: '¡Atención! Esta acción es irreversible. Finalizará la recolección de tiempos.',
                                            confirmText: 'Finalizar',
                                            color: Colors.red,
                                            icon: Icons.stop,
                                            onConfirm: () {
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Carrera Finalizada')));
                                            },
                                          );
                                        },
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 20),
                                        child: Divider(), 
                                      ),

                                      ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), shape: BoxShape.circle),
                                          child: const Icon(Icons.campaign, color: Colors.blueAccent),
                                        ),
                                        title: const Text("Crear Aviso", style: TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: const Text("Enviar notificación push a todos"),
                                        onTap: () {
                                          Navigator.pop(context);
                                          // TODO: Abrir otro dialog para escribir el aviso
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.all(14),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Icon(Icons.route),
                      ),
                      
                      const SizedBox(width: 10),
                      
                      ElevatedButton(
                        onPressed: () async {
                          final scannedUid = await showDialog(
                            context: context,
                            builder: (context) => const QrScannerScreen(),
                          );
                          if (scannedUid != null && scannedUid is String) {
                            showDialog(
                              context: context, barrierDismissible: false,
                              builder: (_) => const Center(child: CircularProgressIndicator()),
                            );
                            try {
                              final doc = await FirebaseFirestore.instance.collection('users').doc(scannedUid).get();
                              
                              if (context.mounted) Navigator.pop(context); 
                              if (!doc.exists) {
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario no encontrado'), backgroundColor: Colors.redAccent));
                                return;
                              }
                              final userData = doc.data() as Map<String, dynamic>;
                              final runnerName = userData['displayName'] ?? 'Sin nombre';
                              if (context.mounted) {
                                _showBibAssignmentModal(scannedUid, runnerName);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                Navigator.pop(context); 
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de conexión')));
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.all(14),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Icon(Icons.qr_code_scanner),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
