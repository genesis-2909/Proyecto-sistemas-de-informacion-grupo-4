import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReservaController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _reservaIdActual = '';
  String get reservaIdActual => _reservaIdActual;

  Future<String> crearSolicitudReserva({
    required String idOferta,
    required String nombreDestino,
    required String fechaInicio,
    required String fechaFin,
    required int cantidadPersonas,
    required double precioNoche,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return '';

      double montoTotal = cantidadPersonas * precioNoche;

      // Guardamos la reserva vinculada al uid del viajero logueado
      DocumentReference docRef = await FirebaseFirestore.instance.collection('reservas').add({
        'id_viajero': user.uid,
        'id_oferta': idOferta,
        'nombre_destino': nombreDestino,
        'fecha_inicio': fechaInicio,
        'fecha_fin': fechaFin,
        'cantidad_personas': cantidadPersonas,
        'monto_total': montoTotal,
        'estado_actual': 'Solicitado', 
        'fecha_creacion': FieldValue.serverTimestamp(),
      });

      _reservaIdActual = docRef.id;
      _isLoading = false;
      notifyListeners(); 
      return docRef.id;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return '';
    }
  }

  Future<bool> procesarPagoReal(String idReserva) async {
    try {
      if (idReserva.isEmpty) return false;
      
      await FirebaseFirestore.instance.collection('reservas').doc(idReserva).update({
        'estado_actual': 'Pagado',
      });
      
      notifyListeners(); 
      return true;
    } catch (e) {
      return false;
    }
  }
}