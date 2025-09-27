import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:armariovirtual/screens/registration/registration_screen.dart';
import 'package:armariovirtual/services/auth_service.dart';
import 'package:armariovirtual/utils/app_alerts.dart';

/// El formulario de login.
///
/// Es un widget [StatefulWidget] porque necesita gestionar estados que cambian:
/// - Lo que el usuario escribe en los campos.
/// - Si la contraseña es visible o no.
/// - Si se está procesando una petición (`_isLoading`).
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  /// Clave global para identificar y validar el formulario.
  final _formKey = GlobalKey<FormState>();

  /// Controladores para leer el contenido de los campos de texto.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  /// Variables de estado para la UI.
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  /// Instancia del servicio de autenticación para delegar la lógica.
  final AuthService _authService = AuthService();

  /// Limpiamos los controladores cuando el widget se destruye para
  /// liberar memoria.
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Gestiona el envío del formulario de email/contraseña.
  Future<void> _submitForm() async {
    // Valida que los campos cumplan las reglas.
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Delega la lógica de inicio de sesión al servicio.
      await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      // Si el login es exitoso, AuthGate se encargará de la navegación.
    } on FirebaseAuthException catch (e) {
      // Maneja errores específicos de autenticación y los muestra al usuario.
      String errorMessage = 'Ocurrió un error';
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        errorMessage = 'Correo o contraseña incorrectos.';
      }

      if (mounted) {
        AppAlerts.showFloatingSnackBar(context, errorMessage, isError: true);
      }
    } finally {
      // Se asegura de que el estado de carga siempre se desactive al final.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Gestiona el inicio de sesión con Google.
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Delega la lógica de Google al servicio.
      await _authService.signInWithGoogle();
    } catch (error) {
      // Maneja cualquier error y lo muestra al usuario.
      if (mounted) {
        AppAlerts.showFloatingSnackBar(
          context,
          'Error al iniciar sesión con Google',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Correo Electrónico',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || !RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                return 'Por favor, introduce un correo válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
            ),
            validator: (value) {
              if (value == null || value.length < 6) {
                return 'La contraseña debe tener al menos 6 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitForm,
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : const Text('INICIAR SESIÓN'),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: Image.asset('assets/google.png', height: 22.0),
                label: const Text('Continuar con Google'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.grey),
                ),
                onPressed: _isLoading ? null : _signInWithGoogle,
              ),
            ],
          ),
          const SizedBox(height: 15),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const RegistrationScreen()),
              );
            },
            child: const Text('¿No tienes cuenta? Regístrate'),
          ),
        ],
      ),
    );
  }
}
