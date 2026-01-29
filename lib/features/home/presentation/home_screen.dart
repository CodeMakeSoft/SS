
import 'package:flutter/material.dart';
import '../../auth/data/firebase_auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartSync Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuthService().signOut();
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Bienvenido al sistema de carreras'),
      ),
    );
  }
}
