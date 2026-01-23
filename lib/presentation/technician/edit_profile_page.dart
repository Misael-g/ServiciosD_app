import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/datasources/profiles_remote_ds.dart';
import '../../data/datasources/storage_remote_ds.dart';
import '../../data/models/profile_model.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/config/supabase_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_widgets.dart';

class TechnicianEditProfilePage extends StatefulWidget {
  final ProfileModel profile;

  const TechnicianEditProfilePage({
    super.key,
    required this.profile,
  });

  @override
  State<TechnicianEditProfilePage> createState() =>
      _TechnicianEditProfilePageState();
}

class _TechnicianEditProfilePageState
    extends State<TechnicianEditProfilePage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  final ProfilesRemoteDataSource _profilesDS = ProfilesRemoteDataSource();
  final StorageRemoteDataSource _storageDS = StorageRemoteDataSource();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  String? _profilePictureUrl;
  bool _isLoading = false;
  late AnimationController _animationController;

  final List<String> _availableSpecialties = [
    'Electricista',
    'Plomero',
    'Carpintero',
    'Pintor',
    'Mecánico',
    'Jardinero',
    'Limpieza',
    'Reparación de Electrodomésticos',
    'Instalación de TV/Internet',
    'Albañil',
    'Cerrajero',
    'Otros',
  ];

  List<String> _selectedSpecialties = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadProfileData();
    _animationController.forward();
  }

  void _loadProfileData() {
    _fullNameController.text = widget.profile.fullName;
    _phoneController.text = widget.profile.phone ?? '';
    _bioController.text = widget.profile.bio ?? '';
    _profilePictureUrl = widget.profile.profilePictureUrl;
    _selectedSpecialties = widget.profile.specialties ?? [];
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Error al seleccionar imagen');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Error al tomar foto');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSpecialties.isEmpty) {
      SnackbarHelper.showError(
        context,
        'Debes seleccionar al menos una especialidad',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw Exception('No hay usuario autenticado');
      }

      String? imageUrl = _profilePictureUrl;
      if (_selectedImage != null) {
        imageUrl = await _storageDS.uploadProfilePicture(
          userId: userId,
          file: _selectedImage!,
        );
      }

      final updates = <String, dynamic>{
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'bio': _bioController.text.trim(),
        'specialties': _selectedSpecialties,
        'profile_picture_url': imageUrl,
      };

      await _profilesDS.updateProfileFields(userId, updates);

      if (mounted) {
        SnackbarHelper.showSuccess(context, '¡Perfil actualizado!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'Error al actualizar: ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Foto de Perfil',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              _buildImageOption(
                Icons.photo_library_rounded,
                'Seleccionar de Galería',
                AppColors.primary,
                () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),

              _buildImageOption(
                Icons.camera_alt_rounded,
                'Tomar Foto',
                AppColors.success,
                () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),

              if (_selectedImage != null || _profilePictureUrl != null)
                _buildImageOption(
                  Icons.delete_rounded,
                  'Eliminar Foto',
                  AppColors.error,
                  () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                      _profilePictureUrl = null;
                    });
                  },
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showSpecialtiesSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Column(
                  children: [
                    // Handle
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 20),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.build_circle_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Especialidades',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {});
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Listo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Lista
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _availableSpecialties.length,
                        itemBuilder: (context, index) {
                          final specialty = _availableSpecialties[index];
                          final isSelected =
                              _selectedSpecialties.contains(specialty);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () {
                                setModalState(() {
                                  if (isSelected) {
                                    _selectedSpecialties.remove(specialty);
                                  } else {
                                    _selectedSpecialties.add(specialty);
                                  }
                                });
                                setState(() {});
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withValues(alpha: 0.1)
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.border,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.check_circle_rounded
                                          : Icons.radio_button_unchecked_rounded,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        specialty,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // AppBar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            actions: [
              if (!_isLoading)
                IconButton(
                  icon: const Icon(Icons.check_rounded),
                  onPressed: _saveProfile,
                  tooltip: 'Guardar',
                ),
            ],
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
              ),
              title: const Text(
                'Editar Perfil',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              centerTitle: true,
            ),
          ),

          // Contenido
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _animationController,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // Avatar
                    _buildAvatarSection(),
                    const SizedBox(height: 32),

                    // Formulario
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(
                            title: 'Información Personal',
                            icon: Icons.person_rounded,
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: _fullNameController,
                            label: 'Nombre Completo',
                            hint: 'Juan Pérez',
                            icon: Icons.person_outline_rounded,
                            color: AppColors.primary,
                            validator: Validators.validateFullName,
                          ),

                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: _phoneController,
                            label: 'Teléfono',
                            hint: '0999123456',
                            icon: Icons.phone_rounded,
                            color: AppColors.success,
                            keyboardType: TextInputType.phone,
                            validator: Validators.validatePhone,
                          ),

                          const SizedBox(height: 16),

                          _buildTextField(
                            initialValue: widget.profile.email,
                            label: 'Correo Electrónico',
                            hint: 'tu@email.com',
                            icon: Icons.email_rounded,
                            color: AppColors.info,
                            enabled: false,
                          ),

                          const SizedBox(height: 32),

                          // Especialidades
                          const SectionHeader(
                            title: 'Especialidades',
                            icon: Icons.build_circle_rounded,
                          ),
                          const SizedBox(height: 16),

                          InkWell(
                            onTap: _isLoading ? null : _showSpecialtiesSelector,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                                boxShadow: AppShadows.small,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.workspace_premium_rounded,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'Tus especialidades',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_drop_down_rounded,
                                        color: AppColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                  if (_selectedSpecialties.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _selectedSpecialties
                                          .map((s) => Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: AppColors.primary
                                                        .withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.verified_rounded,
                                                      size: 14,
                                                      color: AppColors.primary,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      s,
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
                          ),

                          const SizedBox(height: 32),

                          // Bio
                          const SectionHeader(
                            title: 'Descripción',
                            icon: Icons.info_rounded,
                          ),
                          const SizedBox(height: 16),

                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                              boxShadow: AppShadows.small,
                            ),
                            child: TextFormField(
                              controller: _bioController,
                              maxLines: 5,
                              decoration: const InputDecoration(
                                hintText:
                                    'Cuéntanos sobre tu experiencia como técnico...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(20),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'La descripción es requerida';
                                }
                                if (value.length < 20) {
                                  return 'Escribe al menos 20 caracteres';
                                }
                                return null;
                              },
                              enabled: !_isLoading,
                            ),
                          ),

                          const SizedBox(height: 24),

                          InfoCard(
                            message:
                                'Tu ubicación GPS se actualiza automáticamente cuando accedes a solicitudes',
                            icon: Icons.info_rounded,
                            color: AppColors.info,
                          ),

                          const SizedBox(height: 32),

                          // Botón guardar
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _saveProfile,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          AppColors.white,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.save_rounded, size: 24),
                              label: Text(
                                _isLoading ? 'Guardando...' : 'Guardar Cambios',
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

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Stack(
        children: [
          // Círculo decorativo
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.3),
                  AppColors.primary.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white,
                width: 4,
              ),
              boxShadow: AppShadows.medium,
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.primary,
              backgroundImage: _selectedImage != null
                  ? FileImage(_selectedImage!)
                  : (_profilePictureUrl != null
                      ? NetworkImage(_profilePictureUrl!)
                      : null) as ImageProvider?,
              child:
                  _selectedImage == null && _profilePictureUrl == null
                      ? Text(
                          widget.profile.fullName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 48,
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
            ),
          ),
          // Botón editar
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primaryDark,
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.white,
                  width: 3,
                ),
                boxShadow: AppShadows.medium,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.white,
                  size: 22,
                ),
                onPressed: _showImageOptions,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    String? initialValue,
    required String label,
    required String hint,
    required IconData icon,
    required Color color,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: enabled ? AppShadows.small : null,
      ),
      child: TextFormField(
        controller: controller,
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
          enabled: enabled,
        ),
        keyboardType: keyboardType,
        validator: validator,
        textCapitalization: TextCapitalization.words,
      ),
    );
  }

  Widget _buildImageOption(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}