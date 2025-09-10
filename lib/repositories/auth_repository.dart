import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;

  AuthRepository({firebase_auth.FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  // Stream para escuchar los cambios de estado de autenticación (login/logout).
  Stream<firebase_auth.User?> authStateChanges() =>
      _firebaseAuth.authStateChanges();

  // Obtiene el usuario actual de Firebase.
  firebase_auth.User? get currentUser => _firebaseAuth.currentUser;

  // Inicia sesión de forma anónima si no hay ningún usuario.
  Future<void> signInAnonymouslyIfNeeded() async {
    if (currentUser == null) {
      await _firebaseAuth.signInAnonymously();
    }
  }

  // Registra un nuevo usuario con email y contraseña.
  // Si el usuario actual es anónimo, enlaza la nueva cuenta para mantener el UID.
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Desactivamos la verificación de reCAPTCHA para pruebas
      await _firebaseAuth.setSettings(appVerificationDisabledForTesting: true);

      // Primero verificamos si el email ya está en uso para dar un mensaje más claro
      try {
        final methods = await _firebaseAuth.fetchSignInMethodsForEmail(email);
        if (methods.isNotEmpty) {
          throw firebase_auth.FirebaseAuthException(
            code: 'email-already-in-use',
            message: 'Este correo electrónico ya está registrado. Por favor, inicia sesión o usa otro correo.',
          );
        }
      } catch (e) {
        // Si no es un error de "email-already-in-use", continuamos con el registro
        if (e is firebase_auth.FirebaseAuthException && 
            e.code != 'email-already-in-use') {
          rethrow;
        }
      }

      final credential = firebase_auth.EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      if (currentUser != null && currentUser!.isAnonymous) {
        // Si somos un usuario anónimo, enlazamos la cuenta para no perder datos.
        await currentUser!.linkWithCredential(credential);
      } else {
        // Si no, creamos un usuario nuevo.
        await _firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception(
          'Este correo electrónico ya está registrado. Por favor, inicia sesión o usa otro correo.',
        );
      } else {
        throw Exception('Error al crear la cuenta: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error al crear la cuenta: $e');
    }
  }

  // Inicia sesión con email y contraseña.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Desactivamos la verificación de reCAPTCHA para pruebas
      await _firebaseAuth.setSettings(appVerificationDisabledForTesting: true);

      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        throw Exception(
          'Email o contraseña incorrectos. Por favor, inténtalo de nuevo.',
        );
      } else {
        throw Exception('Error al iniciar sesión: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  // Cierra la sesión del usuario actual.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
