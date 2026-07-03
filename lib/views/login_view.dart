import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/auth_controller.dart';
import 'register_view.dart';
import 'dashboard_navigation_view.dart';
import 'landing_view.dart';

enum UserRole { viajero, operador, administrador }

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  UserRole _selectedRole = UserRole.viajero;
  bool _isObscure = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _intentarLogin() async {
    // Limpiamos cualquier mensaje flotante previo de inmediato
    ScaffoldMessenger.of(context).clearSnackBars();

    if (_formKey.currentState!.validate()) {
      final authCtrl = Provider.of<AuthController>(context, listen: false);

      bool exitoso = await authCtrl.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (!context.mounted) return;

      if (exitoso) {
        final User? user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();

        if (!context.mounted) return;

        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data() as Map<String, dynamic>;

          final String rolReal = (data['rol'] ?? 'Viajero')
              .toString()
              .trim()
              .toLowerCase();

          final String rolSolicitado = (data['rol_solicitado'] ?? '')
              .toString()
              .trim()
              .toLowerCase();

          final String estadoSolicitud = (data['estado_solicitud'] ?? '')
              .toString()
              .trim();

          // 🛡️ CONTROL DE FLUJO ESTRICTO: Si el rol registrado o solicitado es 'operador', o si seleccionó la pestaña Operador
          if (rolReal == 'operador' ||
              rolSolicitado == 'operador' ||
              _selectedRole == UserRole.operador) {
            // CASO A: Solicitud aún en revisión
            if (estadoSolicitud == 'Pendiente de Aprobación') {
              await FirebaseAuth.instance
                  .signOut(); // Desloguear de Firebase por seguridad
              _mostrarAlertaEstado(
                'Solicitud en Espera',
                'Tu solicitud como operador aún se encuentra bajo revisión por el equipo administrativo.',
                Colors.orange[800]!,
              );
              return; // 🛑 DETIENE EL FLUJO AQUÍ. Evita que avance al Dashboard general.
            }

            // CASO B: Solicitud rechazada por el administrador
            if (estadoSolicitud == 'Rechazado') {
              await FirebaseAuth.instance.signOut(); // Desloguear por seguridad
              _mostrarAlertaEstado(
                'Solicitud Rechazada',
                'Lamentamos informarte que tu solicitud para ser operador ha sido rechazada.',
                Colors.red[700]!,
              );
              return; // 🛑 DETIENE EL FLUJO AQUÍ.
            }

            // CASO C: Aprobado exitosamente
            if (estadoSolicitud == 'Aprobado') {
              _mostrarAlertaAprobado();
              return;
            }
          }

          // 🟢 Si el usuario es un Viajero normal o Administrador, o ya fue verificado, ingresa al Dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const DashboardNavigationView(),
            ),
          );
        } else {
          // Si por algún motivo el documento no existe en Firestore
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const DashboardNavigationView(),
            ),
          );
        }
      } else {
        // 🛑 MENSAJE DE ERROR DE CREDENCIALES: Genérico y desaparece rápido
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Correo o contraseña incorrectos. Por favor, verifica tus datos.',
            ),
            backgroundColor: Colors.red[700],
            duration: const Duration(
              seconds: 2,
            ), // ⏱️ Solo dura 2 segundos en pantalla
          ),
        );
      }
    }
  }

  void _mostrarAlertaEstado(String titulo, String mensaje, Color color) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          titulo,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        content: Text(
          mensaje,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: color),
            onPressed: () {
              Navigator.pop(context); // Cierra el modal
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LandingView()),
                (route) =>
                    false, // Limpia el historial para que no pueda volver atrás
              );
            },
            child: const Text(
              'ENTENDIDO',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarAlertaAprobado() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 26),
            SizedBox(width: 10),
            Text(
              '¡Solicitud Aceptada!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        content: const Text(
          'Tu solicitud como operador fue aceptada con éxito. Ya puedes gestionar tus servicios dentro de la aplicación.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const DashboardNavigationView(),
                ),
              );
            },
            child: const Text(
              'INGRESAR',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.3),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1501854140801-50d01698950b?q=80&w=1575&auto=format&fit=crop',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24.0, 80.0, 24.0, 24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    padding: const EdgeInsets.all(32.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.eco_rounded,
                            size: 64,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'EcoRutas Unimet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Row(
                            children: [
                              _buildGlassRoleButton(
                                UserRole.viajero,
                                Icons.directions_walk_rounded,
                                'Viajero',
                              ),
                              const SizedBox(width: 8),
                              _buildGlassRoleButton(
                                UserRole.operador,
                                Icons.assignment_ind_outlined,
                                'Operador',
                              ),
                              const SizedBox(width: 8),
                              _buildGlassRoleButton(
                                UserRole.administrador,
                                Icons.admin_panel_settings_rounded,
                                'Admin',
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          _buildGlassTextField(
                            controller: emailController,
                            label: _selectedRole == UserRole.viajero
                                ? 'Correo Institucional Unimet'
                                : 'Correo Electrónico',
                            icon: Icons.email_outlined,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El correo es obligatorio';
                              }
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value.trim())) {
                                return 'Ingresa un correo válido';
                              }

                              // 🛡️ COMPORTAMIENTO INTELIGENTE DEL TEXTO DE ADVERTENCIA
                              if (_selectedRole == UserRole.viajero) {
                                if (!value.trim().endsWith(
                                  '@correo.unimet.edu.ve',
                                )) {
                                  return 'Usa tu correo @correo.unimet.edu.ve';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildGlassTextField(
                            controller: passwordController,
                            label: 'Contraseña',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            isObscure: _isObscure,
                            onToggleVisibility: () {
                              setState(() {
                                _isObscure = !_isObscure;
                              });
                            },
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                ? 'La contraseña es requerida'
                                : null,
                          ),
                          const SizedBox(height: 32),
                          Consumer<AuthController>(
                            builder: (context, auth, child) {
                              return auth.isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(
                                          0xFF1B5E20,
                                        ),
                                        minimumSize: const Size(
                                          double.infinity,
                                          56,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      onPressed: _intentarLogin,
                                      child: Text(
                                        'INGRESAR COMO ${_selectedRole.name.toUpperCase()}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                            },
                          ),
                          const SizedBox(height: 24),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterView(),
                                ),
                              );
                            },
                            child: const Text(
                              '¿No tienes cuenta? Regístrate aquí',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassRoleButton(UserRole role, IconData icon, String label) {
    final bool isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRole = role;
          });
          // Al cambiar de rol limpiamos los textos de advertencia anteriores automáticamente
          _formKey.currentState?.reset();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF1B5E20) : Colors.white70,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF1B5E20) : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isObscure = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      validator: validator,
      onChanged: (val) {
        if (controller.text.length <= 1) {
          _formKey.currentState?.validate();
        }
      },
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: Colors.white),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isObscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        errorStyle: const TextStyle(
          color: Colors.amberAccent,
          fontWeight: FontWeight.bold,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.amberAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.amberAccent, width: 1.5),
        ),
      ),
    );
  }
}
