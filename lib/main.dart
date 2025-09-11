import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:armario_virtual/widgets/auth_gate.dart';
import 'package:armario_virtual/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Armario Virtual',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false, 
      home: const AuthGate(), 
    );
  }
}