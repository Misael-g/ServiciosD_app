import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/config/supabase_config.dart';
import '../../core/theme/app_theme.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  bool _isLoading = false;
  String? _verificationStatus;
  String? _verificationNotes;
  
  // Documentos
  File? _idFrontImage;
  File? _idBackImage;
  File? _certificateImage;
  
  // URLs de documentos ya subidos
  String? _idFrontUrl;
  String? _idBackUrl;
  String? _certificateUrl;
  
  bool _isUploading = false;
  String _uploadingDoc = '';

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  // ============================================
  // CARGAR ESTADO DE VERIFICACIÓN
  // ============================================
  Future<void> _loadVerificationStatus() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw Exception('No hay usuario autenticado');
      }

      // Obtener estado de verificación del perfil
      final profileResponse = await SupabaseConfig.client
          .from('profiles')
          .select('verification_status, verification_notes')
          .eq('id', userId)
          .single();

      setState(() {
        _verificationStatus = profileResponse['verification_status'] as String?;
        _verificationNotes = profileResponse['verification_notes'] as String?;
      });

      print('✅ Estado de verificación: $_verificationStatus');

      // Cargar documentos ya subidos
      await _loadExistingDocuments(userId);
      
    } catch (e) {
      print('❌ Error cargando estado: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar estado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ============================================
  // CARGAR DOCUMENTOS EXISTENTES
  // ============================================
  Future<void> _loadExistingDocuments(String userId) async {
    try {
      final docsResponse = await SupabaseConfig.client
          .from('verification_documents')
          .select('document_type, file_url')
          .eq('technician_id', userId);

      for (var doc in docsResponse) {
        final type = doc['document_type'] as String;
        final url = doc['file_url'] as String;

        if (type == 'id_front') {
          setState(() => _idFrontUrl = url);
        } else if (type == 'id_back') {
          setState(() => _idBackUrl = url);
        } else if (type == 'certificate') {
          setState(() => _certificateUrl = url);
        }
      }

      print('✅ Documentos cargados: ${docsResponse.length}');
    } catch (e) {
      print('⚠️ No hay documentos previos: $e');
    }
  }

  // ============================================
  // SELECCIONAR IMAGEN
  // ============================================
  Future<void> _pickImage(String documentType) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        
        setState(() {
          if (documentType == 'id_front') {
            _idFrontImage = file;
          } else if (documentType == 'id_back') {
            _idBackImage = file;
          } else if (documentType == 'certificate') {
            _certificateImage = file;
          }
        });

        print('✅ Imagen seleccionada: $documentType');
      }
    } catch (e) {
      print('❌ Error seleccionando imagen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================
  // SUBIR DOCUMENTO
  // ============================================
  Future<void> _uploadDocument(String documentType, File file) async {
    setState(() {
      _isUploading = true;
      _uploadingDoc = documentType;
    });

    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw Exception('No hay usuario autenticado');
      }

      print('📤 Subiendo documento: $documentType');

      // 1. Subir archivo a Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$userId/${documentType}_$timestamp.jpg';

      await SupabaseConfig.client.storage
          .from('verification-docs')
          .upload(
            fileName,
            file,
          );

      print('✅ Archivo subido a Storage');

      // 2. Obtener URL pública (con signed URL porque es privado)
      final fileUrl = await SupabaseConfig.client.storage
          .from('verification-docs')
          .createSignedUrl(fileName, 31536000); // 1 año

      print('✅ URL obtenida: $fileUrl');

      // 3. Guardar en tabla verification_documents
      await SupabaseConfig.client
          .from('verification_documents')
          .upsert({
            'technician_id': userId,
            'document_type': documentType,
            'file_url': fileUrl,
            'uploaded_at': DateTime.now().toIso8601String(),
          }, onConflict: 'technician_id,document_type');

      print('✅ Documento guardado en BD');

      // 4. Actualizar estado local
      setState(() {
        if (documentType == 'id_front') {
          _idFrontUrl = fileUrl;
          _idFrontImage = null;
        } else if (documentType == 'id_back') {
          _idBackUrl = fileUrl;
          _idBackImage = null;
        } else if (documentType == 'certificate') {
          _certificateUrl = fileUrl;
          _certificateImage = null;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Documento subido correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error subiendo documento: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
        _uploadingDoc = '';
      });
    }
  }

  // ============================================
  // ENVIAR TODOS LOS DOCUMENTOS
  // ============================================
  Future<void> _submitVerification() async {
    // Validar que todos los documentos estén subidos
    if (_idFrontUrl == null && _idFrontImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Debes subir la cédula frontal'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_idBackUrl == null && _idBackImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Debes subir la cédula trasera'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_certificateUrl == null && _certificateImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Debes subir el certificado'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Subir documentos pendientes
      if (_idFrontImage != null) {
        await _uploadDocument('id_front', _idFrontImage!);
      }
      
      if (_idBackImage != null) {
        await _uploadDocument('id_back', _idBackImage!);
      }
      
      if (_certificateImage != null) {
        await _uploadDocument('certificate', _certificateImage!);
      }

      // Actualizar estado de verificación a pending
      final userId = SupabaseConfig.currentUserId;
      if (userId != null) {
        await SupabaseConfig.client
            .from('profiles')
            .update({'verification_status': 'pending'})
            .eq('id', userId);

        setState(() => _verificationStatus = 'pending');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Documentos enviados para verificación'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error enviando verificación: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación de Cuenta'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading && _verificationStatus == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Estado de verificación
                  _buildStatusCard(),
                  const SizedBox(height: 24),

                  // Instrucciones
                  _buildInstructionsCard(),
                  const SizedBox(height: 24),

                  // Documentos
                  _buildDocumentSection(
                    title: '1. Cédula Frontal',
                    documentType: 'id_front',
                    selectedImage: _idFrontImage,
                    uploadedUrl: _idFrontUrl,
                  ),
                  const SizedBox(height: 16),

                  _buildDocumentSection(
                    title: '2. Cédula Trasera',
                    documentType: 'id_back',
                    selectedImage: _idBackImage,
                    uploadedUrl: _idBackUrl,
                  ),
                  const SizedBox(height: 16),

                  _buildDocumentSection(
                    title: '3. Certificado Profesional',
                    documentType: 'certificate',
                    selectedImage: _certificateImage,
                    uploadedUrl: _certificateUrl,
                  ),
                  const SizedBox(height: 32),

                  // Botón enviar
                  if (_verificationStatus == null || _verificationStatus == 'rejected')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submitVerification,
                        icon: const Icon(Icons.send),
                        label: const Text('Enviar Documentos'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),

                  // Notas de rechazo
                  if (_verificationStatus == 'rejected' && _verificationNotes != null) ...[
                    const SizedBox(height: 16),
                    _buildRejectionNotes(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String statusDescription;

    switch (_verificationStatus) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Verificado ✅';
        statusDescription = 'Tu cuenta ha sido verificada exitosamente';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'En Revisión ⏳';
        statusDescription = 'Tus documentos están siendo revisados por un administrador';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rechazado ❌';
        statusDescription = 'Tu solicitud fue rechazada. Revisa las notas y vuelve a enviar';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info_outline;
        statusText = 'No Verificado';
        statusDescription = 'Sube tus documentos para empezar el proceso de verificación';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(statusIcon, size: 60, color: statusColor),
          const SizedBox(height: 12),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: statusColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'Instrucciones',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstructionItem('📸 Toma fotos claras de tus documentos'),
          _buildInstructionItem('✅ Asegúrate de que el texto sea legible'),
          _buildInstructionItem('💡 Evita reflejos y sombras'),
          _buildInstructionItem('📄 Formatos aceptados: JPG, PNG'),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentSection({
    required String title,
    required String documentType,
    File? selectedImage,
    String? uploadedUrl,
  }) {
    final hasImage = selectedImage != null || uploadedUrl != null;
    final isUploading = _isUploading && _uploadingDoc == documentType;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasImage ? Colors.green : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasImage ? Icons.check_circle : Icons.upload_file,
                color: hasImage ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (hasImage)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Listo',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Preview de imagen
          if (selectedImage != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    selectedImage,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                if (!isUploading)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          if (documentType == 'id_front') _idFrontImage = null;
                          if (documentType == 'id_back') _idBackImage = null;
                          if (documentType == 'certificate') _certificateImage = null;
                        });
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                    ),
                  ),
              ],
            )
          else if (uploadedUrl != null)
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 60, color: Colors.green),
                    SizedBox(height: 12),
                    Text(
                      'Documento Subido',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.shade300,
                  style: BorderStyle.solid,
                  width: 2,
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined, size: 60, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'No hay imagen seleccionada',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Botones
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(documentType),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Seleccionar'),
                ),
              ),
              if (selectedImage != null && !isUploading) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _uploadDocument(documentType, selectedImage),
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Subir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),

          if (isUploading)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildRejectionNotes() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Razón del Rechazo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _verificationNotes!,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}