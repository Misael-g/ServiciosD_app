import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../data/datasources/profiles_remote_ds.dart';
import '../../data/datasources/storage_remote_ds.dart';
import '../../data/models/profile_model.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/location_helper.dart';
import '../../core/config/supabase_config.dart';

/// Pantalla de edición de perfil para Técnico
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

class _TechnicianEditProfilePageState extends State<TechnicianEditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _bioController = TextEditingController();
  final _baseRateController = TextEditingController();

  final ProfilesRemoteDataSource _profilesDS = ProfilesRemoteDataSource();
  final StorageRemoteDataSource _storageDS = StorageRemoteDataSource();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  String? _profilePictureUrl;
  Position? _currentPosition;
  bool _isLoading = false;
  bool _isGettingLocation = false;

  // Especialidades disponibles
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

  // Zonas de cobertura disponibles
  final List<String> _availableZones = [
    'Norte',
    'Sur',
    'Centro',
    'Este',
    'Oeste',
    'Todo el área metropolitana',
  ];

  List<String> _selectedZones = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    _fullNameController.text = widget.profile.fullName;
    _phoneController.text = widget.profile.phone ?? '';
    _addressController.text = widget.profile.address ?? '';
    _bioController.text = widget.profile.bio ?? '';
    _baseRateController.text =
        widget.profile.baseRate?.toStringAsFixed(0) ?? '';
    _profilePictureUrl = widget.profile.profilePictureUrl;

    // Cargar especialidades seleccionadas
    _selectedSpecialties = widget.profile.specialties ?? [];

    // Cargar zonas de cobertura
    _selectedZones = widget.profile.coverageZones ?? [];

    if (widget.profile.latitude != null && widget.profile.longitude != null) {
      _currentPosition = Position(
        latitude: widget.profile.latitude!,
        longitude: widget.profile.longitude!,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    _baseRateController.dispose();
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

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      final position = await LocationHelper.getCurrentLocation();

      if (position != null) {
        setState(() => _currentPosition = position);

        try {
          final placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );

          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            final address =
                '${place.street}, ${place.locality}, ${place.country}';
            _addressController.text = address;
          }
        } catch (e) {
          // Silenciosamente fallar
        }
      } else {
        if (mounted) {
          SnackbarHelper.showError(
            context,
            'No se pudo obtener la ubicación',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error al obtener ubicación');
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
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

    if (_selectedZones.isEmpty) {
      SnackbarHelper.showError(
        context,
        'Debes seleccionar al menos una zona de cobertura',
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

      // Preparar datos de actualización
      final updates = <String, dynamic>{
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'bio': _bioController.text.trim(),
        'base_rate': double.parse(_baseRateController.text),
        'specialties': _selectedSpecialties,
        'coverage_zones': _selectedZones,
        'profile_picture_url': imageUrl,
      };

      // Actualizar ubicación si existe
      if (_currentPosition != null) {
        updates['location'] = LocationHelper.coordinatesToPostGIS(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
      }

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
                            setState(() {}); // Actualizar widget principal
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

  void _showZonesSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Zonas de cobertura',
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
              ...(_availableZones.map((zone) {
                final isSelected = _selectedZones.contains(zone);
                return CheckboxListTile(
                  title: Text(zone),
                  value: isSelected,
                  onChanged: (bool? value) {
                    setModalState(() {
                      if (value == true) {
                        _selectedZones.add(zone);
                      } else {
                        _selectedZones.remove(zone);
                      }
                    });
                    setState(() {}); // Actualizar widget principal
                  },
                );
              })),
              const SizedBox(height: 16),
            ],
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
            // Foto de perfil
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
                    child: _selectedImage == null && _profilePictureUrl == null
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
                        icon:
                            const Icon(Icons.edit, color: Colors.white, size: 20),
                        onPressed: _showImageOptions,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Información básica
            Text(
              'Información Básica',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Nombre completo
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Nombre Completo',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: Validators.validateFullName,
              enabled: !_isLoading,
              textCapitalization: TextCapitalization.words,
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

            // Información profesional
            Text(
              'Información Profesional',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

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
                                  label: Text(s, style: const TextStyle(fontSize: 12)),
                                  visualDensity: VisualDensity.compact,
                                ))
                            .toList(),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Tarifa base
            TextFormField(
              controller: _baseRateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tarifa Base por Hora',
                prefixText: '\$ ',
                prefixIcon: Icon(Icons.attach_money),
                hintText: '25.00',
              ),
              validator: Validators.validatePrice,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),

            // Biografía
            TextFormField(
              controller: _bioController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Descripción / Biografía',
                hintText: 'Cuéntanos sobre tu experiencia y servicios...',
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
            const SizedBox(height: 32),

            // Ubicación
            Text(
              'Ubicación y Cobertura',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Dirección
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Dirección Base',
                prefixIcon: const Icon(Icons.location_on_outlined),
                suffixIcon: _isGettingLocation
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.my_location),
                        onPressed: _isLoading ? null : _getCurrentLocation,
                        tooltip: 'Obtener ubicación actual',
                      ),
              ),
              validator: (value) =>
                  Validators.validateRequired(value, 'Dirección'),
              enabled: !_isLoading,
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Zonas de cobertura
            InkWell(
              onTap: _isLoading ? null : _showZonesSelector,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Zonas de Cobertura',
                  prefixIcon: Icon(Icons.map_outlined),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                child: _selectedZones.isEmpty
                    ? const Text(
                        'Selecciona las zonas donde ofreces servicio',
                        style: TextStyle(color: Colors.grey),
                      )
                    : Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: _selectedZones
                            .map((z) => Chip(
                                  label: Text(z, style: const TextStyle(fontSize: 12)),
                                  visualDensity: VisualDensity.compact,
                                ))
                            .toList(),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Información de ubicación
            if (_currentPosition != null)
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ubicación GPS guardada',
                          style: TextStyle(color: Colors.green[900]),
                        ),
                      ),
                    ],
                  ),
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