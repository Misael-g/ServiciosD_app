import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/verification_states.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/datasources/storage_remote_ds.dart';
import '../../data/datasources/profiles_remote_ds.dart';
import '../../core/config/supabase_config.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final StorageRemoteDataSource _storageDataSource = StorageRemoteDataSource();
  final ProfilesRemoteDataSource _profilesDataSource = ProfilesRemoteDataSource();
  final ImagePicker _imagePicker = ImagePicker();

  Map<String, File?> _selectedFiles = {
    DocumentTypes.idFront: null,
    DocumentTypes.idBack: null,
    DocumentTypes.certificate: null,
  };

  Map<String, String?> _uploadedUrls = {
    DocumentTypes.idFront: null,
    DocumentTypes.idBack: null,
    DocumentTypes.certificate: null,
  };

  bool _isUploading = false;
  String? _verificationStatus;
  String? _verificationNotes;

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
    _loadUploadedDocuments();
  }

  Future<void> _loadVerificationStatus() async {
    try {
      final profile = await _profilesDataSource.getCurrentUserProfile();
      setState(() {
        _verificationStatus = profile.verificationStatus;
        _verificationNotes = profile.verificationNotes;
      });
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error al cargar estado: $e');
      }
    }
  }

  Future<void> _loadUploadedDocuments() async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return;

    try {
      final uploadedTypes = await _storageDataSource.getUploadedDocumentTypes(userId);
      
      setState(() {
        for (var type in uploadedTypes) {
          _uploadedUrls[type] = 'uploaded'; // Marcador de que existe
        }
      });
    } catch (e) {
      // Silenciosamente fallar
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
          _selectedFiles[documentType] = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error al seleccionar archivo: $e');
      }
    }
  }

  Future<void> _takePhoto(String documentType) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedFiles[documentType] = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error al tomar foto: $e');
      }
    }
  }

  Future<void> _uploadDocuments() async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) {
      SnackbarHelper.showError(context, 'No hay usuario autenticado');
      return;
    }

    // Verificar que se hayan seleccionado los 3 documentos
    if (_selectedFiles.values.any((file) => file == null) &&
        _uploadedUrls.values.any((url) => url == null)) {
      SnackbarHelper.showError(
        context,
        'Debes subir los 3 documentos requeridos',
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Subir cada documento
      for (var entry in _selectedFiles.entries) {
        final documentType = entry.key;
        final file = entry.value;

        // Solo subir si hay archivo nuevo seleccionado
        if (file != null) {
          SnackbarHelper.showLoading(
            context,
            'Subiendo ${DocumentTypes.getDisplayName(documentType)}...',
          );

          final url = await _storageDataSource.uploadVerificationDocument(
            technicianId: userId,
            documentType: documentType,
            file: file,
          );

          setState(() {
            _uploadedUrls[documentType] = url;
            _selectedFiles[documentType] = null; // Limpiar archivo seleccionado
          });
        }
      }

      // Actualizar registro en la tabla verification_documents
      // Esto se hace a nivel de base de datos con el trigger

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          '¡Documentos subidos! Tu perfil será revisado pronto.',
        );
        _loadVerificationStatus();
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'Error al subir documentos: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showDocumentOptions(String documentType) {
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
                _pickDocument(documentType);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar Foto'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto(documentType);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación de Técnico'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Estado de verificación
            _buildVerificationStatusCard(),
            const SizedBox(height: 24),

            // Instrucciones
            _buildInstructionsCard(),
            const SizedBox(height: 24),

            // Documentos requeridos
            Text(
              'Documentos Requeridos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Documento 1: Cédula Frontal
            _buildDocumentCard(DocumentTypes.idFront),
            const SizedBox(height: 16),

            // Documento 2: Cédula Posterior
            _buildDocumentCard(DocumentTypes.idBack),
            const SizedBox(height: 16),

            // Documento 3: Certificado
            _buildDocumentCard(DocumentTypes.certificate),
            const SizedBox(height: 24),

            // Botón de subir
            if (_verificationStatus != VerificationStates.approved)
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadDocuments,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Enviar Documentos'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationStatusCard() {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (_verificationStatus) {
      case VerificationStates.approved:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = '¡Verificado!';
        break;
      case VerificationStates.rejected:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rechazado';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Pendiente de Verificación';
    }

    return Card(
      color: statusColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (_verificationNotes != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _verificationNotes!,
                  style: TextStyle(color: Colors.grey[800]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Instrucciones',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• Asegúrate de que las fotos sean claras y legibles\n'
              '• La cédula debe estar vigente\n'
              '• El certificado debe ser oficial\n'
              '• Los documentos serán revisados por un administrador',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(String documentType) {
    final file = _selectedFiles[documentType];
    final isUploaded = _uploadedUrls[documentType] != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isUploaded ? Icons.check_circle : Icons.upload_file,
                  color: isUploaded ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    DocumentTypes.getDisplayName(documentType),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Vista previa si hay archivo seleccionado
            if (file != null)
              Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(file),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Botón de seleccionar
            OutlinedButton.icon(
              onPressed: () => _showDocumentOptions(documentType),
              icon: Icon(file == null ? Icons.add_photo_alternate : Icons.edit),
              label: Text(file == null
                  ? (isUploaded ? 'Cambiar Documento' : 'Seleccionar Documento')
                  : 'Cambiar Selección'),
            ),
          ],
        ),
      ),
    );
  }
}