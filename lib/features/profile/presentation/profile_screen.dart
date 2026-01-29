
import 'package:flutter/material.dart';
import '../../auth/data/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuthService().currentUser;
    final theme = Theme.of(context);

    if (user == null) return const SizedBox.shrink();

    // Identificar proveedores vinculados
    final linkedProviders = user.providerData.map((e) => e.providerId).toList();
    bool hasGoogle = linkedProviders.contains('google.com');
    bool hasFacebook = linkedProviders.contains('facebook.com');
    bool hasPassword = linkedProviders.contains('password');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // AVATAR
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    child: user.photoURL == null
                        ? Text(
                            user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                        onPressed: () {
                          // TODO: Edit Profile
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // NAMES
            Text(
              user.displayName ?? 'Usuario sin nombre',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              user.email ?? 'Sin correo',
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
            
            const SizedBox(height: 40),

            // LINKED ACCOUNTS CARD
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cuentas Vinculadas',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _ProviderRow(
                      icon: Icons.g_mobiledata,
                      color: Colors.red,
                      label: 'Google',
                      isConnected: hasGoogle,
                    ),
                    const Divider(),
                    _ProviderRow(
                      icon: Icons.facebook,
                      color: const Color(0xFF1877F2),
                      label: 'Facebook',
                      isConnected: hasFacebook,
                    ),
                    const Divider(),
                    _ProviderRow(
                      icon: Icons.email,
                      color: Colors.orange,
                      label: 'Correo/Contraseña',
                      isConnected: hasPassword,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // SIGN OUT BUTTON
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                   await FirebaseAuthService().signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar Sesión'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool isConnected;

  const _ProviderRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            ),
          ),
          if (isConnected)
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 4),
                Text('Conectado', style: TextStyle(color: Colors.green, fontSize: 12)),
              ],
            )
          else
            const Text('No conectado', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
