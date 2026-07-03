import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/eco_theme.dart';

class SolicitudOperadorView extends StatefulWidget {
  const SolicitudOperadorView({super.key});

  @override
  State<SolicitudOperadorView> createState() => _SolicitudOperadorViewState();
}

class _SolicitudOperadorViewState extends State<SolicitudOperadorView> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _avalController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _solicitudEnviada = false;
  bool _cargando = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // 🚀 FUNCIÓN DE ENVÍO Y GUARDADO REAL CON FIREBASE CONECTADO AL LOGIN
  void _enviarFormulario() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _cargando = true);

      try {
        // 1. Crear el usuario de forma real en Firebase Authentication
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _correoController.text.trim(),
              password: _passwordController.text.trim(),
            );

        final String uid = userCredential.user!.uid;

        // 2. Guardar los datos en el documento de Firestore vinculando las llaves exactas que lee el Login
        await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
          'nombre_completo': _nombreController.text.trim(),
          'correo': _correoController.text.trim(),
          'cedula': _cedulaController.text.trim(),
          'aval_url': _avalController.text.trim(),
          'rol_solicitado': 'operador',
          'estado_solicitud':
              'Pendiente de Aprobación', // ⏳ Estado inicial visible para el Admin
          'rol': 'Viajero', // Rol base de seguridad hasta que sea aprobado
          'fecha_solicitud': FieldValue.serverTimestamp(),
        });

        setState(() {
          _cargando = false;
          _solicitudEnviada = true;
        });
      } catch (e) {
        setState(() => _cargando = false);

        String mensajeError = 'Ocurrió un error al enviar la solicitud: $e';
        if (e is FirebaseAuthException) {
          if (e.code == 'email-already-in-use') {
            mensajeError =
                'Este correo electrónico ya se encuentra registrado.';
          } else if (e.code == 'weak-password') {
            mensajeError =
                'La contraseña ingresada es muy débil (mínimo 6 caracteres).';
          } else if (e.code == 'invalid-email') {
            mensajeError = 'El formato del correo electrónico no es válido.';
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensajeError),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si la solicitud ya se procesó de forma exitosa, muestra la pantalla de confirmación
    if (_solicitudEnviada) {
      return Scaffold(
        backgroundColor: EcoTheme.warmCream,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: EcoTheme.forestGreen,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Solicitud Recibida',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: EcoTheme.darkForest,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tu cuenta como operador ha sido creada con éxito. Tu documentación se encuentra en estado "Pendiente de Aprobación" bajo la revisión de un administrador.\n\nYa puedes regresar al inicio e iniciar sesión para chequear tu estatus.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: EcoTheme.softGray,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EcoTheme.forestGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(
                        context,
                      ); // Regresa al flujo de autenticación/landing
                    },
                    child: const Text(
                      'VOLVER AL INICIO',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Formulario de inscripción del operador
    return Scaffold(
      backgroundColor: EcoTheme.warmCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: EcoTheme.darkForest,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Registro de Operador',
          style: TextStyle(
            color: EcoTheme.darkForest,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(28.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Únete como Operador',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: EcoTheme.darkForest,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Completa los datos de tu perfil turístico y adjunta tu aval corporativo o personal para verificación.',
                    style: TextStyle(
                      fontSize: 13,
                      color: EcoTheme.softGray,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildInputField(
                    controller: _nombreController,
                    label: 'Nombre Completo o Empresa',
                    hint: 'Ej. Juan Pérez / EcoTurismo S.A.',
                    icon: Icons.person_outline,
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'El nombre es requerido'
                        : null,
                  ),
                  _buildInputField(
                    controller: _correoController,
                    label: 'Correo Electrónico Comercial',
                    hint: 'ejemplo@gmail.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El correo es requerido';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value.trim())) {
                        return 'Ingresa un formato de correo válido';
                      }
                      return null;
                    },
                  ),
                  _buildInputField(
                    controller: _cedulaController,
                    label: 'Cédula de Identidad o RIF',
                    hint: 'V-12345678 / J-123456789',
                    icon: Icons.badge_outlined,
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'La identificación es requerida'
                        : null,
                  ),
                  _buildInputField(
                    controller: _avalController,
                    label: 'Enlace del Documento Aval (URL)',
                    hint: 'https://drive.google.com/file/...',
                    icon: Icons.link_rounded,
                    keyboardType: TextInputType.url,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El link de tu documento aval es obligatorio';
                      }
                      if (!value.trim().startsWith('http://') &&
                          !value.trim().startsWith('https://')) {
                        return 'Debe ser un enlace válido (http o https)';
                      }
                      return null;
                    },
                  ),
                  _buildInputField(
                    controller: _passwordController,
                    label: 'Contraseña de la Cuenta',
                    hint: 'Mínimo 6 caracteres',
                    icon: Icons.lock_open_rounded,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: EcoTheme.softGray,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La contraseña es requerida';
                      }
                      if (value.length < 6) {
                        return 'Debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  _buildInputField(
                    controller: _confirmPasswordController,
                    label: 'Confirmar Contraseña',
                    hint: 'Repite tu contraseña',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: EcoTheme.softGray,
                        size: 20,
                      ),
                      onPressed: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirma tu contraseña';
                      }
                      if (value != _passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _cargando
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: EcoTheme.forestGreen,
                          ),
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EcoTheme.forestGreen,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _enviarFormulario,
                          child: const Text(
                            'ENVIAR SOLICITUD',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: EcoTheme.darkForest,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: EcoTheme.forestGreen, size: 22),
              suffixIcon: suffixIcon,
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.black26, fontSize: 14),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: EcoTheme.forestGreen,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.redAccent),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.redAccent,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
