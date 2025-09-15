import 'package:flutter/material.dart';
import 'widgets/login_form.dart';

/// Pantalla principal de Login
/// 
/// Es un widget [StatelessWidget] (sin estado) porque su única responsabilidad 
/// es mostrar la esturctura de la pantalla (AppBar, cuerpo, etc.) y delegar
/// toda la interactividad al widget [LoginForm].
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenido a tu Armario'),
        centerTitle: true,
      ),
      // Usamos SingleChildScrollView para evitar que el teclado cause un 
      // desbordamiento de pixeles (overflow) al aparecer.
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: LoginForm(),
        ),
      ),
    );
  }
}
