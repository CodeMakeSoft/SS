import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRacesScreen extends StatelessWidget {
  const AdminRacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('races')
            .where('status', isEqualTo: 'active')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final races = snapshot.data!.docs;
          
          if (races.isEmpty) {
            return const Center(
              child: Text("No hay carreras activas", style: TextStyle(color: Colors.white70)),
            );
          }

          // Si solo hay una carrera, podrías mostrar el mapa directamente. 
          // Si hay varias, mostramos una lista elegante.
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: races.length,
            itemBuilder: (context, index) {
              final race = races[index].data() as Map<String, dynamic>;
              return Card(
                color: const Color(0xFF1E293B),
                child: ListTile(
                  title: Text(race['name'] ?? 'Carrera Sin Nombre', style: const TextStyle(color: Colors.white)),
                  subtitle: Text("Status: ${race['status']}", style: const TextStyle(color: Colors.cyanAccent)),
                  trailing: const Icon(Icons.map, color: Colors.white70),
                  onTap: () {
                    // Abrir mapa específico de esta carrera
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
