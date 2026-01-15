import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/location_helper.dart';
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

class _CreateRequestPageState extends State<CreateRequestPage> {
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
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
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
      List<String>? imageUrls;
      if (_selectedImages.isNotEmpty) {
        SnackbarHelper.showLoading(context, 'Subiendo imágenes...');
        
        imageUrls = [];
        for (final image in _selectedImages) {
          final url = await _storageDataSource.uploadServiceImage(
            serviceRequestId: request.id,
            file: image,
          );
          imageUrls.add(url);
        }

        // Actualizar la solicitud con las URLs de las imágenes
        // Esto requeriría un método update en el datasource
        // Por ahora, las imágenes se subirán pero no se asociarán automáticamente
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Solicitud'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Título
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título',
                hintText: 'Ej: Reparación de enchufe',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) => Validators.validateRequired(value, 'Título'),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),

            // Tipo de servicio
            DropdownButtonFormField<String>(
              value: _selectedService,
              decoration: const InputDecoration(
                labelText: 'Tipo de Servicio',
                prefixIcon: Icon(Icons.work_outline),
              ),
              items: _services.map((service) {
                return DropdownMenuItem(
                  value: service,
                  child: Text(service),
                );
              }).toList(),
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() {
                        _selectedService = value;
                      });
                    },
              validator: (value) {
                if (value == null) {
                  return 'Selecciona un tipo de servicio';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Descripción
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción del Problema',
                hintText: 'Describe detalladamente el problema...',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: (value) => Validators.validateDescription(value),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),

            // Ubicación
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Dirección',
                hintText: 'Ingresa tu dirección',
                prefixIcon: const Icon(Icons.location_on),
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
              validator: (value) => Validators.validateRequired(value, 'Dirección'),
              enabled: !_isLoading,
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
                          'Ubicación obtenida correctamente',
                          style: TextStyle(color: Colors.green[900]),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Esperando ubicación GPS...',
                          style: TextStyle(color: Colors.orange[900]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 24),

            // Sección de fotos
            Text(
              'Fotos (Opcional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega fotos del problema para que los técnicos puedan verlo',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Grid de imágenes
            if (_selectedImages.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
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
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

            const SizedBox(height: 16),

            // Botones para agregar fotos
            if (_selectedImages.length < 5)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _pickImages,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galería'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Cámara'),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 32),

            // Botón de crear
            ElevatedButton(
              onPressed: _isLoading ? null : _createRequest,
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
                  : const Text('Crear Solicitud'),
            ),
          ],
        ),
      ),
    );
  }
}