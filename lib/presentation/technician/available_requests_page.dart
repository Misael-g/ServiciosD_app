import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../data/datasources/service_requests_remote_ds.dart';
import '../../data/datasources/profiles_remote_ds.dart';
import '../../data/models/service_request_model.dart';
import '../../core/utils/location_helper.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/constants/service_states.dart';
import '../../core/config/supabase_config.dart';
import '../client/request_detail_page.dart';

/// Pantalla de solicitudes disponibles con mapa para el técnico
class AvailableRequestsPage extends StatefulWidget {
  const AvailableRequestsPage({super.key});

  @override
  State<AvailableRequestsPage> createState() => _AvailableRequestsPageState();
}

class _AvailableRequestsPageState extends State<AvailableRequestsPage> {
  final ServiceRequestsRemoteDataSource _serviceRequestsDS =
      ServiceRequestsRemoteDataSource();
  final ProfilesRemoteDataSource _profilesDS = ProfilesRemoteDataSource();
  final MapController _mapController = MapController();

  List<ServiceRequestModel> _requests = [];
  Position? _currentPosition;
  bool _isLoading = true;
  bool _isUpdatingLocation = false;
  bool _showMap = true; // Toggle entre mapa y lista

  @override
  void initState() {
    super.initState();
    _loadDataAndUpdateLocation();
  }

  /// Carga datos Y actualiza ubicación GPS del técnico
  Future<void> _loadDataAndUpdateLocation() async {
    setState(() => _isLoading = true);

    try {
      // 1. Obtener ubicación GPS actual
      final position = await LocationHelper.getCurrentLocation();

      if (position != null) {
        setState(() => _currentPosition = position);

        // 2. Actualizar ubicación en el perfil del técnico
        await _updateTechnicianLocation(position);

        // 3. Cargar solicitudes cercanas
        await _loadNearbyRequests(position);
      } else {
        if (mounted) {
          SnackbarHelper.showError(
            context,
            'No se pudo obtener tu ubicación',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error al cargar datos: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Actualiza la ubicación GPS en el perfil del técnico
  Future<void> _updateTechnicianLocation(Position position) async {
    setState(() => _isUpdatingLocation = true);

    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) return;

      // Obtener dirección desde coordenadas
      String? address;
      try {
        // Aquí podrías usar geocoding si lo necesitas
        // final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        address = 'Ubicación actualizada'; // Placeholder
      } catch (e) {
        address = null;
      }

      await _profilesDS.updateLocation(
        userId,
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );

      print('✅ Ubicación del técnico actualizada');
    } catch (e) {
      print('⚠️ Error al actualizar ubicación: $e');
      // No mostrar error al usuario, es silencioso
    } finally {
      if (mounted) {
        setState(() => _isUpdatingLocation = false);
      }
    }
  }

  /// Carga solicitudes cercanas
  Future<void> _loadNearbyRequests(Position position) async {
    try {
      final requests = await _serviceRequestsDS.getAllNearbyRequests(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusMeters: 10000, // 10km
      );

      setState(() {
        _requests = requests;
      });
    } catch (e) {
      print('Error al cargar solicitudes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes Disponibles'),
        actions: [
          // Toggle mapa/lista
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
              });
            },
            tooltip: _showMap ? 'Ver Lista' : 'Ver Mapa',
          ),
          // Actualizar ubicación
          IconButton(
            icon: _isUpdatingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.my_location),
            onPressed: _isUpdatingLocation ? null : _loadDataAndUpdateLocation,
            tooltip: 'Actualizar ubicación',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentPosition == null
              ? _buildNoLocationWidget()
              : _showMap
                  ? _buildMapView()
                  : _buildListView(),
    );
  }

  Widget _buildNoLocationWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No se pudo obtener tu ubicación'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadDataAndUpdateLocation,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Column(
      children: [
        // Info panel superior
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoChip(
                Icons.work_outline,
                '${_requests.length}',
                'Solicitudes',
                Colors.blue,
              ),
              _buildInfoChip(
                Icons.location_on,
                '10 km',
                'Radio',
                Colors.orange,
              ),
              if (_isUpdatingLocation)
                _buildInfoChip(
                  Icons.gps_fixed,
                  'GPS',
                  'Actualizando...',
                  Colors.green,
                ),
            ],
          ),
        ),

        // Mapa
        Expanded(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              initialZoom: 13,
              minZoom: 10,
              maxZoom: 18,
            ),
            children: [
              // Capa de tiles (OpenStreetMap)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.servicios_app',
              ),

              // Círculo de radio de 10km
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    radius: 10000, // 10km en metros
                    useRadiusInMeter: true,
                    color: Colors.blue.withOpacity(0.1),
                    borderColor: Colors.blue,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),

              // Marcadores
              MarkerLayer(
                markers: [
                  // Marcador de ubicación del técnico
                  Marker(
                    point: LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    width: 80,
                    height: 80,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Tu ubicación',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.person_pin_circle,
                          color: Colors.green,
                          size: 40,
                        ),
                      ],
                    ),
                  ),

                  // Marcadores de solicitudes
                  ..._requests.where((request) {
                    // 🔍 DEBUG: Imprimir coordenadas para verificar
                    print('📍 Request ${request.id}: lat=${request.latitude}, lng=${request.longitude}');
                    return request.latitude != 0.0 && request.longitude != 0.0;
                  }).map((request) {
                    final distance = LocationHelper.calculateDistance(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                      request.latitude,
                      request.longitude,
                    );

                    return Marker(
                      point: LatLng(request.latitude!, request.longitude!),
                      width: 120,
                      height: 120,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RequestDetailPage(requestId: request.id),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    request.serviceType,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    LocationHelper.formatDistance(distance),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListView() {
    return RefreshIndicator(
      onRefresh: _loadDataAndUpdateLocation,
      child: _requests.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay solicitudes cercanas',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                final request = _requests[index];
                final distance = _currentPosition != null
                    ? LocationHelper.calculateDistance(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                        request.latitude,
                        request.longitude,
                      )
                    : null;

                return _buildRequestCard(request, distance);
              },
            ),
    );
  }

  Widget _buildRequestCard(ServiceRequestModel request, double? distance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RequestDetailPage(requestId: request.id),
            ),
          );
        },
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
                      request.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (distance != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on,
                              size: 14, color: Colors.blue[700]),
                          const SizedBox(width: 4),
                          Text(
                            LocationHelper.formatDistance(distance),
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                request.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.work_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    request.serviceType,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Color(ServiceStates.getStateColor(request.status))
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ServiceStates.getDisplayName(request.status),
                      style: TextStyle(
                        color:
                            Color(ServiceStates.getStateColor(request.status)),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}