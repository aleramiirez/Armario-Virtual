import 'package:flutter/material.dart';
import 'widgets/add_garment_form.dart';

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