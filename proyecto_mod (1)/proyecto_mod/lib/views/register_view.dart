import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import 'dashboard_navigation_view.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController(); // 🛠️ CAMPO NUEVO

  bool _isObscure = true;
  bool _isObscureConfirm = true; // 🛠️ ESTADO NUEVO
  String _tipoUsuarioSeleccionado = 'Viajero';

  final List<String> _tiposDeUsuario = [
    'Viajero',
    'Prestador de Servicio',
    'Operador',
    'Administrador',
  ];

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose(); // 🛠️ LIBERAR MEMORIA
    super.dispose();
  }

  void _ejecutarRegistro() async {
    // 1. Lógica local para verificar si las contraseñas coinciden
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Las contraseñas no coinciden.'),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }

    final authController = Provider.of<AuthController>(context, listen: false);

    // 2. Disparar el registro en Firebase
    bool registroExitoso = await authController.registrarUsuario(
      nameController.text,
      emailController.text,
      passwordController.text,
      _tipoUsuarioSeleccionado,
    );

    if (!context.mounted) return;

    // 3. ¡FLUJO DIRECTO AQUÍ!
    if (registroExitoso) {
      // Lanzamos el SnackBar de éxito en la pantalla actual
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Registro exitoso! Redirigiendo...'),
          backgroundColor: Colors.green,
          duration: Duration(
            seconds: 1,
          ), // Duración cortita para que no estorbe
        ),
      );

      // 🚀 REDIRECCIÓN INMEDIATA AUTOMÁTICA
      // Destruye la pantalla de registro y monta de una vez el Dashboard
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const DashboardNavigationView(),
        ),
        (route) =>
            false, // Esto borra el historial para que no pueda darle "atrás"
      );
    } else {
      // Si algo falla (ej. correo ya registrado), muestra el error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authController.errorMessage),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              padding: const EdgeInsets.all(24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(32.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
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
                          'Crea tu Cuenta',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 24),

                        _buildGlassTextField(
                          controller: nameController,
                          label: 'Nombre Completo',
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 16),

                        _buildGlassTextField(
                          controller: emailController,
                          label: 'Correo Unimet (@correo.unimet.edu.ve)',
                          icon: Icons.email_outlined,
                        ),
                        const SizedBox(height: 16),

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
                        ),
                        const SizedBox(height: 16),

                        // 🛠️ COMPONENTE NUEVO: CONFIRMAR CONTRASEÑA
                        _buildGlassTextField(
                          controller: confirmPasswordController,
                          label: 'Confirmar Contraseña',
                          icon: Icons.lock_clock_outlined,
                          isPassword: true,
                          isObscure: _isObscureConfirm,
                          onToggleVisibility: () {
                            setState(() {
                              _isObscureConfirm = !_isObscureConfirm;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildGlassDropdown(),
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
                                      foregroundColor: const Color(0xFF1B5E20),
                                      minimumSize: const Size(
                                        double.infinity,
                                        56,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    onPressed: _ejecutarRegistro,
                                    child: const Text(
                                      'REGISTRARME',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  );
                          },
                        ),
                        const SizedBox(height: 16),

                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            '¿Ya tienes cuenta? Inicia sesión',
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
        ],
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
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
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
      ),
    );
  }

  Widget _buildGlassDropdown() {
    return DropdownButtonFormField<String>(
      value: _tipoUsuarioSeleccionado,
      dropdownColor: const Color(0xFF2E4A3F),
      style: const TextStyle(color: Colors.white),
      iconEnabledColor: Colors.white,
      decoration: InputDecoration(
        labelText: 'Tipo de Usuario',
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: const Icon(
          Icons.assignment_ind_outlined,
          color: Colors.white,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
      ),
      items: _tiposDeUsuario.map((String valor) {
        return DropdownMenuItem<String>(value: valor, child: Text(valor));
      }).toList(),
      onChanged: (nuevoValor) {
        if (nuevoValor != null) {
          setState(() {
            _tipoUsuarioSeleccionado = nuevoValor;
          });
        }
      },
    );
  }
}
