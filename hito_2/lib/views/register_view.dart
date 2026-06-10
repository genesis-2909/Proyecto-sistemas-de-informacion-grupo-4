import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import 'profile_view.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String tipoUsuario = 'Estudiante'; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta - EcoRutas'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Consumer<AuthController>(
          builder: (context, authController, child) {
            return SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/logo.png', height: 100),
                  const SizedBox(height: 20),
                  
                  TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre Completo', 
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green, width: 2.0)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Correo (@correo.unimet.edu.ve)', 
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green, width: 2.0)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña (Mín. 6 caracteres)', 
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green, width: 2.0)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  DropdownButtonFormField<String>(
                    value: tipoUsuario,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(), 
                      labelText: 'Tipo de Usuario / Rol',
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green, width: 2.0)),
                    ),
                    items: ['Estudiante', 'Profesor', 'Personal', 'Prestador de Servicio'].map((String tipo) {
                      return DropdownMenuItem<String>(value: tipo, child: Text(tipo));
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        tipoUsuario = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  
                  if (authController.errorMessage.isNotEmpty)
                    Text(authController.errorMessage, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  
                  const SizedBox(height: 20),
                  
                  authController.isLoading
                      ? const CircularProgressIndicator(color: Colors.green)
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B5E20),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
                            bool exito = await authController.registrarUsuario(
                              nombreController.text.trim(),
                              emailController.text.trim(),
                              passwordController.text.trim(),
                              tipoUsuario,
                            );
                            
                            if (exito && context.mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const ProfileView()),
                              );
                            }
                          },
                          child: const Text('Registrarme', style: TextStyle(fontSize: 16)),
                        ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}