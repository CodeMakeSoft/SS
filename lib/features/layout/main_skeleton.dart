
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import '../auth/data/firebase_auth_service.dart';
import '../home/presentation/home_screen.dart';
import '../profile/presentation/profile_screen.dart';
import '../stats/presentation/stats_screen.dart';

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
    const StatsScreen(),
    const ProfileScreen(),
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
    final theme = Theme.of(context);
    
    return Scaffold(
      extendBody: true, // Allows body to go behind the bar (Transparency)
      body: Stack(
        children: [
          // Main Content
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          
          // Custom Tech Navigation Bar
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.85), // Dark Tech Blue/Black
                borderRadius: BorderRadius.circular(35), // Rounded curves
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Glass Effect
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(0, Icons.map_outlined, Icons.map, "Mapa"),
                      _buildNavItem(1, Icons.bar_chart_outlined, Icons.bar_chart, "Stats"),
                      _buildNavItem(2, Icons.person_outline, Icons.person, "Perfil"),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData iconOutlined, IconData iconFilled, String label) {
    final bool isSelected = _currentIndex == index;
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 20 : 10, vertical: 8),
        decoration: isSelected 
            ? BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with Glow if selected
            Icon(
              isSelected ? iconFilled : iconOutlined,
              color: isSelected ? theme.colorScheme.secondary : Colors.grey[400],
              size: 26,
            ),
            
            // Label Animation
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
