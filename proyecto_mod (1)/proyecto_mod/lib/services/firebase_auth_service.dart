import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  // Constructor privado para asegurar una única instancia en memoria
  FirebaseAuthService._internal();
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseAuth get auth => _auth;
}