import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../layout/main_skeleton.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _isLoading = false;

  Future<void> _requestPermission() async {
    setState(() => _isLoading = true);

    LocationPermission permission = await Geolocator.checkPermission();
    
    // Si no está concedido, lo pedimos
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // Si está denegado para siempre, le pedimos que abra configuración
    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoading = false);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Permiso Requerido"),
            content: const Text("Necesitas habilitar la ubicación desde la configuración de tu teléfono para poder participar."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Geolocator.openAppSettings();
                },
                child: const Text("Abrir Configuración"),
              )
            ],
          ),
        );
      }
      return;
    }

    // Si concedió el permiso, avanzamos a la App Principal (Skeleton)
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainSkeleton()),
        );
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Fondo Dark Tech
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono con efecto Glow
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.secondary.withOpacity(0.5),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 80,
                  color: theme.colorScheme.secondary, // Cyan Accent
                ),
              ),
              const SizedBox(height: 40),
              
              // Título
              const Text(
                "Precisión en Tiempo Real",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // Texto legal obligatorio (NO BORRAR para pasar validación de tiendas)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  "SmartSync recopila datos de ubicación para habilitar el rastreo de tu ruta en vivo durante la carrera.\n\n"
                  "Estos datos se envían a la base de datos oficial del evento de forma segura. El rastreo continuará y funcionará en segundo plano incluso si la app está cerrada o no está en uso mientras estés en una carrera activa.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[300],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),
              const SizedBox(height: 40),

              // Botón Principal
              _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 10,
                      ),
                      onPressed: _requestPermission,
                      child: const Text(
                        "Entendido y Continuar",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
