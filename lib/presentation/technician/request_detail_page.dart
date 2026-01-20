import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/datasources/service_requests_remote_ds.dart';
import '../../data/datasources/profiles_remote_ds.dart';
import '../../data/models/service_request_model.dart';
import '../../data/models/profile_model.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/config/supabase_config.dart';
import 'send_quotation_page.dart';

/// Pantalla de detalle de solicitud para técnico
/// Muestra toda la información de la solicitud antes de cotizar
class RequestDetailPage extends StatefulWidget {
  final String requestId;

  const RequestDetailPage({
    super.key,
    required this.requestId,
  });

  @override
  State<RequestDetailPage> createState() => _RequestDetailPageState();
}

class _RequestDetailPageState extends State<RequestDetailPage> {
  final ServiceRequestsRemoteDataSource _requestsDS =
      ServiceRequestsRemoteDataSource();
  final ProfilesRemoteDataSource _profilesDS = ProfilesRemoteDataSource();

  ServiceRequestModel? _request;
  ProfileModel? _clientProfile;
  Position? _technicianPosition;
  double? _distanceKm;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequestDetail();
  }

  Future<void> _loadRequestDetail() async {
    setState(() => _isLoading = true);

    try {
      // Cargar solicitud
      final request = await _requestsDS.getServiceRequestById(widget.requestId);

      // Cargar perfil del cliente
      final clientProfile = await _profilesDS.getProfileById(request.clientId);

      // Obtener ubicación del técnico para calcular distancia
      final technicianId = SupabaseConfig.currentUserId;
      if (technicianId != null) {
        final techProfile = await _profilesDS.getProfileById(technicianId);
        
        if (techProfile.latitude != null && 
            techProfile.longitude != null &&
            request.latitude != null && 
            request.longitude != null) {
          
          _technicianPosition = Position(
            latitude: techProfile.latitude!,
            longitude: techProfile.longitude!,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );

          // Calcular distancia
          final distance = Geolocator.distanceBetween(
            techProfile.latitude!,
            techProfile.longitude!,
            request.latitude!,
            request.longitude!,
          );

          _distanceKm = distance / 1000; // Convertir a km
        }
      }

      setState(() {
        _request = request;
        _clientProfile = clientProfile;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error al cargar solicitud: $e');
        Navigator.pop(context);
      }
    }
  }

  void _goToSendQuotation() {
    if (_request == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SendQuotationPage(serviceRequest: _request!),
      ),
    ).then((sent) {
      // Si envió la cotización, regresar
      if (sent == true && mounted) {
        Navigator.pop(context, true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cargando...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_request == null || _clientProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('No se pudo cargar la solicitud')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Solicitud'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Título y tipo de servicio
          Card(
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
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _request!.serviceType,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (_distanceKm != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                '${_distanceKm!.toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _request!.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _request!.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Información del cliente
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información del Cliente',
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
                        backgroundColor: Theme.of(context).colorScheme.primary,
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
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (_clientProfile!.phone != null)
                              Row(
                                children: [
                                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    _clientProfile!.phone!,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Fotos (si existen)
          if (_request!.images != null && _request!.images!.isNotEmpty) ...[
            const Text(
              'Fotos del Problema',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
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
                      onTap: () {
                        // Mostrar imagen en pantalla completa
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
                                  child: CachedNetworkImage(imageUrl: imageUrl),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.error),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Ubicación en mapa
          const Text(
            'Ubicación del Servicio',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (_request!.latitude != null && _request!.longitude != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 200,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(
                      _request!.latitude!,
                      _request!.longitude!,
                    ),
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.servicios_app',
                    ),
                    MarkerLayer(
                      markers: [
                        // Marcador del servicio
                        Marker(
                          point: LatLng(
                            _request!.latitude!,
                            _request!.longitude!,
                          ),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                        // Marcador del técnico (si tiene ubicación)
                        if (_technicianPosition != null)
                          Marker(
                            point: LatLng(
                              _technicianPosition!.latitude,
                              _technicianPosition!.longitude,
                            ),
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.person_pin_circle,
                              color: Colors.blue,
                              size: 40,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_request!.address != null)
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _request!.address!,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
          ],

          const SizedBox(height: 24),
        ],
      ),

      // Botón para enviar cotización
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _goToSendQuotation,
            icon: const Icon(Icons.attach_money),
            label: const Text('Enviar Cotización'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}