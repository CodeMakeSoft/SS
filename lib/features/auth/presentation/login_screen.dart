import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/firebase_auth_service.dart';
import '../domain/auth_service.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'dart:io';
import 'widgets/wave_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(Future<User?> Function() loginMethod) async {
    setState(() => _isLoading = true);
    try {
      final user = await loginMethod();
      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Bienvenido!')),
        );
      }
    } on AuthLinkingException catch (e){
      if(mounted) {
        _showLinkingDialog(e);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = 'Error de autenticación';
        if (e.code == 'user-not-allowed') {
          message = e.message ?? 'Usuario no permitido';
        } else if (e.code == 'user-not-found' || e.code == 'wrong-password') {
          message = 'Correo o contraseña incorrectos';
        } else if (e.code == 'network-request-failed') {
          message = 'Error de conexión';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onEmailLoginPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      _handleLogin(() => _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      ));
    }
  }

  void _showLinkingDialog(AuthLinkingException e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cuenta ya existente'),
        content: Text('El correo ${e.email} ya está registrado con Google.\n¿Quieres vincular tu Facebook a esa cuenta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _performLinking(e);
            },
            child: const Text('Sí, vincular'),
          ),
        ],
      ),
    );
  }
  // Ejecuta la vinculación real
  Future<void> _performLinking(AuthLinkingException e) async {
    setState(() => _isLoading = true);
    stderr.writeln("DEBUG: _performLinking iniciado - stderr");
    try {
      // 1. Iniciamos sesión con el proveedor original (Google)
      final user = await _authService.signInWithGoogle();
      stderr.writeln("DEBUG: Google Login completado. Usuario: ${user?.email}");
      
      if (user != null) {
        // 2. Intentamos obtener una credencial FRESCA de Facebook
        AuthCredential credentialToLink = e.credential;
        
        try {
          final AccessToken? currentToken = await FacebookAuth.instance.accessToken;
          if (currentToken != null) {
            stderr.writeln("DEBUG: Token de Facebook fresco obtenido.");
            credentialToLink = FacebookAuthProvider.credential(currentToken.tokenString);
          } else {
            stderr.writeln("DEBUG: No se pudo refrescar el token de Facebook (usando el del error).");
          }
        } catch (tokenError) {
           stderr.writeln("DEBUG: Error obteniendo token facebook: $tokenError");
        }

        // 3. GUARDAMOS la credencial para vincularla en el Skeleton/Home
        //    (Evitamos race condition al cambiar de pantalla)
        FirebaseAuthService.pendingLinkingCredential = credentialToLink;
        stderr.writeln("DEBUG: Credencial guardada en pendingLinkingCredential. Redirigiendo...");
        
        // El StreamBuilder en main.dart detectará el cambio de usuario y navegará.
        // La vinculación ocurrirá en main_skeleton.dart
      }
    } catch (error) {
      stderr.writeln("DEBUG: Excepción general en _performLinking: $error");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Waves
          Positioned.fill(
            child: CustomPaint(
              painter: WavePainter(color: theme.colorScheme.primary),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // LOGO Placeholder
                      Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'assets/images/logo.png', // Make sure to place your logo here!
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'SmartSync',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Ingresa tu correo',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu correo';
                          }
                          if (!value.contains('@')) {
                            return 'Ingresa un correo válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Ingresa tu contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu contraseña';
                          }
                          if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      
                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: Implement forgot password flow
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Funcionalidad pendiente')),
                            );
                          },
                          child: const Text('¿Olvidaste tu contraseña?'),
                        ),
                      ),
                      
                      const SizedBox(height: 24),

                      // Login Button
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        ElevatedButton(
                          onPressed: _onEmailLoginPressed,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30), // Pill shape
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            'Ingresar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      const SizedBox(height: 40),
                      
                      // Social Login Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[400])),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'O también',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey[400])),
                        ],
                      ),
                      
                      const SizedBox(height: 24),

                      // Social Buttons Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _CircularSocialButton(
                            icon: Icons.g_mobiledata, // Replace with SVG asset later
                            color: Colors.red,
                            label: 'G',
                            onTap: () => _handleLogin(_authService.signInWithGoogle),
                          ),
                          const SizedBox(width: 30),
                          _CircularSocialButton(
                            icon: Icons.facebook,
                            color: const Color(0xFF1877F2),
                            label: 'F',
                            onTap: () => _handleLogin(_authService.signInWithFacebook),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40), // Bottom spacing
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
}

class _CircularSocialButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String label;

  const _CircularSocialButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Center(
          // For now using Icon, but ideally use SvgPicture.asset
           child: Icon(icon, color: color, size: 32),
        ),
      ),
    );
  }
}
