import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import '../auth/data/firebase_auth_service.dart';
import '../home/presentation/home_screen.dart';
import '../profile/presentation/profile_screen.dart';
import '../home/presentation/admin_races_screen.dart';
import '../home/presentation/admin_management_screen.dart';
import '../stats/presentation/stats_screen.dart';
import '../home/providers/user_provider.dart';
import 'package:provider/provider.dart';

class MainSkeleton extends StatefulWidget {
  const MainSkeleton({super.key});

  @override
  State<MainSkeleton> createState() => _MainSkeletonState();
}

class _MainSkeletonState extends State<MainSkeleton> {
  int _currentIndex = 0;
  final FirebaseAuthService _authService = FirebaseAuthService();

  final List<Widget> _screensUserAndTrial = [
    const HomeScreen(),
    const StatsScreen(),
    const ProfileScreen(),
  ];

  final List<Widget> _screensAdmins = [
    const AdminRacesScreen(),
    const AdminManagementScreen(),
    const ProfileScreen(),
  ];

  final List<Widget> _screensSudo = [
    const ProfileScreen(),
    //Pending to development and defining this part
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
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.userData;
    final bool isAdmin = user?.role == 'admin' || user?.role == 'super_admin';
    final bool isSudo = user?.role == 'sudo';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final List<Widget> currentScreens = isSudo 
    ? _screensSudo 
    : (isAdmin ? _screensAdmins : _screensUserAndTrial);
    if(_currentIndex >= currentScreens.length) {
      _currentIndex = 0;
    }
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: currentScreens,
          ),
          
          // Custom Tech Navigation Bar - Dinámica
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (isSudo)
                        _buildNavItem(0, Icons.person_outline, Icons.person, "Perfil")
                      else if (isAdmin) ...[
                        _buildNavItem(0, Icons.radar, Icons.radar_sharp, "Carreras"),
                        _buildNavItem(1, Icons.settings_suggest_outlined, Icons.settings_suggest, "Gestión"),
                        _buildNavItem(2, Icons.person_outline, Icons.person, "Perfil"),
                      ] else ...[
                        _buildNavItem(0, Icons.map_outlined, Icons.map, "Mapa"),
                        _buildNavItem(1, Icons.bar_chart_outlined, Icons.bar_chart, "Stats"),
                        _buildNavItem(2, Icons.person_outline, Icons.person, "Perfil"),
                      ],
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
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 20 : 10, vertical: 8),
        decoration: isSelected 
            ? BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? iconFilled : iconOutlined,
              color: isSelected 
                ? theme.colorScheme.primary 
                : theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
