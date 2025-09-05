import 'package:flutter/material.dart';
import 'widgets/login_form.dart'; // Importamos nuestro nuevo widget

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenido a tu Armario'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: LoginForm(), // Aquí usamos nuestro widget de formulario
        ),
      ),
    );
  }
}
