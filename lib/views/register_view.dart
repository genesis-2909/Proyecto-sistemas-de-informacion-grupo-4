import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import 'dashboard_navigation_view.dart';
import 'login_view.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey =
      GlobalKey<FormState>(); // Para controlar de forma segura las validaciones
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _isObscure = true;
  bool _isObscureConfirm = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _ejecutarRegistro() async {
    // Primero disparamos las validaciones locales de los campos de texto
    if (_formKey.currentState!.validate()) {
      final authController = Provider.of<AuthController>(
        context,
        listen: false,
      );

      // Disparar el registro en Firebase pasando explícitamente el rol como 'Viajero'
      bool registroExitoso = await authController.registrarUsuario(
        nameController.text.trim(),
        emailController.text.trim(),
        passwordController.text.trim(),
        'Viajero', // Rol asignado de manera fija y automática
      );

      if (!context.mounted) return;

      if (registroExitoso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Registro exitoso! Redirigiendo...'),
            backgroundColor: Colors.green,
            duration: Duration(milliseconds: 1000),
          ),
        );

        // Redirección inmediata limpiando el árbol de navegación
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const DashboardNavigationView(),
          ),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authController.errorMessage),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar:
          true, // Permite que la imagen de fondo suba detrás de la barra superior
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(
              0.3,
            ), // Botón translúcido premium idéntico al de Login
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
              tooltip: 'Volver al Inicio',
              onPressed: () {
                Navigator.pop(
                  context,
                ); // Te regresa a la vista de donde viniste (Home/LandingView)
              },
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // 🏞️ IMAGEN DE FONDO
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
          // 🌫️ EFECTO FROSTED GLASS
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                24.0,
                90.0,
                24.0,
                24.0,
              ), // Margen superior para no solapar el botón de regreso
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    padding: const EdgeInsets.all(32.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(
                        0.35,
                      ), // Un toque más de opacidad para favorecer el contraste de alertas
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Form(
                      key: _formKey, // Se enlaza la clave del formulario
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.badge_outlined,
                            size: 54,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Regístrate como Viajero',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Exclusivo para la comunidad Unimet',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // =========================================================================
                          // CAMPO: NOMBRE COMPLETO
                          // =========================================================================
                          _buildGlassTextField(
                            controller: nameController,
                            label: 'Nombre Completo',
                            icon: Icons.person_outline_rounded,
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                ? 'El nombre es obligatorio'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // =========================================================================
                          // CAMPO: CORREO (CON FILTRO OBLIGATORIO UNIMET)
                          // =========================================================================
                          _buildGlassTextField(
                            controller: emailController,
                            label: 'Correo Institucional Unimet',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El correo es obligatorio';
                              }
                              // Validación de formato básico de correo electrónico
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value.trim())) {
                                return 'Ingresa un correo válido';
                              }
                              // Validación estricta del dominio Unimet obligatorio por ser Viajero
                              if (!value.trim().endsWith(
                                '@correo.unimet.edu.ve',
                              )) {
                                return 'Debes usar obligatoriamente tu correo @correo.unimet.edu.ve';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // =========================================================================
                          // CAMPO: CONTRASEÑA
                          // =========================================================================
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
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'La contraseña es requerida';
                              if (value.length < 6)
                                return 'Debe tener al menos 6 caracteres';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // =========================================================================
                          // CAMPO: CONFIRMAR CONTRASEÑA
                          // =========================================================================
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
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Confirma tu contraseña';
                              if (value != passwordController.text)
                                return 'Las contraseñas no coinciden';
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          // =========================================================================
                          // BOTÓN DE REGISTRO CON CONSUMER
                          // =========================================================================
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
                                      onPressed: _ejecutarRegistro,
                                      child: const Text(
                                        'REGISTRARME COMO VIAJERO',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                          fontSize: 13,
                                        ),
                                      ),
                                    );
                            },
                          ),
                          const SizedBox(height: 16),

                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginView(),
                                ),
                              );
                            },
                            child: const Text(
                              '¿Ya tienes cuenta? Inicia sesión aquí',
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

  // WIDGET AUXILIAR: Transmutado de TextField a TextFormField para que actúen las validaciones
  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isObscure = false,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      validator: validator, // Asignación del validador dinámico
      keyboardType: keyboardType,
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
        ), // Alertas legibles en color amarillo ámbar sobre fondo oscuro
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
