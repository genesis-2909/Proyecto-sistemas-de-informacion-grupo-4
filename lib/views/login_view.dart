import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import 'register_view.dart';
import 'home_view.dart';

class LoginView extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoRutas - Iniciar Sesión'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Consumer<AuthController>(
          builder: (context, authController, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 120,
                ),
                const SizedBox(height: 30),
                
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo Institucional',
                    hintText: 'usuario@correo.unimet.edu.ve',
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green, width: 2.0),
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green, width: 2.0),
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),

                if (authController.errorMessage.isNotEmpty)
                  Text(
                    authController.errorMessage,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                
                const SizedBox(height: 20),

                authController.isLoading
                    ? const CircularProgressIndicator(color: Colors.green)
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          bool exito = await authController.login(
                            emailController.text.trim(),
                            passwordController.text.trim(),
                          );
                          
                          if (exito && context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const HomeView()),
                            );
                          }
                        },
                        child: const Text('Ingresar', style: TextStyle(fontSize: 16)),
                      ),
                
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterView()),
                    );
                  },
                  child: const Text(
                    '¿No tienes cuenta? Regístrate aquí',
                    style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}