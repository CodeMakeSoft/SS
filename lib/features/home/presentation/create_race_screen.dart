import 'package:flutter/material.dart';
import '../data/race_service.dart';
import '../data/models/race_model.dart';
import '../../auth/data/firebase_auth_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'route_designer_screen.dart';

class CreateRaceScreen extends StatefulWidget {
  const CreateRaceScreen({super.key});

  @override
  State<CreateRaceScreen> createState() => _CreateRaceScreenState();
}

class _CreateRaceScreenState extends State<CreateRaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _tagController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  List<String> _tags = [];
  bool _isLoading = false;
  List<LatLng> _routePoints = [];

  void _addTag() {
    if (_tags.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo 10 tags permitidos'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF0D47A1),
              onPrimary: Colors.white,
              onSurface: const Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectDuration(BuildContext context) async {
    Duration initialDuration = const Duration(hours: 2, minutes: 0);
    if (_durationController.text.isNotEmpty) {
      final regex = RegExp(r'(?:(\d+)h)?\s*(?:(\d+)m)?');
      final match = regex.firstMatch(_durationController.text);
      if (match != null) {
        final hours = int.tryParse(match.group(1) ?? '') ?? 0;
        final minutes = int.tryParse(match.group(2) ?? '') ?? 0;
        initialDuration = Duration(hours: hours, minutes: minutes);
      }
    }
    Duration tempDuration = initialDuration;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: 300,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                      ),
                      const Text('Duración', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            String h = tempDuration.inHours > 0 ? '${tempDuration.inHours}h ' : '';
                            String m = (tempDuration.inMinutes % 60) > 0 ? '${tempDuration.inMinutes % 60}m' : '';
                            _durationController.text = (h + m).trim();
                            if (_durationController.text.isEmpty) _durationController.text = '0m';
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Guardar', style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.hm,
                    initialTimerDuration: initialDuration,
                    onTimerDurationChanged: (Duration newDuration) {
                      tempDuration = newDuration;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _createRace() async {
    if (!_formKey.currentState!.validate()) return;
    if (_routePoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes definir la ruta en el mapa'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuthService().currentUser;
      if (user == null) throw Exception("No hay usuario autenticado");

      final newRace = RaceModel(
        raceId: "race_${DateTime.now().millisecondsSinceEpoch}",
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        status: 'upcoming',
        date: _selectedDate,
        creatorUid: user.uid,
        tags: _tags,
        estimatedDuration: _durationController.text.trim(),
      );

      await RaceService.instance.createRace(newRace);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evento creado con éxito'),
            backgroundColor: Colors.green,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Configurar Evento', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Información General"),
                  _buildTextField(
                    controller: _nameController,
                    label: "Nombre del Evento",
                    icon: Icons.emoji_events_outlined,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "El nombre es obligatorio";
                      if (v.trim().length > 50) return "Máximo 50 caracteres";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _descriptionController,
                    label: "Descripción Detallada",
                    icon: Icons.description_outlined,
                    maxLines: 3,
                    validator: (v) {
                      if (v != null && v.trim().length > 300) {
                        return "Máximo 300 caracteres (te pasaste por ${v.length - 300})";
                      }
                      return null; 
                    },
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle("Logística y Tiempo"),
                  Row(
                    children: [
                      Expanded(
                        child: _buildClickableField(
                          label: "Fecha",
                          value: DateFormat('dd/MM/yyyy').format(_selectedDate),
                          icon: Icons.calendar_month_outlined,
                          onTap: () => _selectDate(context),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildClickableField(
                          label: "Duración",
                          value: _durationController.text.isEmpty ? "Opcional" : _durationController.text,
                          icon: Icons.timer_outlined,
                          onTap: () => _selectDuration(context),
                          onClear: () {
                            setState(() {
                              _durationController.clear();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle("Tags del Evento"),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _tagController,
                          label: "Agregar Tag",
                          hint: "ej. Trail, 10K...",
                          icon: Icons.label_outline,
                          onFieldSubmitted: (_) => _addTag(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filled(
                        onPressed: _addTag,
                        icon: const Icon(Icons.add),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF0D47A1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _tags.map((tag) => Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 12, color: Colors.white)),
                      backgroundColor: const Color(0xFF1E293B),
                      deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white70),
                      onDeleted: () => setState(() => _tags.remove(tag)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide.none,
                    )).toList(),
                  ),

                  const SizedBox(height: 32),
                  _buildSectionTitle("Ruta de Carrera"),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _routePoints.isEmpty ? theme.cardColor : theme.colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _routePoints.isEmpty ? theme.dividerColor : theme.colorScheme.primary),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _routePoints.isEmpty ? Icons.map_outlined : Icons.check_circle_outline, 
                          size: 40, 
                          color: _routePoints.isEmpty ? theme.colorScheme.onSurface.withOpacity(0.3) : theme.colorScheme.primary
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _routePoints.isEmpty ? "Diseñar ruta" : "Ruta Lista (${_routePoints.length} puntos)",
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: _routePoints.isEmpty ? theme.colorScheme.onSurface.withOpacity(0.7) : theme.colorScheme.primary
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RouteDesignerScreen(initialRoute: _routePoints),
                              ),
                            );
                            if (result != null && result is List<LatLng>) {
                              setState(() {
                                _routePoints = result;
                              });
                            }
                          }, 
                          icon: Icon(_routePoints.isEmpty ? Icons.edit_location_alt_outlined : Icons.edit),
                          label: Text(_routePoints.isEmpty ? "Definir Ruta" : "Editar Ruta"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            side: BorderSide(color: theme.colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        height: 60,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _createRace,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D47A1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            shadowColor: const Color(0xFF0D47A1).withOpacity(0.4),
          ),
          child: const Text(
            'LANZAR EVENTO',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

 Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        onFieldSubmitted: onFieldSubmitted,
        style: TextStyle(color: theme.colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
          hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
          prefixIcon: Icon(icon, color: theme.colorScheme.primary, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: theme.cardColor,
        ),
      ),
    );
  }

  Widget _buildClickableField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                ],
              ),
            ),
            if (onClear != null && value != "Opcional")
              GestureDetector(
                onTap: onClear,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.red, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
