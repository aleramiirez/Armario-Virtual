import 'package:flutter/material.dart';
import 'widgets/add_garment_form.dart';

/// Pantalla para añadir una nueva prenda al armario.
///
/// Es un widget [StatelessWidget] que muestra la estructura básica de la pantalla
/// y delega toda la lógica y la interfaz del formulario al widget [AddGarmentForm].
class AddGarmentScreen extends StatelessWidget {
  const AddGarmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir Nueva Prenda'),
      ),
      body: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: AddGarmentForm(),
        ),
      ),
    );
  }
}