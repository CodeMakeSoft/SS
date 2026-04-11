
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/firebase_auth_service.dart';
import '../domain/auth_service.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'dart:io';
// For simple blur logic if needed, or stick to simpler opacity

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
    final isDark = theme.brightness == Brightness.dark;
    
    // Dynamic Colors based on Mode
    final bgColor1 = isDark ? theme.colorScheme.primary.withOpacity(0.8) : const Color(0xFFF5F7FA);
    final bgColor2 = isDark ? const Color(0xFF000000) : Colors.white;
    final textColor = isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF0F172A);
    final subTextColor = isDark ? Colors.white.withOpacity(0.6) : const Color(0xFF64748B);
    final cardColor = isDark ? Colors.white.withOpacity(0.08) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. Tech Background (Adaptive Gradient)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bgColor1, bgColor2],
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
                          color: isDark ? Colors.white.withOpacity(0.1) : theme.colorScheme.primary.withOpacity(0.05),
                          border: Border.all(color: borderColor, width: 1),
                          boxShadow: [
                             BoxShadow(
                               color: theme.colorScheme.secondary.withOpacity(isDark ? 0.3 : 0.1),
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
                          letterSpacing: 4.0,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '¡BIENVENIDO!',
                        style: TextStyle(
                          fontSize: 12,
                          color: subTextColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      
                      const SizedBox(height: 48),

                      // ADAPTIVE CARD FORM
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: borderColor),
                          boxShadow: isDark ? [] : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _TechInputField(
                                isDark: isDark,
                                controller: _emailController,
                                label: 'Correo Electrónico',
                                icon: Icons.email_outlined,
                                validator: (val) => (val == null || !val.contains('@')) ? 'Correo inválido' : null,
                              ),
                              const SizedBox(height: 16),
                              
                              _TechInputField(
                                isDark: isDark,
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
                                  onPressed: () {},
                                  child: Text('Recuperar clave', 
                                    style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              if (_isLoading)
                                Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
                              else
                                ElevatedButton(
                                  onPressed: _onEmailLoginPressed,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    elevation: isDark ? 0 : 5,
                                    shadowColor: theme.colorScheme.primary.withOpacity(0.3),
                                  ),
                                  child: const Text('INGRESAR', 
                                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      Row(
                        children: [
                          Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('o continúa con', style: TextStyle(color: subTextColor, fontSize: 13)),
                          ),
                          Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           _SocialLoginButton(
                             icon: Icons.g_mobiledata,
                             color: Colors.white,
                             bgColor: const Color(0xFFDB4437), 
                             onTap: () => _handleLogin(_authService.signInWithGoogle),
                           ),
                           const SizedBox(width: 24),
                           _SocialLoginButton(
                             icon: Icons.facebook,
                             color: Colors.white,
                             bgColor: const Color(0xFF1877F2),
                             onTap: () => _handleLogin(_authService.signInWithFacebook),
                           ),
                        ],
                      ),
                      const SizedBox(height: 30),
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
  final bool isDark;
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final bool isObscure;
  final VoidCallback? onToggleVisibility;
  final String? Function(String?) validator;

  const _TechInputField({
    required this.isDark,
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
    final theme = Theme.of(context);
    final inputTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final fillColor = isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC);
    final labelColor = isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF64748B);

    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      style: TextStyle(color: inputTextColor, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: labelColor, fontSize: 14),
        prefixIcon: Icon(icon, color: labelColor.withOpacity(0.8), size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, 
                  color: labelColor, size: 20),
                onPressed: onToggleVisibility,
              )
            : null,
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
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
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
