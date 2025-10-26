import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_router.dart';
import '../core/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/repository_providers.dart';

class AppDrawer extends ConsumerWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.primaryGreen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.eco, color: Colors.white, size: 48),
                const SizedBox(height: 8),
                const Text(
                  'Gluten Search',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (authState.value != null)
                  Text(
                    authState.value!.isAnonymous
                        ? 'Usuario Invitado'
                        : 'Usuario Registrado',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
              ],
            ),
          ),
          _DrawerItem(
            icon: Icons.search,
            title: 'Búsqueda Principal',
            route: AppRouter.main,
            currentRoute: currentRoute,
            onTap: () {
              Navigator.pop(context);
              if (currentRoute != AppRouter.main) {
                Navigator.pushReplacementNamed(context, AppRouter.main);
              }
            },
          ),
          _DrawerItem(
            icon: Icons.home,
            title: 'Catálogo de Productos',
            route: AppRouter.catalog,
            currentRoute: currentRoute,
            onTap: () {
              Navigator.pop(context);
              if (currentRoute != AppRouter.catalog) {
                Navigator.pushReplacementNamed(context, AppRouter.catalog);
              }
            },
          ),
          _DrawerItem(
            icon: Icons.person,
            title: 'Perfil',
            route: AppRouter.profile,
            currentRoute: currentRoute,
            onTap: () {
              Navigator.pop(context);
              if (currentRoute != AppRouter.profile) {
                Navigator.pushReplacementNamed(context, AppRouter.profile);
              }
            },
          ),
          const Divider(),
          if (authState.value != null)
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.errorRed),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: AppTheme.errorRed),
              ),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await ref.read(authRepositoryProvider).signOut();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sesión cerrada exitosamente'),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al cerrar sesión: $e'),
                        backgroundColor: AppTheme.errorRed,
                      ),
                    );
                  }
                }
              },
            ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String route;
  final String currentRoute;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.route,
    required this.currentRoute,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentRoute == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primaryGreen : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppTheme.primaryGreen : Colors.black87,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppTheme.lightGreen,
      onTap: onTap,
    );
  }
}
