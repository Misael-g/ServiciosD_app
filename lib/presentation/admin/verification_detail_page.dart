import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/datasources/profiles_remote_ds.dart';
import '../../data/datasources/storage_remote_ds.dart';
import '../../data/models/profile_model.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/constants/verification_states.dart';

/// Pantalla de detalle de verificación (Admin)
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
      // Cargar perfil del técnico
      final technician = await _profilesDS.getProfileById(widget.technicianId);

      // Cargar URLs de documentos
      final documentUrls = <String, String?>{};
      for (final docType in VerificationStates.documentTypes) {
        try {
          final url = await _storageDS.getVerificationDocumentUrl(
            widget.technicianId,
            docType,
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
        'approved',
        _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          'Técnico verificado exitosamente',
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
        'rejected',
        _notesController.text.trim(),
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
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          backgroundColor: Colors.black,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación de Técnico'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Información del técnico
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          backgroundImage: _technician?.profilePictureUrl != null
                              ? NetworkImage(_technician!.profilePictureUrl!)
                              : null,
                          child: _technician?.profilePictureUrl == null
                              ? Text(
                                  _technician?.fullName[0].toUpperCase() ?? '?',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _technician?.fullName ?? '',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _technician?.email ?? '',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        if (_technician?.phone != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _technician!.phone!,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (_technician?.specialties != null &&
                            _technician!.specialties!.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _technician!.specialties!
                                .map((specialty) => Chip(
                                      label: Text(specialty),
                                      avatar: const Icon(Icons.work, size: 16),
                                    ))
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Documentos
                Text(
                  'Documentos de Verificación',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                // ID Front
                _buildDocumentCard(
                  'Cédula (Frontal)',
                  'id_front',
                  _documentUrls['id_front'],
                ),
                const SizedBox(height: 12),

                // ID Back
                _buildDocumentCard(
                  'Cédula (Reverso)',
                  'id_back',
                  _documentUrls['id_back'],
                ),
                const SizedBox(height: 12),

                // Certificate
                _buildDocumentCard(
                  'Certificado Profesional',
                  'certificate',
                  _documentUrls['certificate'],
                ),
                const SizedBox(height: 24),

                // Notas
                TextField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    hintText: 'Agregar comentarios sobre la verificación...',
                    border: OutlineInputBorder(),
                  ),
                  enabled: !_isProcessing,
                ),
                const SizedBox(height: 24),

                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing ? null : _rejectVerification,
                        icon: const Icon(Icons.close),
                        label: const Text('Rechazar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _approveVerification,
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.check),
                        label: const Text('Aprobar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
    return Card(
      child: InkWell(
        onTap: url != null ? () => _viewImageFullscreen(url) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (url != null)
                    const Icon(Icons.visibility, color: Colors.blue),
                ],
              ),
              const SizedBox(height: 12),
              if (url != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.error, color: Colors.red),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.file_present, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'Documento no disponible',
                          style: TextStyle(color: Colors.grey[600]),
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
}