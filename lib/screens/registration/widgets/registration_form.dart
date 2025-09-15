import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:armario_virtual/services/auth_service.dart';
import 'package:armario_virtual/config/app_theme.dart';

/// Formulario de registro de nuevos usuarios.
///
/// Es un widget [StatefulWidget] para gestionar los datos introducidos por el
/// usuario y el estado de carga (`_isLoading`). Delega la lógica de creación
/// de usuario al [AuthService]
class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key});

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
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

  /// Limpiamos los controladores cuando el widget se destruye para liberar memoria.
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Gestiona el envío del formulario de registro.
  Future<void> _submitForm() async {
    // Valida que los campos cumplan las reglas.
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Delega la creación del usuario al servicio de autenticación.
      await _authService.signUpWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Si el registro es exitoso, muestra un mensaje y vuelve a la
      // pantalla de login.
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(
            content: const Text('¡Registro exitoso! Ya puedes iniciar sesión.'),
            backgroundColor: AppTheme.colorExito,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Maneja errores específicos de Firebase (contraseña débil,
      // email en uso, etc.).
      String errorMessage = 'Ocurrió un error en el registro.';
      if (e.code == 'weak-password') {
        errorMessage = 'La contraseña es demasiado débil.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Ya existe una cuenta con este correo.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Campo de texto para el email.
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Correo Electrónico'),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || !RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                return 'Introduce un correo válido.';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          // Campo de texto para la contraseña.
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Contraseña',
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
                return 'La contraseña debe tener al menos 6 caracteres.';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),
          // Botón de envío del formulario.
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
                : const Text('REGISTRARSE'),
          ),
        ],
      ),
    );
  }
}
