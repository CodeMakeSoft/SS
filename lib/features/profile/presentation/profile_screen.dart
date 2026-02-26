import 'package:flutter/material.dart';
import '../../auth/data/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;

  Future<void> _handleLinkGoogle() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuthService().linkWithGoogle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google vinculado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLinkFacebook() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuthService().linkWithFacebook();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Facebook vinculado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleUnlink(String providerId) async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuthService().unlinkProvider(providerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cuenta desvinculada ($providerId)'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuthService().currentUser;
    final theme = Theme.of(context);

    if (user == null) return const SizedBox.shrink();

    user.reload();
    final linkedProviders = user.providerData.map((e) => e.providerId).toList();
    bool hasGoogle = linkedProviders.contains('google.com');
    bool hasFacebook = linkedProviders.contains('facebook.com');

    String? displayPhoto = user.photoURL;
    String? displayName = user.displayName;

    // Fallback: If Firebase root user lacks photo but a linked provider has it
    if (displayPhoto == null || displayPhoto.isEmpty) {
      for (var provider in user.providerData) {
        if (provider.photoURL != null && provider.photoURL!.isNotEmpty) {
          displayPhoto = provider.photoURL;
          break;
        }
      }
    }

    // Fallback: If Firebase root lacks Name but a linked provider has it
    if (displayName == null || displayName.isEmpty) {
      for (var provider in user.providerData) {
        if (provider.displayName != null && provider.displayName!.isNotEmpty) {
          displayName = provider.displayName;
          break;
        }
      }
    }

    return IgnorePointer(
      ignoring: _isLoading,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA), // Light Tech Grey background
        appBar: AppBar(
          title: const Text(
            'ID de Usuario',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () {}, // Future feature
            ),
            if (_isLoading) const CircularProgressIndicator(),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              // USER CARD (Tech Style)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar with Ring
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundImage:
                            (displayPhoto != null && displayPhoto.isNotEmpty)
                            ? NetworkImage(displayPhoto)
                            : null,
                        backgroundColor: Colors.white24,
                        child: (displayPhoto == null || displayPhoto.isEmpty)
                            ? Text(
                                (displayName != null && displayName.isNotEmpty)
                                    ? displayName.substring(0, 1).toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 28,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Text Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (displayName != null && displayName.isNotEmpty)
                                ? displayName
                                : 'Usuario',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              fontFamily:
                                  'RobotoMono', // Tech font hint if available
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Status: Online',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // SECURITY SECTION
              const _SectionHeader(title: 'Seguridad y Vinculación'),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _TechListTile(
                      icon: Icons.g_mobiledata,
                      iconColor: Colors.red,
                      title: 'Google',
                      subtitle: hasGoogle ? 'Conectado' : 'Toca para vincular',
                      isLinked: hasGoogle,
                      onTap: () {
                        if (hasGoogle) {
                          _handleUnlink('google.com');
                        } else {
                          _handleLinkGoogle();
                        }
                      },
                    ),
                    const Divider(height: 1),
                    _TechListTile(
                      icon: Icons.facebook,
                      iconColor: const Color(0xFF1877F2),
                      title: 'Facebook',
                      subtitle: hasFacebook
                          ? 'Conectado'
                          : 'Toca para vincular',
                      isLinked: hasFacebook,
                      onTap: () {
                        if (hasFacebook) {
                          _handleUnlink('facebook.com');
                        } else {
                          _handleLinkFacebook();
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // SETTINGS SECTION
              const _SectionHeader(title: 'Sistema'),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.black87,
                        ),
                      ),
                      title: const Text('Notificaciones'),
                      trailing: Switch(value: true, onChanged: (v) {}),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.logout, color: Colors.red),
                      ),
                      title: const Text(
                        'Cerrar Sesión',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () async {
                        await FirebaseAuthService().signOut();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              Center(
                child: Text(
                  'v1.0.0 • SmartSync Tech',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _TechListTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isLinked;
  final VoidCallback onTap;

  const _TechListTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isLinked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: isLinked ? Colors.green : Colors.grey),
      ),
      trailing: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isLinked
              ? Colors.green.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
        ),
        child: Icon(
          isLinked ? Icons.check : Icons.add,
          color: isLinked ? Colors.green : Colors.grey,
          size: 16,
        ),
      ),
    );
  }
}
