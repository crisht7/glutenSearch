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
  }

  // Inicia sesión con email y contraseña.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Cierra la sesión del usuario actual.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
