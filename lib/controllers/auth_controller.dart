import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthController extends ChangeNotifier {
  bool _isLoading = false;
  String _errorMessage = '';

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  set errorMessage(String value) {
    _errorMessage = value;
    notifyListeners();
  }

  bool _esCorreoUnimet(String email) {
    return email.trim().toLowerCase().endsWith('@correo.unimet.edu.ve');
  }

  // 🔓 Lógica de Inicio de Sesión Modificada (Permite el acceso a operadores con correos externos)
  Future<bool> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      _errorMessage = 'Por favor, llena todos los campos.';
      notifyListeners();
      return false;
    }

    // Se eliminó la validación estricta de '_esCorreoUnimet(email)' para permitir
    // que los operadores con correos comerciales inicien sesión.

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      // Ajustamos los mensajes para saber EXACTAMENTE qué dice Firebase
      if (e.code == 'user-not-found') {
        _errorMessage = 'No existe ningún usuario con este correo.';
      } else if (e.code == 'wrong-password') {
        _errorMessage = 'La contraseña ingresada es incorrecta.';
      } else if (e.code == 'invalid-credential') {
        _errorMessage =
            'Credenciales inválidas. Verifica tu contraseña o vuelve a registrar al operador.';
      } else if (e.code == 'user-disabled') {
        _errorMessage = 'Esta cuenta ha sido deshabilitada.';
      } else {
        _errorMessage = 'Error de autenticación: ${e.message}';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Ocurrió un error inesperado.';
      notifyListeners();
      return false;
    }
  }

  // 📝 Lógica de Registro Normal (Mantiene el candado de seguridad para la comunidad Unimet)
  Future<bool> registrarUsuario(
    String nombre,
    String email,
    String password,
    String tipoUsuario,
  ) async {
    if (nombre.isEmpty || email.isEmpty || password.isEmpty) {
      _errorMessage = 'Por favor, llena todos los campos.';
      notifyListeners();
      return false;
    }

    if (!_esCorreoUnimet(email)) {
      _errorMessage = 'Registro denegado. Utiliza tu correo unimetano.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      String emailLimpio = email.trim().toLowerCase();
      String rolAsignado = 'Viajero';
      String rolSolicitado = '';
      String estadoSolicitud = 'Aprobado';

      // 1. REGLA DE ORO: Si es tu correo, se fuerza 'admin'
      if (emailLimpio == 'a.villarroel@correo.unimet.edu.ve') {
        rolAsignado = 'admin';
        tipoUsuario = 'Administrador';
        estadoSolicitud = 'Aprobado';
      }
      // 2. Si no es tu correo, se evalúan los demás usuarios normales
      else if (tipoUsuario == 'Prestador de Servicio') {
        rolAsignado = 'Prestador de Servicio';
      } else if (tipoUsuario == 'Operador' || tipoUsuario == 'Administrador') {
        rolAsignado = 'Viajero';
        rolSolicitado = tipoUsuario;
        estadoSolicitud = 'Pendiente de Aprobación';
      }

      // Guardado en Firestore
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userCredential.user!.uid)
          .set({
            'nombre_completo': nombre,
            'correo_institucional': emailLimpio,
            'tipo_usuario': tipoUsuario,
            'rol': rolAsignado,
            'rol_solicitado': rolSolicitado,
            'estado_solicitud': estadoSolicitud,
            'fecha_creacion': FieldValue.serverTimestamp(),
          });

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      if (e.code == 'email-already-in-use') {
        _errorMessage = 'Este correo ya se encuentra registrado.';
      } else {
        _errorMessage = e.message ?? 'Error en el registro.';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al procesar el registro.';
      notifyListeners();
      return false;
    }
  }
}
