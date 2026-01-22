import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/utils/snackbar_helper.dart';

/// Pantalla de configuración del administrador
class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final authRepository = context.read<AuthRepository>();

    try {
      await authRepository.signOut();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showError(context, 'Error al cerrar sesión');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Perfil'),
            subtitle: const Text('Ver y editar información personal'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              SnackbarHelper.showInfo(context, 'Por implementar');
            },
          ),
          const Divider(),

          const SizedBox(height: 32),

          // Cerrar sesión
          OutlinedButton.icon(
            onPressed: () => _handleLogout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar Sesión'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}