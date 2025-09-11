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
            message:
                'Este correo electrónico ya está registrado. Por favor, inicia sesión o usa otro correo.',
          );
        }
      } catch (e) {
        // Si no es un error de "email-already-in-use", continuamos con el registro
        if (e is firebase_auth.FirebaseAuthException &&
            e.code != 'email-already-in-use') {
          rethrow;
        }
      }

      firebase_auth.UserCredential userCredential;

      if (currentUser != null && currentUser!.isAnonymous) {
        // Si somos un usuario anónimo, enlazamos la cuenta para no perder datos.
        final credential = firebase_auth.EmailAuthProvider.credential(
          email: email,
          password: password,
        );

        try {
          // Con la nueva versión de Firebase, manejamos posibles errores de tipo
          userCredential = await currentUser!.linkWithCredential(credential);
        } catch (e) {
          print('Error al enlazar cuenta: $e');
          // Si hay un error al enlazar, intentamos crear un usuario nuevo
          userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        }
      } else {
        // Si no hay usuario o no es anónimo, creamos un usuario nuevo.
        userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      // Verificar que el usuario se haya creado correctamente
      if (userCredential.user == null) {
        throw Exception('Error al crear la cuenta: usuario nulo');
      }

      // Actualizar el perfil después de la creación exitosa
      try {
        await userCredential.user!.updateDisplayName(email.split('@')[0]);
      } catch (e) {
        print(
          'No se pudo actualizar el nombre de usuario, pero la cuenta se creó: $e',
        );
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception(
          'Este correo electrónico ya está registrado. Por favor, inicia sesión o usa otro correo.',
        );
      } else if (e.code == 'operation-not-allowed') {
        throw Exception(
          'El registro por email está deshabilitado. Contacta al soporte.',
        );
      } else if (e.code == 'weak-password') {
        throw Exception(
          'La contraseña es muy débil. Intenta con una más segura.',
        );
      } else {
        throw Exception('Error al crear la cuenta: ${e.message}');
      }
    } catch (e) {
      // Manejar específicamente el error de PigeonUserDetails
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('not a subtype')) {
        print('Error conocido de tipo en Firebase Auth: $e');
        throw Exception(
          'Error interno durante el registro. Por favor, intenta nuevamente.',
        );
      } else {
        throw Exception('Error al crear la cuenta: $e');
      }
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
      } else if (e.code == 'invalid-email') {
        throw Exception('El formato del email no es válido');
      } else if (e.code == 'user-disabled') {
        throw Exception('Esta cuenta ha sido deshabilitada');
      } else if (e.code == 'too-many-requests') {
        throw Exception('Demasiados intentos. Intenta más tarde');
      } else {
        throw Exception('Error al iniciar sesión: ${e.message}');
      }
    } catch (e) {
      // Manejar específicamente el error de PigeonUserDetails
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('not a subtype')) {
        print('Error conocido de tipo en Firebase Auth al iniciar sesión: $e');
        throw Exception(
          'Error interno durante el inicio de sesión. Por favor, intenta nuevamente.',
        );
      } else {
        throw Exception('Error al iniciar sesión: $e');
      }
    }
  }

  // Cierra la sesión del usuario actual.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
