import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../data/datasources/service_requests_remote_ds.dart';
import '../../data/datasources/profiles_remote_ds.dart';
import '../../data/datasources/quotations_remote_ds.dart';
import '../../data/models/service_request_model.dart';
import '../../data/models/profile_model.dart';
import '../../data/models/quotation_model.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/config/supabase_config.dart';
import 'send_quotation_page.dart';

/// Pantalla de detalle de solicitud para técnico
/// ✅ ACTUALIZADA: Botón para completar trabajo cuando cotización aceptada
class TechnicianRequestDetailPage extends StatefulWidget {
  final String requestId;

  const TechnicianRequestDetailPage({
    super.key,
    required this.requestId,
  });

  @override
  State<TechnicianRequestDetailPage> createState() =>
      _TechnicianRequestDetailPageState();
}

class _TechnicianRequestDetailPageState
    extends State<TechnicianRequestDetailPage> {
  final ServiceRequestsRemoteDataSource _requestsDS =
      ServiceRequestsRemoteDataSource();
  final ProfilesRemoteDataSource _profilesDS = ProfilesRemoteDataSource();
  final QuotationsRemoteDataSource _quotationsDS =
      QuotationsRemoteDataSource();

  ServiceRequestModel? _request;
  ProfileModel? _clientProfile;
  ProfileModel? _technicianProfile;
  QuotationModel? _myQuotation;
  bool _isLoading = true;
  bool _hasQuotation = false;
  double? _distanceKm;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      print('🔵 [REQUEST_DETAIL] Cargando solicitud: ${widget.requestId}');

      // 1. Cargar solicitud
      final request = await _requestsDS.getServiceRequestById(widget.requestId);

      print('✅ [REQUEST_DETAIL] Solicitud cargada');
      print('   Título: ${request.title}');
      print('   Cliente ID: ${request.clientId}');
      print('   Estado: ${request.status}');
      print('   Ubicación: lat=${request.latitude}, lng=${request.longitude}');

      // 2. Verificar si ya envié cotización
      final myQuotation = await _quotationsDS.getMyQuotationForRequest(widget.requestId);
      final hasQuotation = myQuotation != null;

      if (hasQuotation) {
        print('⚠️ [REQUEST_DETAIL] Ya existe cotización');
        print('   Estado cotización: ${myQuotation!.status}');
      } else {
        print('✅ [REQUEST_DETAIL] No hay cotización previa');
      }

      // 3. Cargar perfil del cliente
      final clientProfile = await _profilesDS.getProfileById(request.clientId);

      print('✅ [REQUEST_DETAIL] Cliente cargado: ${clientProfile.fullName}');

      // 4. Cargar perfil del técnico (para calcular distancia)
      final technicianId = SupabaseConfig.currentUserId;
      ProfileModel? techProfile;
      if (technicianId != null) {
        techProfile = await _profilesDS.getProfileById(technicianId);
        print('✅ [REQUEST_DETAIL] Técnico cargado: ${techProfile.fullName}');
        print('   Ubicación técnico: lat=${techProfile.latitude}, lng=${techProfile.longitude}');

        // 5. Calcular distancia
        if (techProfile.latitude != null &&
            techProfile.longitude != null &&
            request.latitude != null &&
            request.longitude != null) {
          final distance = Geolocator.distanceBetween(
            techProfile.latitude!,
            techProfile.longitude!,
            request.latitude!,
            request.longitude!,
          );
          _distanceKm = distance / 1000;
          print('📍 [REQUEST_DETAIL] Distancia calculada: ${_distanceKm!.toStringAsFixed(2)}km');
        }
      }

      setState(() {
        _request = request;
        _clientProfile = clientProfile;
        _technicianProfile = techProfile;
        _myQuotation = myQuotation;
        _hasQuotation = hasQuotation;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [REQUEST_DETAIL] Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(context, 'Error al cargar solicitud');
      }
    }
  }

  void _navigateToSendQuotation() {
    if (_request == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SendQuotationPage(
          serviceRequest: _request!,
        ),
      ),
    ).then((sent) {
      if (sent == true && mounted) {
        // Regresar a la pantalla anterior
        Navigator.pop(context, true);
      }
    });
  }

  /// ✅ NUEVA FUNCIÓN: Completar trabajo
  Future<void> _completeWork() async {
    if (_request == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Completar Trabajo'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Confirmas que has completado este trabajo?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Al marcar como completado:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('• El cliente será notificado'),
                  const Text('• Podrá verificar el trabajo'),
                  const Text('• Podrá dejar una reseña'),
                  const Text('• Se incrementarán tus trabajos completados'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_money, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Precio acordado: \$${_myQuotation?.estimatedPrice.toStringAsFixed(2) ?? "0.00"}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check),
            label: const Text('Sí, Completar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      print('📤 [REQUEST_DETAIL] Completando trabajo: ${_request!.id}');

      // ✅ Usar la función RPC que ya existe en Supabase
      await _requestsDS.completeService(_request!.id);

      print('✅ [REQUEST_DETAIL] Trabajo marcado como completado');

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          '¡Trabajo completado! El cliente puede dejar una reseña',
        );
        
        // Recargar datos para actualizar UI
        await _loadData();
      }
    } catch (e) {
      print('❌ [REQUEST_DETAIL] Error al completar: $e');
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'Error al completar trabajo: ${e.toString().replaceAll("Exception: ", "")}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Solicitud'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _request == null
              ? const Center(child: Text('No se encontró la solicitud'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Título y descripción
                          _buildTitleSection(),
                          const SizedBox(height: 16),

                          // Info del cliente
                          _buildClientSection(),
                          const SizedBox(height: 16),

                          // Galería de fotos
                          if (_request!.images != null &&
                              _request!.images!.isNotEmpty)
                            _buildPhotosSection(),
                          const SizedBox(height: 16),

                          // Mapa con ubicación
                          _buildMapSection(),
                          const SizedBox(height: 16),

                          // Distancia
                          if (_distanceKm != null) _buildDistanceSection(),
                        ],
                      ),
                    ),

                    // Botón de acción
                    _buildActionButton(),
                  ],
                ),
    );
  }

  Widget _buildTitleSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _request!.serviceType,
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _request!.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _request!.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Creado: ${_formatDate(_request!.createdAt)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientSection() {
    if (_clientProfile == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cliente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue,
                  backgroundImage: _clientProfile!.profilePictureUrl != null
                      ? NetworkImage(_clientProfile!.profilePictureUrl!)
                      : null,
                  child: _clientProfile!.profilePictureUrl == null
                      ? Text(
                          _clientProfile!.fullName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _clientProfile!.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_clientProfile!.phone != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              _clientProfile!.phone!,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.phone, color: Colors.green),
                  onPressed: () {
                    // TODO: Implementar llamada
                  },
                  tooltip: 'Llamar',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fotos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _request!.images!.length,
                itemBuilder: (context, index) {
                  final imageUrl = _request!.images![index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _showFullImage(imageUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 120,
                              height: 120,
                              color: Colors.grey[300],
                              child: const Icon(Icons.error),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    if (_request!.latitude == null || _request!.longitude == null) {
      return const SizedBox.shrink();
    }

    final requestLocation = LatLng(_request!.latitude!, _request!.longitude!);
    LatLng? technicianLocation;
    if (_technicianProfile?.latitude != null &&
        _technicianProfile?.longitude != null) {
      technicianLocation = LatLng(
        _technicianProfile!.latitude!,
        _technicianProfile!.longitude!,
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Ubicación',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_request!.address != null)
                  Expanded(
                    flex: 2,
                    child: Text(
                      _request!.address!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 250,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: requestLocation,
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.servicios_app',
                ),
                MarkerLayer(
                  markers: [
                    // Marcador de la solicitud (rojo)
                    Marker(
                      point: requestLocation,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                    // Marcador del técnico (azul)
                    if (technicianLocation != null)
                      Marker(
                        point: technicianLocation,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 40,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceSection() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.straighten, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Text(
              'Distancia: ${_distanceKm!.toStringAsFixed(2)} km',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    // ✅ Verificar si puede completar el trabajo
    final canComplete = _hasQuotation && 
                       _myQuotation?.status == 'accepted' && 
                       (_request!.status == 'quotation_accepted' || _request!.status == 'in_progress') &&
                       _request!.status != 'completed' &&
                       _request!.status != 'rated';

    final isCompleted = _request!.status == 'completed' || _request!.status == 'rated';

    // Si ya envió cotización
    if (_hasQuotation && _myQuotation != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Estado de la cotización
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getQuotationStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getQuotationStatusColor(),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getQuotationStatusIcon(),
                      color: _getQuotationStatusColor(),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getQuotationStatusText(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _getQuotationStatusColor(),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Precio: \$${_myQuotation!.estimatedPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ BOTÓN DE COMPLETAR - Solo si puede completar
              if (canComplete) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _completeWork,
                    icon: const Icon(Icons.check_circle, size: 28),
                    label: const Text(
                      'Marcar como Completado',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
              ],

              // Mensaje si ya está completado
              if (isCompleted) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.done_all, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '✅ Trabajo completado. Esperando reseña del cliente.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Botón para ver mis cotizaciones
              if (!isCompleted) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Volver
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Si no ha enviado cotización, mostrar botón normal
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: _navigateToSendQuotation,
          icon: const Icon(Icons.attach_money, size: 28),
          label: const Text(
            'Enviar Cotización',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Color _getQuotationStatusColor() {
    switch (_myQuotation?.status) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getQuotationStatusIcon() {
    switch (_myQuotation?.status) {
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.hourglass_empty;
    }
  }

  String _getQuotationStatusText() {
    if (_request!.status == 'completed' || _request!.status == 'rated') {
      return '✅ Trabajo Completado';
    }
    
    switch (_myQuotation?.status) {
      case 'accepted':
        return '🎉 ¡Cotización Aceptada!';
      case 'rejected':
        return 'Cotización Rechazada';
      default:
        return 'Cotización Enviada - Pendiente';
    }
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Imagen'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}