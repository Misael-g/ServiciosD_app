import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/datasources/profiles_remote_ds.dart';
import '../../data/datasources/storage_remote_ds.dart';
import '../../data/models/profile_model.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/config/supabase_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_widgets.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> 
    with SingleTickerProviderStateMixin {
  final ProfilesRemoteDataSource _profilesDS = ProfilesRemoteDataSource();
  final StorageRemoteDataSource _storageDS = StorageRemoteDataSource();
  final ImagePicker _imagePicker = ImagePicker();

  ProfileModel? _profile;
  bool _isLoading = true;
  bool _isUploading = false;
  late AnimationController _animationController;

  // Archivos locales
  File? _idFrontFile;
  File? _idBackFile;
  File? _certificateFile;

  // URLs existentes
  String? _idFrontUrl;
  String? _idBackUrl;
  String? _certificateUrl;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadProfile();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final profile = await _profilesDS.getCurrentUserProfile();
      setState(() {
        _profile = profile;
        _isLoading = false;
      });

      if (profile.verificationStatus == 'approved') {
        _animationController.forward();
      } else {
        await _loadExistingDocuments();
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(context, 'Error al cargar perfil');
      }
    }
  }

  Future<void> _loadExistingDocuments() async {
    if (_profile == null) return;

    try {
      final documents = await Future.wait([
        _storageDS.getVerificationDocumentUrl(
          technicianId: _profile!.id,
          documentType: 'id_front',
        ),
        _storageDS.getVerificationDocumentUrl(
          technicianId: _profile!.id,
          documentType: 'id_back',
        ),
        _storageDS.getVerificationDocumentUrl(
          technicianId: _profile!.id,
          documentType: 'certificate',
        ),
      ]);

      setState(() {
        _idFrontUrl = documents[0];
        _idBackUrl = documents[1];
        _certificateUrl = documents[2];
      });
    } catch (e) {
      // No hacer nada si no hay documentos
    }
  }

  Future<void> _pickDocument(String documentType) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          switch (documentType) {
            case 'id_front':
              _idFrontFile = File(image.path);
              break;
            case 'id_back':
              _idBackFile = File(image.path);
              break;
            case 'certificate':
              _certificateFile = File(image.path);
              break;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error al seleccionar documento');
      }
    }
  }

  Future<void> _submitDocuments() async {
    if (_idFrontFile == null || _idBackFile == null || _certificateFile == null) {
      SnackbarHelper.showError(
        context,
        'Debes subir todos los documentos requeridos',
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) throw Exception('No hay usuario autenticado');

      // Subir documentos
      await Future.wait([
        _storageDS.uploadVerificationDocument(
          technicianId: userId,
          file: _idFrontFile!,
          documentType: 'id_front',
        ),
        _storageDS.uploadVerificationDocument(
          technicianId: userId,
          file: _idBackFile!,
          documentType: 'id_back',
        ),
        _storageDS.uploadVerificationDocument(
          technicianId: userId,
          file: _certificateFile!,
          documentType: 'certificate',
        ),
      ]);

      // Actualizar estado a verificación pendiente
      await _profilesDS.updateVerificationStatus(
        userId,
        status: 'pending',
        notes: 'Documentos enviados para revisión',
      );

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          '¡Documentos enviados! Revisaremos tu solicitud pronto',
        );
        _loadProfile();
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error al enviar documentos');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile?.verificationStatus == 'approved') {
      return _buildApprovedScreen();
    }

    if (_profile?.verificationStatus == 'pending') {
      return _buildPendingScreen();
    }

    return _buildUploadScreen();
  }

  Widget _buildApprovedScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _animationController,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animación de éxito
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.success,
                                AppColors.success.withValues(alpha: 0.8),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success.withValues(alpha: 0.3),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            size: 80,
                            color: AppColors.white,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  const Text(
                    '¡Verificado!',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                      letterSpacing: -1,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Tu cuenta ha sido verificada exitosamente',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Stats
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadows.medium,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.success,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ya puedes',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Enviar Cotizaciones',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        const Divider(height: 1),
                        
                        const SizedBox(height: 20),

                        _buildBenefit(
                          Icons.work_rounded,
                          'Acceso a todas las solicitudes',
                        ),
                        const SizedBox(height: 12),
                        _buildBenefit(
                          Icons.monetization_on_rounded,
                          'Envía cotizaciones ilimitadas',
                        ),
                        const SizedBox(height: 12),
                        _buildBenefit(
                          Icons.star_rounded,
                          'Construye tu reputación',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navegar a solicitudes disponibles
                        SnackbarHelper.showInfo(
                          context,
                          'Ve a la pestaña de Solicitudes',
                        );
                      },
                      icon: const Icon(Icons.explore_rounded, size: 24),
                      label: const Text(
                        'Explorar Solicitudes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _animationController,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animación de espera
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(seconds: 2),
                    builder: (context, value, child) {
                      return Transform.rotate(
                        angle: value * 6.28,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.warning,
                                AppColors.warning.withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.hourglass_empty_rounded,
                            size: 60,
                            color: AppColors.white,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  const Text(
                    'En Revisión',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.warning,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Tu solicitud está siendo revisada',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 40),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadows.small,
                    ),
                    child: Column(
                      children: [
                        _buildTimelineItem(
                          Icons.upload_file_rounded,
                          'Documentos enviados',
                          true,
                        ),
                        _buildTimelineConnector(true),
                        _buildTimelineItem(
                          Icons.search_rounded,
                          'Revisión en proceso',
                          true,
                        ),
                        _buildTimelineConnector(false),
                        _buildTimelineItem(
                          Icons.verified_rounded,
                          'Aprobación final',
                          false,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  InfoCard(
                    message: 'Te notificaremos cuando tu cuenta sea verificada. Esto puede tomar hasta 48 horas.',
                    icon: Icons.notifications_active_rounded,
                    color: AppColors.info,
                  ),

                  if (_profile?.verificationNotes != null &&
                      _profile!.verificationNotes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.comment_rounded,
                                color: AppColors.warning,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Notas del administrador:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _profile!.verificationNotes!,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // AppBar
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primaryDark,
                    ],
                  ),
                ),
                child: const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              size: 32,
                              color: AppColors.white,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Verificación',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Sube tus documentos para comenzar',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Contenido
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _animationController,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // Info Card
                    InfoCard(
                      message: 'Para proteger a nuestros clientes, todos los técnicos deben verificar su identidad',
                      icon: Icons.security_rounded,
                      color: AppColors.info,
                    ),

                    const SizedBox(height: 32),

                    // Documentos requeridos
                    const SectionHeader(
                      title: 'Documentos Requeridos',
                      icon: Icons.folder_rounded,
                    ),

                    const SizedBox(height: 16),

                    _buildDocumentUpload(
                      'Cédula (Frontal)',
                      'Foto clara del frente de tu cédula',
                      Icons.badge_rounded,
                      'id_front',
                      _idFrontFile,
                      _idFrontUrl,
                    ),

                    const SizedBox(height: 16),

                    _buildDocumentUpload(
                      'Cédula (Reverso)',
                      'Foto clara del reverso de tu cédula',
                      Icons.badge_rounded,
                      'id_back',
                      _idBackFile,
                      _idBackUrl,
                    ),

                    const SizedBox(height: 16),

                    _buildDocumentUpload(
                      'Certificado Profesional',
                      'Certificado, diploma o documento que avale tu experiencia',
                      Icons.workspace_premium_rounded,
                      'certificate',
                      _certificateFile,
                      _certificateUrl,
                    ),

                    const SizedBox(height: 32),

                    // Tips
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.warning.withValues(alpha: 0.1),
                            AppColors.warning.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.tips_and_updates_rounded,
                                  color: AppColors.warning,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Consejos',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTip('✓ Asegúrate de que las fotos sean claras'),
                          _buildTip('✓ La información debe ser legible'),
                          _buildTip('✓ Evita fotos borrosas o con reflejos'),
                          _buildTip('✓ Usa buena iluminación'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // Botón de enviar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _submitDocuments,
              icon: _isUploading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.white,
                        ),
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 24),
              label: Text(
                _isUploading ? 'Enviando...' : 'Enviar Documentos',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentUpload(
    String title,
    String description,
    IconData icon,
    String documentType,
    File? file,
    String? url,
  ) {
    final hasDocument = file != null || url != null;

    return InkWell(
      onTap: () => _pickDocument(documentType),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasDocument
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.border,
            width: hasDocument ? 2 : 1,
          ),
          boxShadow: AppShadows.small,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasDocument
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    hasDocument ? Icons.check_circle_rounded : icon,
                    color: hasDocument ? AppColors.success : AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
              ],
            ),
            
            if (file != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  file,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ] else if (url != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  url,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.success, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(IconData icon, String text, bool isCompleted) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted
                ? AppColors.success
                : AppColors.background,
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted
                  ? AppColors.success
                  : AppColors.border,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isCompleted ? AppColors.white : AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w500,
              color: isCompleted
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineConnector(bool isActive) {
    return Container(
      margin: const EdgeInsets.only(left: 19),
      width: 2,
      height: 30,
      color: isActive ? AppColors.success : AppColors.border,
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }
}