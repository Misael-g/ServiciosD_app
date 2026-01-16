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
          // Sección de cuenta
          const Text(
            'Cuenta',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

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

          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Cambiar Contraseña'),
            subtitle: const Text('Actualizar contraseña de acceso'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              SnackbarHelper.showInfo(context, 'Por implementar');
            },
          ),
          const Divider(),

          const SizedBox(height: 32),

          // Sección de sistema
          const Text(
            'Sistema',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text('Gestión de Usuarios'),
            subtitle: const Text('Administrar usuarios del sistema'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              SnackbarHelper.showInfo(context, 'Por implementar');
            },
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Reportes'),
            subtitle: const Text('Ver estadísticas y reportes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              SnackbarHelper.showInfo(context, 'Por implementar');
            },
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notificaciones'),
            subtitle: const Text('Configurar alertas del sistema'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              SnackbarHelper.showInfo(context, 'Por implementar');
            },
          ),
          const Divider(),

          const SizedBox(height: 32),

          // Sección de información
          const Text(
            'Información',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Acerca de'),
            subtitle: const Text('Versión 1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Servicios Técnicos',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2026 Todos los derechos reservados',
              );
            },
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Ayuda'),
            subtitle: const Text('Centro de ayuda y soporte'),
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