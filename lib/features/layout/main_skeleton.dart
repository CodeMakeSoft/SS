
import 'package:flutter/material.dart';
import 'dart:io';
import '../auth/data/firebase_auth_service.dart';
import '../home/presentation/home_screen.dart';

class MainSkeleton extends StatefulWidget {
  const MainSkeleton({super.key});

  @override
  State<MainSkeleton> createState() => _MainSkeletonState();
}

class _MainSkeletonState extends State<MainSkeleton> {
  int _currentIndex = 0;
  final FirebaseAuthService _authService = FirebaseAuthService();

  final List<Widget> _screens = [
    const HomeScreen(),
    const Center(child: Text("Perfil (Próximamente)")),
  ];

  @override
  void initState() {
    super.initState();
    // Check for pending linking operations after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingLinking();
    });
  }

  Future<void> _checkPendingLinking() async {
    final credential = FirebaseAuthService.pendingLinkingCredential;
    if (credential != null) {
      stderr.writeln("DEBUG: MainSkeleton detectó credencial pendiente. Intentando vincular...");
      
      // Clear the static field immediately to avoid double attempts
      FirebaseAuthService.pendingLinkingCredential = null;

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Finalizando vinculación de cuentas...'),
          duration: Duration(seconds: 2),
        ),
      );

      try {
        await _authService.linkCurrentUser(credential);
        
        // Force reload not strictly necessary if link methods return updated user, but good unique measure.
        // But linkCurrentUser logic already calls linkWithCredential.
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text('¡Cuentas vinculadas con éxito! 🎉'), 
               backgroundColor: Colors.green,
               duration: Duration(seconds: 4),
             ),
           );
        }
        stderr.writeln("DEBUG: Vinculación exitosa en Skeleton.");
      } catch (e) {
        stderr.writeln("DEBUG: Error vinculando en Skeleton: $e");
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error completando vinculación: $e'), backgroundColor: Colors.red),
           );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home), 
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
