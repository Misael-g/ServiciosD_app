// lib/presentation/admin/verification_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_widgets.dart';
import '../../data/datasources/profiles_remote_ds.dart';
import '../../data/datasources/storage_remote_ds.dart';
import '../../data/models/profile_model.dart';
import '../../core/utils/snackbar_helper.dart';

class VerificationDetailPage extends StatefulWidget {
  final String technicianId;

  const VerificationDetailPage({
    super.key,
    required this.technicianId,
  });

  @override
  State<VerificationDetailPage> createState() => _VerificationDetailPageState();
}

class _VerificationDetailPageState extends State<VerificationDetailPage> {
  final ProfilesRemoteDataSource _profilesDS = ProfilesRemoteDataSource();
  final StorageRemoteDataSource _storageDS = StorageRemoteDataSource();
  final TextEditingController _notesController = TextEditingController();

  ProfileModel? _technician;
  Map<String, String?> _documentUrls = {};
  bool _isLoading = true;
  bool _isProcessing = false;

  static const List<String> _documentTypes = [
    'id_front',
    'id_back',
    'certificate',
  ];

  @override
  void initState() {
    super.initState();
    _loadTechnicianData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadTechnicianData() async {
    setState(() => _isLoading = true);

    try {
      final technician = await _profilesDS.getProfileById(widget.technicianId);

      final documentUrls = <String, String?>{};
      for (final docType in _documentTypes) {
        try {
          final url = await _storageDS.getVerificationDocumentUrl(
            technicianId: widget.technicianId,
            documentType: docType,
          );
          documentUrls[docType] = url;
        } catch (e) {
          documentUrls[docType] = null;
        }
      }

      setState(() {
        _technician = technician;
        _documentUrls = documentUrls;
        _notesController.text = technician.verificationNotes ?? '';
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(context, 'Error al cargar datos');
      }
    }
  }

  Future<void> _approveVerification() async {
    setState(() => _isProcessing = true);

    try {
      await _profilesDS.updateVerificationStatus(
        widget.technicianId,
        status: 'approved',
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          '¡Técnico verificado exitosamente!',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error al aprobar: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _rejectVerification() async {
    if (_notesController.text.trim().isEmpty) {
      SnackbarHelper.showError(
        context,
        'Debes agregar notas explicando el motivo del rechazo',
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await _profilesDS.updateVerificationStatus(
        widget.technicianId,
        status: 'rejected',
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          'Verificación rechazada',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error al rechazar: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _viewImageFullscreen(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.black,
          appBar: AppBar(
            backgroundColor: AppColors.black,
            iconTheme: const IconThemeData(color: AppColors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getDocumentTitle(String type) {
    switch (type) {
      case 'id_front':
        return 'Cédula (Frontal)';
      case 'id_back':
        return 'Cédula (Reverso)';
      case 'certificate':
        return 'Certificado Profesional';
      default:
        return 'Documento';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        title: const Text('Verificación de Técnico'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Technician Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.small,
                  ),
                  child: Column(
                    children: [
                      ProfileAvatar(
                        name: _technician?.fullName ?? '?',
                        imageUrl: _technician?.profilePictureUrl,
                        radius: 48,
                        showBorder: true,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _technician?.fullName ?? '',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _technician?.email ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (_technician?.phone != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _technician!.phone!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_technician?.specialties != null &&
                          _technician!.specialties!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: _technician!.specialties!
                              .map((specialty) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.primary.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.verified,
                                          size: 16,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          specialty,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Documents Section
                const SectionHeader(
                  title: 'Documentos de Verificación',
                  icon: Icons.folder_outlined,
                ),
                const SizedBox(height: 16),

                ..._documentTypes.map((docType) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildDocumentCard(
                      _getDocumentTitle(docType),
                      docType,
                      _documentUrls[docType],
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // Notes Section
                const SectionHeader(
                  title: 'Notas de Verificación',
                  subtitle: 'Opcional - visible para el técnico',
                  icon: Icons.note_outlined,
                ),
                const SizedBox(height: 16),

                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _notesController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Agregar comentarios sobre la verificación...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    enabled: !_isProcessing,
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: _isProcessing ? null : _rejectVerification,
                          icon: const Icon(Icons.close),
                          label: const Text('Rechazar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(
                              color: AppColors.error,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _approveVerification,
                          icon: _isProcessing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: const Text('Aprobar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildDocumentCard(String title, String type, String? url) {
    return InkWell(
      onTap: url != null ? () => _viewImageFullscreen(url) : null,
      borderRadius: BorderRadius.circular(AppBorderRadius.md),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: url != null
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        url != null ? Icons.check_circle : Icons.warning,
                        color: url != null ? AppColors.success : AppColors.error,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (url != null)
                  const Icon(
                    Icons.visibility,
                    color: AppColors.primary,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (url != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: url,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 180,
                    color: AppColors.background,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 180,
                    color: AppColors.background,
                    child: const Center(
                      child: Icon(Icons.error, color: AppColors.error),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.border,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.file_present,
                        size: 48,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Documento no disponible',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}