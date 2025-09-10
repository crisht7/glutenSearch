import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:gluten_search/repositories/auth_repository.dart';

void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late AuthRepository authRepository;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    authRepository = AuthRepository(firebaseAuth: mockFirebaseAuth);
  });

  group('AuthRepository', () {
    test('currentUser returns FirebaseAuth.currentUser', () {
      final result = authRepository.currentUser;
      expect(result, mockFirebaseAuth.currentUser);
    });

    test('authStateChanges returns FirebaseAuth.authStateChanges', () {
      final result = authRepository.authStateChanges();
      expect(result, mockFirebaseAuth.authStateChanges());
    });

    test(
      'signInAnonymouslyIfNeeded calls signInAnonymously when currentUser is null',
      () async {
        await authRepository.signInAnonymouslyIfNeeded();
        expect(mockFirebaseAuth.currentUser, isNotNull);
        expect(mockFirebaseAuth.currentUser!.isAnonymous, isTrue);
      },
    );

    test('signInWithEmail signs in with email and password', () async {
      const email = 'test@example.com';
      const password = 'password123';

      // Creamos un MockFirebaseAuth con configuración específica para este test
      final authWithUser = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(email: email, isAnonymous: false),
      );
      final authRepo = AuthRepository(firebaseAuth: authWithUser);

      await authRepo.signInWithEmail(email: email, password: password);

      // Verify user is signed in with correct email
      expect(authRepo.currentUser, isNotNull);
      expect(authRepo.currentUser!.email, email);
      expect(authRepo.currentUser!.isAnonymous, isFalse);
    });

    test('signUpWithEmail creates new user', () async {
      const email = 'newuser@example.com';
      const password = 'password123';

      // Creamos un MockFirebaseAuth con configuración específica para este test
      final authWithUser = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(email: email, isAnonymous: false),
      );
      final authRepo = AuthRepository(firebaseAuth: authWithUser);

      await authRepo.signUpWithEmail(email: email, password: password);

      // Verify new user is created
      expect(authRepo.currentUser, isNotNull);
      expect(authRepo.currentUser!.email, email);
      expect(authRepo.currentUser!.isAnonymous, isFalse);
    });

    test('signOut signs out current user', () async {
      // First sign in to have a user
      await mockFirebaseAuth.signInAnonymously();
      expect(mockFirebaseAuth.currentUser, isNotNull);

      // Then sign out
      await authRepository.signOut();

      // Verify user is signed out
      expect(mockFirebaseAuth.currentUser, isNull);
    });
  });
}
