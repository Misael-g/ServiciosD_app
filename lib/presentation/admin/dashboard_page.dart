// lib/presentation/admin/dashboard_page.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_widgets.dart';
import '../../data/datasources/profiles_remote_ds.dart';
import '../../data/models/profile_model.dart';
import 'pending_verifications_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _pendingVerifications = 0;
  int _totalRequests = 0;
  int _activeRequests = 0;
  int _totalTechnicians = 0;
  bool _isLoading = true;
  List<ProfileModel> _pendingTechnicians = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      final profilesDS = ProfilesRemoteDataSource();
      final pending = await profilesDS.getPendingVerifications();
      
      setState(() {
        _pendingVerifications = pending.length;
        _pendingTechnicians = pending;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        title: const Text('Panel de Administración'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primaryDark,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings_rounded,
                          size: 48,
                          color: AppColors.white,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Panel Administrativo',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Gestión y control de TecniHogar',
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

                  // Quick Actions
                  if (_pendingVerifications > 0)
                    InfoCard(
                      message: 'Tienes $_pendingVerifications técnico(s) pendiente(s) de verificación',
                      icon: Icons.pending_actions,
                      color: AppColors.warning,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PendingVerificationsPage(),
                          ),
                        ).then((_) => _loadStats());
                      },
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Stats Section
                  const SectionHeader(
                    title: 'Estadísticas Generales',
                    icon: Icons.analytics_outlined,
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Verificaciones\nPendientes',
                          value: _pendingVerifications.toString(),
                          icon: Icons.pending_actions,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          label: 'Solicitudes\nActivas',
                          value: _activeRequests.toString(),
                          icon: Icons.work_outline,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Total\nSolicitudes',
                          value: _totalRequests.toString(),
                          icon: Icons.list_alt_rounded,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          label: 'Técnicos\nActivos',
                          value: _totalTechnicians.toString(),
                          icon: Icons.people_outline,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),

                  // Pending Technicians
                  SectionHeader(
                    title: 'Técnicos Pendientes',
                    subtitle: 'Requieren aprobación',
                    icon: Icons.verified_user_outlined,
                    action: _pendingTechnicians.isNotEmpty
                        ? TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PendingVerificationsPage(),
                                ),
                              ).then((_) => _loadStats());
                            },
                            child: const Text('Ver todos'),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  
                  if (_pendingTechnicians.isEmpty)
                    const EmptyState(
                      icon: Icons.check_circle_outline,
                      title: 'Todo al día',
                      message: 'No hay técnicos pendientes de aprobación',
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _pendingTechnicians.length > 3
                          ? 3
                          : _pendingTechnicians.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final technician = _pendingTechnicians[index];
                        return _buildTechnicianCard(technician);
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildTechnicianCard(ProfileModel technician) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PendingVerificationsPage(),
          ),
        ).then((_) => _loadStats());
      },
      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ProfileAvatar(
              name: technician.fullName,
              imageUrl: technician.profilePictureUrl,
              radius: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    technician.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    technician.email,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (technician.specialties != null &&
                      technician.specialties!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: technician.specialties!
                          .take(2)
                          .map((specialty) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  specialty,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}