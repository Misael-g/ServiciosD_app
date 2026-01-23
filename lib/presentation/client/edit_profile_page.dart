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

class EditProfilePage extends StatefulWidget {
  final ProfileModel profile;

  const EditProfilePage({
    super.key,
    required this.profile,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> 
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  final ProfilesRemoteDataSource _profilesDS = ProfilesRemoteDataSource();
  final StorageRemoteDataSource _storageDS = StorageRemoteDataSource();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  String? _profilePictureUrl;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _loadProfileData();
    _animationController.forward();
  }

  void _loadProfileData() {
    _fullNameController.text = widget.profile.fullName;
    _phoneController.text = widget.profile.phone ?? '';
    _profilePictureUrl = widget.profile.profilePictureUrl;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
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
                icon: Icons.photo_library_rounded,
                title: 'Seleccionar de Galería',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),

              _buildImageOption(
                icon: Icons.camera_alt_rounded,
                title: 'Tomar Foto',
                color: AppColors.success,
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),

              if (_selectedImage != null || _profilePictureUrl != null)
                _buildImageOption(
                  icon: Icons.delete_rounded,
                  title: 'Eliminar Foto',
                  color: AppColors.error,
                  onTap: () {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        centerTitle: true,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.check_rounded),
              onPressed: _saveProfile,
              tooltip: 'Guardar',
            ),
        ],
      ),
      body: ScaleTransition(
        scale: _scaleAnimation,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 8),

              // Avatar
              Center(
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
                        child: _selectedImage == null &&
                                _profilePictureUrl == null
                            ? Text(
                                widget.profile.fullName[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 48,
                                  color: Colors.white,
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
              ),

              const SizedBox(height: 40),

              // Formulario
              const SectionHeader(
                title: 'Información Personal',
                icon: Icons.person_rounded,
              ),

              const SizedBox(height: 16),

              // Nombre completo
              _buildTextField(
                controller: _fullNameController,
                label: 'Nombre Completo',
                hint: 'Juan Pérez',
                icon: Icons.person_outline_rounded,
                color: AppColors.primary,
                validator: Validators.validateFullName,
              ),

              const SizedBox(height: 16),

              // Teléfono
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

              // Email (no editable)
              _buildTextField(
                initialValue: widget.profile.email,
                label: 'Correo Electrónico',
                hint: 'tu@email.com',
                icon: Icons.email_rounded,
                color: AppColors.info,
                enabled: false,
              ),

              const SizedBox(height: 32),

              // Nota informativa
              InfoCard(
                message: 'La ubicación se establece automáticamente al crear una solicitud de servicio',
                icon: Icons.info_rounded,
                color: AppColors.info,
              ),

              const SizedBox(height: 32),

              // Botón guardar
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.white,
                            ),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_rounded),
                            SizedBox(width: 12),
                            Text(
                              'Guardar Cambios',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
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
}