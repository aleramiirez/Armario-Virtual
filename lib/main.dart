import 'package:flutter/material.dart';
import 'package:armario_virtual/screens/login/login_screen.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Armario Virtual',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false, // Quita la banda de "Debug"
      home: const LoginScreen(), // ¡Aquí establecemos nuestra pantalla de login!
    );
  }
}