import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../data/datasources/service_requests_remote_ds.dart';
import '../../data/datasources/profiles_remote_ds.dart';
import '../../data/datasources/quotations_remote_ds.dart';
import '../../data/models/service_request_model.dart';
import '../../core/utils/location_helper.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/constants/service_states.dart';
import '../../core/config/supabase_config.dart';
import './request_detail_page.dart';

/// 🎨 Pantalla de solicitudes disponibles MEJORADA
/// Con diseño profesional, animaciones y mejor UX
class AvailableRequestsPage extends StatefulWidget {
  const AvailableRequestsPage({super.key});

  @override
  State<AvailableRequestsPage> createState() => _AvailableRequestsPageState();
}

class _AvailableRequestsPageState extends State<AvailableRequestsPage>
    with SingleTickerProviderStateMixin {
  final ServiceRequestsRemoteDataSource _serviceRequestsDS =
      ServiceRequestsRemoteDataSource();
  final ProfilesRemoteDataSource _profilesDS = ProfilesRemoteDataSource();
  final QuotationsRemoteDataSource _quotationsDS = QuotationsRemoteDataSource();
  final MapController _mapController = MapController();

  List<ServiceRequestModel> _requests = [];
  Position? _currentPosition;
  bool _isLoading = true;
  bool _isUpdatingLocation = false;
  bool _showMap = true;
  final Map<String, bool> _myQuotationsCache = {};

  // 🆕 Para animaciones
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _loadDataAndUpdateLocation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDataAndUpdateLocation() async {
    setState(() => _isLoading = true);

    try {
      final position = await LocationHelper.getCurrentLocation();

      if (position != null) {
        setState(() => _currentPosition = position);
        await _updateTechnicianLocation(position);
        await _loadNearbyRequests(position);
        _animationController.forward();
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

  Future<void> _updateTechnicianLocation(Position position) async {
    setState(() => _isUpdatingLocation = true);

    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) return;

      await _profilesDS.updateLocation(
        userId,
        latitude: position.latitude,
        longitude: position.longitude,
        address: 'Ubicación actualizada',
      );

      print('✅ Ubicación del técnico actualizada');
    } catch (e) {
      print('⚠️ Error al actualizar ubicación: $e');
    } finally {
      if (mounted) {
        setState(() => _isUpdatingLocation = false);
      }
    }
  }

  Future<void> _loadNearbyRequests(Position position) async {
    try {
      final requests = await _serviceRequestsDS.getAllNearbyRequests(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusMeters: 10000,
      );

      _myQuotationsCache.clear();
      for (var request in requests) {
        final myQuotation =
            await _quotationsDS.getMyQuotationForRequest(request.id);
        _myQuotationsCache[request.id] = myQuotation != null;
      }

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
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : _currentPosition == null
              ? _buildNoLocationWidget()
              : _showMap
                  ? _buildMapView()
                  : _buildListView(),
    );
  }

  // 🎨 AppBar mejorado
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.orange,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Solicitudes Disponibles',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (_requests.isNotEmpty)
            Text(
              '${_requests.length} ${_requests.length == 1 ? 'solicitud' : 'solicitudes'} cerca de ti',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
        ],
      ),
      actions: [
        // Toggle vista
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(_showMap ? Icons.view_list : Icons.map),
            onPressed: () {
              setState(() => _showMap = !_showMap);
            },
            tooltip: _showMap ? 'Ver Lista' : 'Ver Mapa',
            color: Colors.white,
          ),
        ),
        // Actualizar ubicación
        Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
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
            onPressed:
                _isUpdatingLocation ? null : _loadDataAndUpdateLocation,
            tooltip: 'Actualizar ubicación',
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // 🎨 Loading mejorado
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Buscando solicitudes cercanas...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // 🎨 Sin ubicación mejorado
  Widget _buildNoLocationWidget() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off,
                size: 64,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ubicación no disponible',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Necesitamos tu ubicación para mostrarte las solicitudes cercanas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadDataAndUpdateLocation,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🗺️ Vista de mapa mejorada
  Widget _buildMapView() {
    return Column(
      children: [
        // Panel de información superior
        _buildInfoPanel(),

        // Mapa
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
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
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.servicios_app',
                  ),
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        radius: 10000,
                        useRadiusInMeter: true,
                        color: Colors.orange.withOpacity(0.1),
                        borderColor: Colors.orange,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      // Mi ubicación
                      Marker(
                        point: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        width: 100,
                        height: 100,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Tu ubicación',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person_pin_circle,
                                color: Colors.orange,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Solicitudes
                      ..._requests
                          .where((request) =>
                              request.latitude != 0.0 &&
                              request.longitude != 0.0)
                          .map((request) {
                        final distance = LocationHelper.calculateDistance(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                          request.latitude,
                          request.longitude,
                        );

                        return Marker(
                          point: LatLng(request.latitude!, request.longitude!),
                          width: 140,
                          height: 140,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TechnicianRequestDetailPage(
                                      requestId: request.id),
                                ),
                              ).then((_) => _loadDataAndUpdateLocation());
                            },
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue.shade400,
                                        Colors.blue.shade600,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 8,
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
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        LocationHelper.formatDistance(distance),
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 32,
                                  ),
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

              // Botón para centrar mapa
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton.small(
                  onPressed: () {
                    _mapController.move(
                      LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      13,
                    );
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Colors.orange),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 🎨 Panel de información mejorado
  Widget _buildInfoPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoChip(
            Icons.work_outline,
            '${_requests.length}',
            _requests.length == 1 ? 'Solicitud' : 'Solicitudes',
            Colors.blue,
          ),
          _buildInfoChip(
            Icons.location_on_outlined,
            '10 km',
            'Radio',
            Colors.orange,
          ),
          _buildInfoChip(
            Icons.schedule,
            'Hoy',
            'Actualizadas',
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
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
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 📋 Vista de lista mejorada
  Widget _buildListView() {
    return RefreshIndicator(
      onRefresh: _loadDataAndUpdateLocation,
      color: Colors.orange,
      child: _requests.isEmpty
          ? _buildEmptyState()
          : FadeTransition(
              opacity: _fadeAnimation,
              child: ListView.builder(
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

                  return _buildRequestCard(request, distance, index);
                },
              ),
            ),
    );
  }

  // 🎨 Estado vacío mejorado
  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 64,
                color: Colors.blue.shade300,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No hay solicitudes cercanas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Actualmente no hay trabajos disponibles\nen tu área',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _loadDataAndUpdateLocation,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🎨 Card de solicitud MEJORADO
  Widget _buildRequestCard(
      ServiceRequestModel request, double? distance, int index) {
    final iSentQuotation = _myQuotationsCache[request.id] ?? false;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TechnicianRequestDetailPage(requestId: request.id),
                ),
              ).then((_) => _loadDataAndUpdateLocation());
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con título y distancia
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.work_outline,
                                    size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  request.serviceType,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (distance != null) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade400,
                                Colors.blue.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 16, color: Colors.white),
                              const SizedBox(height: 2),
                              Text(
                                LocationHelper.formatDistance(distance),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Descripción
                  Text(
                    request.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Footer con estado
                  Row(
                    children: [
                      // Estado
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(request, iSentQuotation)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getStatusColor(request, iSentQuotation)
                                  .withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(request, iSentQuotation),
                                size: 16,
                                color: _getStatusColor(request, iSentQuotation),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _getDisplayStatusForTechnician(
                                      request, iSentQuotation),
                                  style: TextStyle(
                                    color:
                                        _getStatusColor(request, iSentQuotation),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Botón ver detalles
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.orange, Colors.deepOrange],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Ver',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios,
                                size: 12, color: Colors.white),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🎨 Helpers para estado y color
  String _getDisplayStatusForTechnician(
      ServiceRequestModel request, bool iSentQuotation) {
    if (iSentQuotation) {
      return 'Cotización Enviada';
    }

    if (request.status == 'quotation_sent') {
      return 'Disponible';
    }

    if (request.status == 'pending') {
      return 'Nueva';
    }

    return ServiceStates.getDisplayName(request.status);
  }

  Color _getStatusColor(ServiceRequestModel request, bool iSentQuotation) {
    if (iSentQuotation) {
      return Colors.orange;
    }

    if (request.status == 'pending' || request.status == 'quotation_sent') {
      return Colors.green;
    }

    return Color(ServiceStates.getStateColor(request.status));
  }

  IconData _getStatusIcon(ServiceRequestModel request, bool iSentQuotation) {
    if (iSentQuotation) {
      return Icons.send;
    }

    if (request.status == 'pending') {
      return Icons.new_releases;
    }

    if (request.status == 'quotation_sent') {
      return Icons.check_circle;
    }

    return Icons.info;
  }
}