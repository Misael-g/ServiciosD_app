import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_widgets.dart';
import '../../data/datasources/profiles_remote_ds.dart';
import '../../data/models/profile_model.dart';
import '../../core/utils/snackbar_helper.dart';
import 'verification_detail_page.dart';

class PendingVerificationsPage extends StatefulWidget {
  const PendingVerificationsPage({super.key});

  @override
  State<PendingVerificationsPage> createState() =>
      _PendingVerificationsPageState();
}

class _PendingVerificationsPageState extends State<PendingVerificationsPage> {
  final ProfilesRemoteDataSource _profilesDS = ProfilesRemoteDataSource();

  List<ProfileModel> _pendingTechnicians = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingVerifications();
  }

  Future<void> _loadPendingVerifications() async {
    setState(() => _isLoading = true);

    try {
      final technicians = await _profilesDS.getPendingVerifications();
      setState(() {
        _pendingTechnicians = technicians;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(context, 'Error al cargar verificaciones');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        title: const Text('Verificaciones Pendientes'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPendingVerifications,
              child: _pendingTechnicians.isEmpty
                  ? const EmptyState(
                      icon: Icons.check_circle_outline,
                      title: 'Todo verificado',
                      message: 'No hay técnicos pendientes de verificación',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _pendingTechnicians.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final technician = _pendingTechnicians[index];
                        return _buildTechnicianCard(technician);
                      },
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
            builder: (_) => VerificationDetailPage(
              technicianId: technician.id,
            ),
          ),
        ).then((_) => _loadPendingVerifications());
      },
      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.small,
        ),
        child: Column(
          children: [
            Row(
              children: [
                ProfileAvatar(
                  name: technician.fullName,
                  imageUrl: technician.profilePictureUrl,
                  radius: 32,
                  showBorder: true,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        technician.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        technician.email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (technician.phone != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              technician.phone!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.schedule,
                    color: AppColors.warning,
                    size: 24,
                  ),
                ),
              ],
            ),
            
            if (technician.specialties != null &&
                technician.specialties!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: technician.specialties!
                      .map((specialty) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              specialty,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}