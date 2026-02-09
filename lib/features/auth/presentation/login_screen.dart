
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/firebase_auth_service.dart';
import '../domain/auth_service.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'dart:io';
import 'dart:ui'; // For simple blur logic if needed, or stick to simpler opacity

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Fast, crisp animation (600ms)
    _animController = AnimationController(
       vsync: this, 
       duration: const Duration(milliseconds: 600),
    );
    
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    // Auto start
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
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
      barrierDismissible: false,
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
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface, // Matches theme background
      body: Stack(
        children: [
          // 1. Tech Background (Gradient)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primary.withOpacity(0.8),
                  const Color(0xFF000000), // Deep black bottom
                ],
              ),
            ),
          ),
          
          // 2. Center Content with Slide Animation
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // LOGO / BRAND
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                          boxShadow: [
                             BoxShadow(
                               color: theme.colorScheme.secondary.withOpacity(0.3),
                               blurRadius: 20,
                               spreadRadius: 5,
                             )
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      Text(
                        'SMARTSYNC',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3.0,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Acceso al Sistema',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.6),
                          letterSpacing: 1.0,
                        ),
                      ),
                      
                      const SizedBox(height: 48),

                      // GLASS CARD FORM
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08), // Glass Effect
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // EMAIL
                              _TechInputField(
                                controller: _emailController,
                                label: 'Correo Electrónico',
                                icon: Icons.email_outlined,
                                validator: (val) => (val == null || !val.contains('@')) ? 'Correo inválido' : null,
                              ),
                              const SizedBox(height: 16),
                              
                              // PASSWORD
                              _TechInputField(
                                controller: _passwordController,
                                label: 'Contraseña',
                                icon: Icons.lock_outline,
                                isPassword: true,
                                isObscure: _obscurePassword,
                                onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                                validator: (val) => (val == null || val.length < 6) ? 'Mínimo 6 caracteres' : null,
                              ),
                              
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    // TODO
                                  },
                                  child: Text('Recuperar clave', style: TextStyle(color: theme.colorScheme.secondary)),
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // LOGIN BUTTON
                              if (_isLoading)
                                const Center(child: CircularProgressIndicator(color: Colors.white))
                              else
                                ElevatedButton(
                                  onPressed: _onEmailLoginPressed,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.secondary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  child: const Text('INGRESAR', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      const Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white24)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('o continúa con', style: TextStyle(color: Colors.white54)),
                          ),
                          Expanded(child: Divider(color: Colors.white24)),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // SOCIAL BUTTONS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           _SocialLoginButton(
                             icon: Icons.g_mobiledata,
                             color: Colors.white,
                             bgColor: Colors.red[700]!, // Google Red
                             onTap: () => _handleLogin(_authService.signInWithGoogle),
                           ),
                           const SizedBox(width: 24),
                           _SocialLoginButton(
                             icon: Icons.facebook,
                             color: Colors.white,
                             bgColor: const Color(0xFF1877F2), // Facebook Blue
                             onTap: () => _handleLogin(_authService.signInWithFacebook),
                           ),
                        ],
                      ),
                      const SizedBox(height: 20),
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

class _TechInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final bool isObscure;
  final VoidCallback? onToggleVisibility;
  final String? Function(String?) validator;

  const _TechInputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.isObscure = false,
    this.onToggleVisibility,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
                onPressed: onToggleVisibility,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
        ),
      ),
      validator: validator,
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _SocialLoginButton({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
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
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}
