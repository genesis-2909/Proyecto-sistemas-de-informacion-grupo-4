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
      if (user == null) {
        _isLoading = false;
        notifyListeners();
        return '';
      }

      double montoTotal = cantidadPersonas * precioNoche;

      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('reservations')
          .add({
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

      // Apunta a la colección unificada 'reservations'
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(idReserva)
          .update({'estado_actual': 'Pagado'});

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 🔒 REGLA DE NEGOCIO: Retorna true si la reserva está pagada y ya terminó la estadía.
  /// Maneja de forma segura el formato nativo del proyecto "dd/mm/yyyy"
  bool puedeDejarResena(String fechaFinStr, String estadoActual) {
    try {
      // 1. Validar el estado
      if (estadoActual != 'Pagado') return false;

      // 2. Descomponer el formato de barras "dd/mm/yyyy" de forma segura
      List<String> partes = fechaFinStr.split('/');
      if (partes.length != 3) return false;

      int dia = int.parse(partes[0]);
      int mes = int.parse(partes[1]);
      int anio = int.parse(partes[2]);

      // 3. Crear instancias de tiempo para comparar
      DateTime fechaFin = DateTime(anio, mes, dia);
      DateTime fechaActual = DateTime.now();

      // Para ser justos en la entrega, si es el mismo día del fin del viaje,
      // limpiamos las horas para comparar solo las fechas.
      DateTime fechaFinLimpia = DateTime(
        fechaFin.year,
        fechaFin.month,
        fechaFin.day,
      );
      DateTime fechaActualLimpia = DateTime(
        fechaActual.year,
        fechaActual.month,
        fechaActual.day,
      );

      // Retorna verdadero si hoy es después o el mismo día del fin de la estadía
      return fechaActualLimpia.isAfter(fechaFinLimpia) ||
          fechaActualLimpia.isAtSameMomentAs(fechaFinLimpia);
    } catch (e) {
      return false;
    }
  }
}
