import 'package:flutter/material.dart';
import '../screens/views/main_screen.dart';
import '../screens/views/catalog_screen.dart';
import '../screens/views/cart_screen.dart';
import '../screens/views/profile_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';

class AppRouter {
  static const String main = '/';
  static const String catalog = '/catalog';
  static const String login = '/login';
  static const String register = '/register';
  static const String cart = '/cart';
  static const String profile = '/profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case main:
        return MaterialPageRoute(
          builder: (_) => const MainScreen(),
          settings: settings,
        );
      case catalog:
        return MaterialPageRoute(
          builder: (_) => const CatalogScreen(),
          settings: settings,
        );
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
          settings: settings,
        );
      case cart:
        return MaterialPageRoute(
          builder: (_) => const CartScreen(),
          settings: settings,
        );
      case profile:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Página no encontrada'))),
        );
    }
  }
}
