import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/utils/snackbar_helper.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        title: const Text('Configuración'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Admin Profile Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.secondary,
                  AppColors.secondaryLight,
                ],
              ),
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              boxShadow: AppShadows.medium,
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.white,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 36,
                    color: AppColors.secondary,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Administrador',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Control total del sistema',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // Settings Options
          _buildSettingsCard(
            icon: Icons.person_outline,
            title: 'Mi Perfil',
            subtitle: 'Ver y editar información personal',
            onTap: () {
              SnackbarHelper.showInfo(context, 'Por implementar');
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildSettingsCard(
            icon: Icons.notifications_outlined,
            title: 'Notificaciones',
            subtitle: 'Configurar alertas y avisos',
            onTap: () {
              SnackbarHelper.showInfo(context, 'Por implementar');
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildSettingsCard(
            icon: Icons.security_outlined,
            title: 'Seguridad',
            subtitle: 'Cambiar contraseña y privacidad',
            onTap: () {
              SnackbarHelper.showInfo(context, 'Por implementar');
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildSettingsCard(
            icon: Icons.help_outline,
            title: 'Ayuda y Soporte',
            subtitle: 'Centro de ayuda y documentación',
            onTap: () {
              SnackbarHelper.showInfo(context, 'Por implementar');
            },
          ),

          const SizedBox(height: 32),

          // Logout Button
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: ListTile(
              onTap: () => _handleLogout(context),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.logout,
                  color: AppColors.error,
                ),
              ),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
              subtitle: const Text(
                'Salir de la cuenta de administrador',
                style: TextStyle(fontSize: 13),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}