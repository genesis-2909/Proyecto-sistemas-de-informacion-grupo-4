import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_view.dart';
import '../theme/eco_theme.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isSavingName = false;
  bool _isUpdatingPassword = false;
  bool _obscurePassword = true;

  late Future<DocumentSnapshot> _perfilUsuarioFuture;

  @override
  void initState() {
    super.initState();
    _obtenerPerfil();
  }

  void _obtenerPerfil() {
    if (_user != null) {
      setState(() {
        _perfilUsuarioFuture = FirebaseFirestore.instance
            .collection('usuarios')
            .doc(_user.uid)
            .get();
      });
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _guardarNombre() async {
    if (_user == null || _nombreController.text.trim().isEmpty) return;

    setState(() => _isSavingName = true);

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_user.uid)
          .update({
        'nombre_completo': _nombreController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Nombre actualizado con éxito!'),
            backgroundColor: EcoTheme.forestGreen,
          ),
        );
        _obtenerPerfil(); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingName = false);
    }
  }

  Future<void> _actualizarPassword() async {
    if (_user == null || _passwordController.text.trim().isEmpty) return;

    if (_passwordController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contraseña debe tener al menos 6 caracteres.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isUpdatingPassword = true);

    try {
      await _user.updatePassword(_passwordController.text.trim());
      _passwordController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Contraseña cambiada con éxito!'),
            backgroundColor: EcoTheme.forestGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de seguridad. Reautentique e intente de nuevo: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingPassword = false);
    }
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoTheme.warmCream,
      body: _user == null
          ? const Center(child: Text('Sesión no encontrada.'))
          : FutureBuilder<DocumentSnapshot>(
              future: _perfilUsuarioFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: EcoTheme.forestGreen),
                  );
                }

                String nombreCompleto = 'Usuario Unimet';
                String rolActual = 'Viajero';
                String estadoSolicitud = '';
                String rolSolicitado = '';

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  nombreCompleto = data['nombre_completo'] ?? nombreCompleto;
                  rolActual = (data['rol'] ?? data['tipo_usuario'] ?? 'Viajero').toString();
                  estadoSolicitud = (data['estado_solicitud'] ?? '').toString();
                  rolSolicitado = (data['rol_solicitado'] ?? '').toString();

                  if (_nombreController.text.isEmpty) {
                    _nombreController.text = nombreCompleto;
                  }
                }

                final bool esAdministrador = rolActual.trim().toLowerCase() == 'administrador';

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // 🔔 NOTIFICACIÓN VISUAL: SOLICITUD RECHAZADA
                        if (estadoSolicitud.toLowerCase() == 'rechazado') ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline_rounded, color: Colors.red.shade900, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Solicitud de Rol Rechazada',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900, fontSize: 14),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Tu petición para el rol de "$rolSolicitado" no fue aprobada por el administrador central.',
                                        style: TextStyle(color: Colors.red.shade800, fontSize: 12, height: 1.3),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                        ],

                        // ⏳ NOTIFICACIÓN VISUAL: PENDIENTE DE APROBACIÓN
                        if (estadoSolicitud.toLowerCase() == 'pendiente de aprobación') ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.hourglass_empty_rounded, color: Colors.amber, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Tu solicitud para ser "$rolSolicitado" está bajo revisión del Administrador.',
                                    style: TextStyle(color: Colors.amber.shade900, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                        ],

                        const SizedBox(height: 10),
                        const CircleAvatar(
                          radius: 45,
                          backgroundColor: EcoTheme.forestGreen,
                          child: Icon(Icons.person, size: 45, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        
                        Text(
                          nombreCompleto, 
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: EcoTheme.darkForest),
                        ),
                        
                        Text(
                          rolActual.toUpperCase(), 
                          style: const TextStyle(fontSize: 12, color: EcoTheme.ecoGold, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 30),
                        
                        TextFormField(
                          controller: _nombreController,
                          enabled: !esAdministrador, 
                          decoration: InputDecoration(
                            labelText: 'Nombre Completo', 
                            prefixIcon: const Icon(Icons.face),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        if (!esAdministrador) ...[
                          _isSavingName 
                              ? const CircularProgressIndicator(color: EcoTheme.forestGreen)
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 45),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: _guardarNombre,
                                  child: const Text('Actualizar Nombre'),
                                ),
                          const SizedBox(height: 20),
                        ] else ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                            child: Text(
                              'Los privilegios de la cuenta administradora no permiten modificaciones nominales directas.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        
                        const Divider(),
                        const SizedBox(height: 15),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Nueva Contraseña',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _isUpdatingPassword 
                            ? const CircularProgressIndicator(color: EcoTheme.forestGreen)
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: EcoTheme.darkForest,
                                  minimumSize: const Size(double.infinity, 45),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _actualizarPassword,
                                child: const Text('Cambiar Contraseña'),
                              ),

                        const SizedBox(height: 40),
                        
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade900,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _cerrarSesion(context),
                          icon: const Icon(Icons.power_settings_new_rounded),
                          label: const Text('CERRAR SESIÓN', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}