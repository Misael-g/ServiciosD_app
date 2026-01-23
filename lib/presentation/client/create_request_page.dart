import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/location_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_widgets.dart';
import '../../data/datasources/service_requests_remote_ds.dart';
import '../../data/datasources/storage_remote_ds.dart';

/// Pantalla para crear una nueva solicitud de servicio
class CreateRequestPage extends StatefulWidget {
  final String? preselectedService;

  const CreateRequestPage({
    super.key,
    this.preselectedService,
  });

  @override
  State<CreateRequestPage> createState() => _CreateRequestPageState();
}

class _CreateRequestPageState extends State<CreateRequestPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  final ServiceRequestsRemoteDataSource _serviceRequestsDataSource =
      ServiceRequestsRemoteDataSource();
  final StorageRemoteDataSource _storageDataSource = StorageRemoteDataSource();
  final ImagePicker _imagePicker = ImagePicker();

  String? _selectedService;
  Position? _currentPosition;
  List<File> _selectedImages = [];
  bool _isLoading = false;
  bool _isGettingLocation = false;
  int _currentStep = 0;
  late AnimationController _animationController;

  final List<String> _services = [
    'Electricista',
    'Plomero',
    'Carpintero',
    'Pintor',
    'Mecánico',
    'Jardinero',
    'Limpieza',
    'Reparación de Electrodomésticos',
    'Instalación de TV/Internet',
    'Otros',
  ];

  @override
  void initState() {
    super.initState();
    _selectedService = widget.preselectedService;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animationController.forward();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      final position = await LocationHelper.getCurrentLocation();
      
      if (position != null) {
        setState(() => _currentPosition = position);

        // Obtener dirección desde coordenadas
        try {
          final placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );

          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            final address = '${place.street}, ${place.locality}, ${place.country}';
            _addressController.text = address;
          }
        } catch (e) {
          // Si falla geocoding, dejar que el usuario ingrese manualmente
        }
      } else {
        if (mounted) {
          SnackbarHelper.showError(
            context,
            'No se pudo obtener la ubicación. Verifica los permisos.',
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

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((img) => File(img.path)));
          
          // Limitar a 5 imágenes
          if (_selectedImages.length > 5) {
            _selectedImages = _selectedImages.take(5).toList();
            SnackbarHelper.showInfo(context, 'Máximo 5 imágenes permitidas');
          }
        });
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Error al seleccionar imágenes');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
          
          if (_selectedImages.length > 5) {
            _selectedImages = _selectedImages.take(5).toList();
            SnackbarHelper.showInfo(context, 'Máximo 5 imágenes permitidas');
          }
        });
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Error al tomar foto');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _createRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedService == null) {
      SnackbarHelper.showError(context, 'Selecciona un tipo de servicio');
      return;
    }

    if (_currentPosition == null) {
      SnackbarHelper.showError(
        context,
        'No se ha obtenido tu ubicación. Por favor, espera o activa el GPS.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Crear la solicitud primero
      final request = await _serviceRequestsDataSource.createServiceRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        serviceType: _selectedService!,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        address: _addressController.text.trim(),
      );

      // Subir imágenes si hay
      if (_selectedImages.isNotEmpty) {
        try {
          print('📤 [CREATE_REQUEST] Subiendo ${_selectedImages.length} imágenes...');
          
          final imageUrls = <String>[];
          
          for (int i = 0; i < _selectedImages.length; i++) {
            final image = _selectedImages[i];
            
            print('   Subiendo imagen ${i + 1}/${_selectedImages.length}...');
            
            final url = await _storageDataSource.uploadServiceImage(
              serviceRequestId: request.id,
              file: image,
            );
            
            imageUrls.add(url);
            print('   ✅ Imagen ${i + 1} subida: $url');
          }

          // ✅ ACTUALIZAR LA SOLICITUD CON LAS URLs
          print('📤 [CREATE_REQUEST] Actualizando solicitud con URLs de imágenes...');
          
          await _serviceRequestsDataSource.updateServiceRequestImages(
            request.id,
            imageUrls,
          );
          
          print('✅ [CREATE_REQUEST] Imágenes guardadas en BD: ${imageUrls.length}');
          
        } catch (e) {
          print('❌ [CREATE_REQUEST] Error al subir imágenes: $e');
          // Continuar aunque falle subir imágenes
        }
      }

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          '¡Solicitud creada! Los técnicos cercanos serán notificados.',
        );
        Navigator.pop(context, true); // Retornar true para indicar éxito
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'Error al crear solicitud: ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _nextStep() {
    if (_currentStep == 0 && _selectedService == null) {
      SnackbarHelper.showError(context, 'Selecciona un servicio');
      return;
    }

    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _animationController.forward(from: 0);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _animationController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nueva Solicitud'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Indicador de progreso
            _buildProgressIndicator(),

            // Contenido
            Expanded(
              child: FadeTransition(
                opacity: _animationController,
                child: _buildStepContent(),
              ),
            ),

            // Botones de navegación
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildProgressStep(0, 'Servicio', Icons.build_circle_rounded),
          _buildProgressConnector(0),
          _buildProgressStep(1, 'Detalles', Icons.description_rounded),
          _buildProgressConnector(1),
          _buildProgressStep(2, 'Ubicación', Icons.location_on_rounded),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String label, IconData icon) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Expanded(
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: isActive || isCompleted
                  ? LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primaryDark,
                      ],
                    )
                  : null,
              color: isActive || isCompleted ? null : AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive || isCompleted
                    ? AppColors.primary
                    : AppColors.border,
                width: 2,
              ),
            ),
            child: Icon(
              isCompleted ? Icons.check_rounded : icon,
              color: isActive || isCompleted
                  ? AppColors.white
                  : AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressConnector(int step) {
    final isCompleted = _currentStep > step;

    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 30),
        decoration: BoxDecoration(
          gradient: isCompleted
              ? LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primaryDark,
                  ],
                )
              : null,
          color: isCompleted ? null : AppColors.border,
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildServiceSelection();
      case 1:
        return _buildDetailsForm();
      case 2:
        return _buildLocationAndPhotos();
      default:
        return const SizedBox();
    }
  }

  Widget _buildServiceSelection() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(
          title: '¿Qué servicio necesitas?',
          subtitle: 'Selecciona el tipo de servicio',
          icon: Icons.home_repair_service_rounded,
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: _services.length,
          itemBuilder: (context, index) {
            final service = _services[index];
            final isSelected = _selectedService == service;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedService = service;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary,
                            AppColors.primaryDark,
                          ],
                        )
                      : null,
                  color: isSelected ? null : AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected ? AppShadows.medium : AppShadows.small,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getServiceIcon(service),
                      size: 40,
                      color: isSelected
                          ? AppColors.white
                          : AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      service,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.white
                            : AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  IconData _getServiceIcon(String service) {
    switch (service) {
      case 'Electricista':
        return Icons.electrical_services_rounded;
      case 'Plomero':
        return Icons.plumbing_rounded;
      case 'Carpintero':
        return Icons.carpenter_rounded;
      case 'Pintor':
        return Icons.format_paint_rounded;
      case 'Mecánico':
        return Icons.build_circle_rounded;
      case 'Jardinero':
        return Icons.grass_rounded;
      case 'Limpieza':
        return Icons.cleaning_services_rounded;
      case 'Reparación de Electrodomésticos':
        return Icons.kitchen_rounded;
      case 'Instalación de TV/Internet':
        return Icons.router_rounded;
      default:
        return Icons.more_horiz_rounded;
    }
  }

  Widget _buildDetailsForm() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(
          title: 'Describe tu problema',
          subtitle: 'Cuéntanos qué necesitas',
          icon: Icons.edit_note_rounded,
        ),
        const SizedBox(height: 24),

        // Título
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Título de la solicitud',
              hintText: 'Ej: Reparación de enchufe',
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.title_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
            validator: (value) => Validators.validateRequired(value, 'Título'),
            textCapitalization: TextCapitalization.sentences,
          ),
        ),

        const SizedBox(height: 16),

        // Descripción
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Descripción del problema',
              hintText: 'Describe detalladamente qué necesitas...',
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
              alignLabelWithHint: true,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
            maxLines: 6,
            validator: Validators.validateDescription,
            textCapitalization: TextCapitalization.sentences,
          ),
        ),

        const SizedBox(height: 24),

        // Consejo
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.info.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.tips_and_updates_rounded,
                  color: AppColors.info,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Sé específico para recibir mejores cotizaciones',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.info,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationAndPhotos() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(
          title: 'Ubicación y fotos',
          subtitle: 'Última información',
          icon: Icons.place_rounded,
        ),
        const SizedBox(height: 24),

        // Ubicación
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Dirección',
              hintText: 'Ingresa tu dirección',
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.warning,
                  size: 20,
                ),
              ),
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
                      icon: const Icon(Icons.my_location_rounded),
                      onPressed: _getCurrentLocation,
                      tooltip: 'Obtener ubicación actual',
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
            validator: (value) => Validators.validateRequired(value, 'Dirección'),
          ),
        ),

        const SizedBox(height: 16),

        // Estado de ubicación
        if (_currentPosition != null)
          InfoCard(
            message: '✅ Ubicación obtenida correctamente',
            icon: Icons.check_circle_rounded,
            color: AppColors.success,
          )
        else
          InfoCard(
            message: '⏳ Obteniendo ubicación GPS...',
            icon: Icons.gps_fixed_rounded,
            color: AppColors.warning,
          ),

        const SizedBox(height: 32),

        // Fotos
        const SectionHeader(
          title: 'Fotos del problema',
          subtitle: 'Opcional - Máximo 5 fotos',
          icon: Icons.photo_camera_rounded,
        ),
        const SizedBox(height: 16),

        // Grid de imágenes
        if (_selectedImages.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      _selectedImages[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

        if (_selectedImages.isNotEmpty)
          const SizedBox(height: 16),

        // Botones para agregar fotos
        if (_selectedImages.length < 5)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.photo_library_rounded),
                  label: const Text('Galería'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.primary),
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('Cámara'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.success),
                    foregroundColor: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
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
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Atrás'),
                ),
              ),
            if (_currentStep > 0)
              const SizedBox(width: 16),
            Expanded(
              flex: _currentStep == 0 ? 1 : 2,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : (_currentStep == 2 ? _createRequest : _nextStep),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.white,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentStep == 2 ? 'Crear Solicitud' : 'Siguiente',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentStep == 2
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                            size: 20,
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