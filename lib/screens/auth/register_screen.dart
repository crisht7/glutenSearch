import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async'; // Import for TimeoutException
import '../../core/app_theme.dart';
import '../../core/app_router.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/loading_spinner.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.primaryGreen,
        actions: const [],
      ),
      body: LoadingSpinnerOverlay(
        isLoading: _isLoading,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icono y título
                const Icon(
                  Icons.person_add_outlined,
                  size: 64,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Crea tu cuenta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Disfruta de todas las funcionalidades',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                // Formulario de registro
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo',
                          hintText: 'Tu nombre',
                          prefixIcon: Icon(Icons.person_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu nombre';
                          }
                          if (value.trim().length < 2) {
                            return 'El nombre debe tener al menos 2 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'tu@email.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu email';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Ingresa un email válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          hintText: 'Mínimo 6 caracteres',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa una contraseña';
                          }
                          if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleRegister(),
                        decoration: InputDecoration(
                          labelText: 'Confirmar contraseña',
                          hintText: 'Repite tu contraseña',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor confirma tu contraseña';
                          }
                          if (value != _passwordController.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Términos y condiciones
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _acceptTerms,
                            onChanged: (value) {
                              setState(() {
                                _acceptTerms = value ?? false;
                              });
                            },
                            activeColor: AppTheme.primaryGreen,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _acceptTerms = !_acceptTerms;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: RichText(
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                    children: [
                                      TextSpan(text: 'Acepto los '),
                                      TextSpan(
                                        text: 'términos y condiciones',
                                        style: TextStyle(
                                          color: AppTheme.primaryGreen,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(text: ' y la '),
                                      TextSpan(
                                        text: 'política de privacidad',
                                        style: TextStyle(
                                          color: AppTheme.primaryGreen,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Botón de registro
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: (_isLoading || !_acceptTerms)
                              ? null
                              : _handleRegister,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Crear Cuenta',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Ya tienes cuenta
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('¿Ya tienes cuenta? '),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Inicia sesión',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Beneficios de crear cuenta
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Beneficios de crear una cuenta:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkGreen,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _BenefitItem(
                        icon: Icons.favorite,
                        text: 'Guarda tus productos favoritos',
                      ),
                      const _BenefitItem(
                        icon: Icons.sync,
                        text: 'Sincroniza tu carrito en todos los dispositivos',
                      ),
                      const _BenefitItem(
                        icon: Icons.history,
                        text: 'Historial de compras y carritos guardados',
                      ),
                      const _BenefitItem(
                        icon: Icons.notifications,
                        text: 'Notificaciones de nuevos productos',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar los términos y condiciones'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Paso 1: Registrar al usuario en Firebase Auth
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Paso 2: Verificar que el usuario se haya creado correctamente
      final userId = authRepository.currentUser?.uid;
      if (userId == null) {
        throw Exception(
          'Error al crear la cuenta: No se pudo obtener el ID del usuario',
        );
      }

      // Paso 3: Guardar información adicional en Firestore
      bool firestoreSuccess = true;
      try {
        final userDataRepository = ref.read(userDataRepositoryProvider);

        // Establecemos un timeout para la operación de Firestore
        await Future.any([
          userDataRepository.updateUserProfile(
            userId: userId,
            email: _emailController.text.trim(),
            name: _nameController.text.trim(),
          ),
          // Si después de 10 segundos no hay respuesta, continuamos con un error controlado
          Future.delayed(const Duration(seconds: 10)).then((_) {
            throw TimeoutException('La operación de Firestore tardó demasiado');
          }),
        ]);
      } catch (firestoreError) {
        firestoreSuccess = false;
        print('Error al guardar datos en Firestore: $firestoreError');

        // Verificamos si el error está relacionado con PigeonUserDetails
        if (firestoreError.toString().contains('PigeonUserDetails') ||
            firestoreError.toString().contains('not a subtype')) {
          // Intento de recuperación específico para este error
          try {
            print('Intentando recuperación para error PigeonUserDetails...');
            // Esperar un momento para que Firebase pueda sincronizarse
            await Future.delayed(const Duration(seconds: 1));

            final userDataRepository = ref.read(userDataRepositoryProvider);
            // Intentar con un formato más simple y con timeout
            await Future.any([
              userDataRepository.updateUserProfile(
                userId: userId,
                email: _emailController.text.trim(),
                name: _nameController.text.trim(),
              ),
              // Si después de 5 segundos no hay respuesta, continuamos con un error controlado
              Future.delayed(const Duration(seconds: 5)).then((_) {
                throw TimeoutException(
                  'El intento de recuperación tardó demasiado',
                );
              }),
            ]);
            firestoreSuccess = true;
          } catch (recoveryError) {
            print('Error en el intento de recuperación: $recoveryError');
            // Continuamos sin lanzar excepción para no bloquear el registro
          }
        } else {
          print(
            'Error al guardar datos en Firestore, pero la cuenta se creó: $firestoreError',
          );
          // No lanzamos excepción para no bloquear el registro si Firestore falla
        }
      }

      // Paso 4: Esperar a que el estado de autenticación se actualice
      // Esto asegura que el usuario aparezca como registrado en lugar de invitado
      await authRepository.reloadCurrentUser();
      await Future.delayed(const Duration(milliseconds: 500));

      // Verificar que el usuario ya no sea anónimo
      final currentUser = authRepository.currentUser;
      if (currentUser != null && !currentUser.isAnonymous) {
        print('✅ Usuario registrado correctamente: ${currentUser.email}');
      }

      // Paso 5: Notificar éxito
      if (mounted) {
        final message = firestoreSuccess
            ? '¡Cuenta creada exitosamente!'
            : '¡Cuenta creada! Algunas funciones pueden no estar disponibles porque la base de datos no está configurada.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppTheme.primaryGreen,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navegación explícita a la pantalla principal
        Navigator.of(context).pushReplacementNamed(AppRouter.main);
      }
    } catch (e) {
      print('Error durante el registro: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e.toString())),
            backgroundColor: AppTheme.errorRed,
            duration: const Duration(seconds: 4),
          ),
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

  String _getErrorMessage(String error) {
    if (error.contains('email-already-in-use') ||
        error.contains('already in use')) {
      return 'Ya existe una cuenta con este email. Por favor, inicia sesión o usa otro correo.';
    } else if (error.contains('invalid-email')) {
      return 'El formato del email no es válido';
    } else if (error.contains('weak-password')) {
      return 'La contraseña es muy débil';
    } else if (error.contains('network-request-failed')) {
      return 'Error de conexión. Verifica tu internet';
    } else if (error.contains('operation-not-allowed')) {
      return 'El registro por email está deshabilitado. Contacta al soporte.';
    } else if (error.contains('reCAPTCHA')) {
      return 'Error de verificación de seguridad. Intenta nuevamente.';
    } else if (error.contains('PigeonUserDetails') ||
        error.contains('not a subtype')) {
      return 'Error interno de conversión de datos durante el registro. Hemos registrado el problema y se puede usar la app normalmente. Por favor, reinicia la aplicación si experimentas problemas.';
    } else if (error.contains('TimeoutException') ||
        error.contains('tardó demasiado')) {
      return 'La operación tomó demasiado tiempo. Tu cuenta se ha creado pero algunas funciones pueden no estar disponibles.';
    } else if (error.contains('database (default) does not exist') ||
        error.contains(
          'Error: La base de datos de Firestore no está configurada',
        )) {
      return 'Tu cuenta se ha creado correctamente, pero la base de datos no está disponible en este momento. Algunas funciones pueden estar limitadas.';
    } else {
      return 'Error al crear la cuenta: $error';
    }
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.darkGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppTheme.darkGreen, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
