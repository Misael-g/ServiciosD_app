import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/datasources/profiles_remote_ds.dart';
import '../../data/datasources/storage_remote_ds.dart';
import '../../data/models/profile_model.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/config/supabase_config.dart';

/// Pantalla de edición de perfil para Técnico (SIN ubicación)
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
    extends State<TechnicianEditProfilePage> {
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

  // Especialidades
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
    _loadProfileData();
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

      // Subir imagen si hay una nueva
      String? imageUrl = _profilePictureUrl;
      if (_selectedImage != null) {
        SnackbarHelper.showLoading(context, 'Subiendo foto...');
        imageUrl = await _storageDS.uploadProfilePicture(
          userId: userId,
          file: _selectedImage!,
        );
      }

      // Preparar datos (SIN ubicación)
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
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Seleccionar de Galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar Foto'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            if (_selectedImage != null || _profilePictureUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar Foto'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                    _profilePictureUrl = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showSpecialtiesSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Text(
                          'Selecciona tus especialidades',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Listo'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _availableSpecialties.length,
                      itemBuilder: (context, index) {
                        final specialty = _availableSpecialties[index];
                        final isSelected =
                            _selectedSpecialties.contains(specialty);

                        return CheckboxListTile(
                          title: Text(specialty),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setModalState(() {
                              if (value == true) {
                                _selectedSpecialties.add(specialty);
                              } else {
                                _selectedSpecialties.remove(specialty);
                              }
                            });
                            setState(() {});
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveProfile,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Foto
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(context).colorScheme.primary,
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
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: IconButton(
                        icon: const Icon(Icons.edit,
                            color: Colors.white, size: 20),
                        onPressed: _showImageOptions,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Nombre
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Nombre Completo',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: Validators.validateFullName,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),

            // Teléfono
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: Validators.validatePhone,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),

            // Email (no editable)
            TextFormField(
              initialValue: widget.profile.email,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
                enabled: false,
              ),
            ),
            const SizedBox(height: 32),

            // Especialidades
            InkWell(
              onTap: _isLoading ? null : _showSpecialtiesSelector,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Especialidades',
                  prefixIcon: Icon(Icons.build_outlined),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                child: _selectedSpecialties.isEmpty
                    ? const Text(
                        'Selecciona tus especialidades',
                        style: TextStyle(color: Colors.grey),
                      )
                    : Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: _selectedSpecialties
                            .map((s) => Chip(
                                  label: Text(s,
                                      style: const TextStyle(fontSize: 12)),
                                  visualDensity: VisualDensity.compact,
                                ))
                            .toList(),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Biografía
            TextFormField(
              controller: _bioController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Descripción / Biografía',
                hintText: 'Cuéntanos sobre tu experiencia...',
                prefixIcon: Icon(Icons.info_outline),
                alignLabelWithHint: true,
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
            const SizedBox(height: 24),

            // Nota informativa
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tu ubicación GPS se actualiza automáticamente cuando accedes a la pestaña de solicitudes',
                      style: TextStyle(
                        color: Colors.blue[900],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Botón guardar
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Guardar Cambios'),
            ),
          ],
        ),
      ),
    );
  }
}