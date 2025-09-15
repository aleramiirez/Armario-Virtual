import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Gestiona toda la comunicación con Firebase Authentication.
///
/// Abstrae la lógica de negocio para el inicio de sesión, registro y cierre de sesión,
/// permitiendo que la UI sea independiente de la implementación de Firebase.
class AuthService {
  /// Instancia principal de Firebase Auth para gestionar usuarios.
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Instancia para gestionar el flujo de inicio de sesión con Google.
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Inicia sesión con correo y contraseña.
  ///
  /// Devuelve el [User] si el inicio de sesión es exitoso.
  /// Lanza una [FirebaseAuthException] si las credenciales son incorrectas o el usuario no existe.
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user;
  }

  /// Inicia el flujo de inicio de sesión con Google y luego autentica al 
  /// usuario en Firebase.
  ///
  /// Devuelve el [User] si el proceso es exitoso, o `null` si el usuario
  /// cancela la selección de cuenta de Google.
  Future<User?> signInWithGoogle() async {
    // 1. Abre la ventana nativa de Google para que el usuario elija su cuenta.
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return null; // El usuario cerró la ventana de selección.
    }

    // 2. Obtiene las credenciales (tokens) de la cuenta de Google seleccionada.
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // 3. Usa las credenciales para iniciar sesión en Firebase.
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    return userCredential.user;
  }

  /// Registra un nuevo usuario con correo y contraseña.
  /// 
  /// Devuelve el [User] si el registro es exitoso.
  /// Lanza una [FirebaseAuthException] si la contraseña es débil o el email
  /// ya esta en uso.
  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user;
  }

  /// Cierra la sesión del usuario tanto en Firebase como en Google Sign-In.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}
