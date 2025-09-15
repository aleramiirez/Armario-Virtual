import 'package:flutter/material.dart';
import 'widgets/registration_form.dart';

/// Pantalla de Registro de Nuevos Usuarios.
/// 
/// Al igual que [LoginScreen], es un widget 'Stateless' cuya única 
/// responsabilidad es mostrar la estructura visual de la pantalla y delegar
/// toda la lógica e interactividad al widget [RegistrationForm].
class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nueva Cuenta'),
      ),
      body: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: RegistrationForm(),
        ),
      ),
    );
  }
}