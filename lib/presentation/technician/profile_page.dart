import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/datasources/profiles_remote_ds.dart';
import '../../data/models/profile_model.dart';
import '../../core/utils/snackbar_helper.dart';
import 'edit_profile_page.dart';
import 'portfolio_page.dart';

/// Pantalla de perfil del técnico (SIN tarifa/h)
class TechnicianProfilePage extends StatefulWidget {
  const TechnicianProfilePage({super.key});

  @override
  State<TechnicianProfilePage> createState() => _TechnicianProfilePageState();
}

class _TechnicianProfilePageState extends State<TechnicianProfilePage> {
  final ProfilesRemoteDataSource _profilesDS = ProfilesRemoteDataSource();

  ProfileModel? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final profile = await _profilesDS.getCurrentUserProfile();
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(context, 'Error al cargar perfil');
      }
    }
  }

  Future<void> _handleLogout() async {
    final authRepository = context.read<AuthRepository>();

    try {
      await authRepository.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error al cerrar sesión');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Foto de perfil
                  Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      backgroundImage: _profile?.profilePictureUrl != null
                          ? NetworkImage(_profile!.profilePictureUrl!)
                          : null,
                      child: _profile?.profilePictureUrl == null
                          ? Text(
                              _profile?.fullName[0].toUpperCase() ?? '?',
                              style: const TextStyle(
                                fontSize: 48,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nombre y rating
                  Text(
                    _profile?.fullName ?? '',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Colors.amber[700], size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${_profile?.averageRating?.toStringAsFixed(1) ?? "0.0"} '
                        '(${_profile?.totalReviews ?? 0} reseñas)',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  if (_profile?.bio != null && _profile!.bio!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        _profile!.bio!,
                        style: TextStyle(color: Colors.grey[700], height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),

                  // Ubicación actual
                  if (_profile?.address != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _profile!.address!,
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Especialidades
                  if (_profile?.specialties != null &&
                      _profile!.specialties!.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Especialidades',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _profile!.specialties!
                                  .map((s) => Chip(
                                        label: Text(s),
                                        backgroundColor:
                                            Theme.of(context).colorScheme.primaryContainer,
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Métricas (SIN tarifa/h)
                  _buildStatCard(
                    'Servicios Completados',
                    '${_profile?.completedServices ?? 0}',
                    Icons.check_circle,
                  ),
                  const SizedBox(height: 32),

                  // Opciones
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Editar Perfil'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      if (_profile != null) {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TechnicianEditProfilePage(profile: _profile!),
                          ),
                        );

                        if (result == true) {
                          _loadProfile();
                        }
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Mi Portafolio'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      if (_profile != null) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PortfolioPage(technician: _profile!),
                          ),
                        );
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: const Text('Actualizar Ubicación'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      if (_profile != null) {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TechnicianEditProfilePage(profile: _profile!),
                          ),
                        );

                        if (result == true) {
                          _loadProfile();
                        }
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Configuración'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      SnackbarHelper.showInfo(context, 'Por implementar');
                    },
                  ),
                  const Divider(),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar Sesión'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}