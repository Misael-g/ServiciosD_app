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
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_widgets.dart';
import './request_detail_page.dart';

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
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
          SnackbarHelper.showError(context, 'No se pudo obtener tu ubicación');
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
        final myQuotation = await _quotationsDS.getMyQuotationForRequest(request.id);
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
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // AppBar Expandible Moderno
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.success,
                      AppColors.success.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.work_outline_rounded,
                              size: 32,
                              color: AppColors.white,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Solicitudes Disponibles',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_currentPosition != null)
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      size: 16,
                                      color: AppColors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_requests.length} cerca de ti',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
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
              ),
            ),
            actions: [
              // Toggle Vista
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    _showMap ? Icons.list_rounded : Icons.map_rounded,
                    color: AppColors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _showMap = !_showMap;
                    });
                  },
                  tooltip: _showMap ? 'Ver Lista' : 'Ver Mapa',
                ),
              ),
              // Actualizar Ubicación
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: _isUpdatingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.white,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.my_location_rounded,
                          color: AppColors.white,
                        ),
                  onPressed: _isUpdatingLocation ? null : _loadDataAndUpdateLocation,
                  tooltip: 'Actualizar ubicación',
                ),
              ),
            ],
          ),

          // Contenido
          SliverToBoxAdapter(
            child: _isLoading
                ? const SizedBox(
                    height: 400,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _currentPosition == null
                    ? _buildNoLocationWidget()
                    : FadeTransition(
                        opacity: _animationController,
                        child: _showMap ? _buildMapView() : _buildListView(),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoLocationWidget() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.medium,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_off_rounded,
              size: 64,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No se pudo obtener tu ubicación',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Verifica que tengas los permisos de ubicación activados y el GPS encendido',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loadDataAndUpdateLocation,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Column(
      children: [
        // Panel de Info Superior
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.white,
                AppColors.background,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.medium,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoChip(
                Icons.work_outline_rounded,
                '${_requests.length}',
                'Solicitudes',
                AppColors.success,
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.border,
              ),
              _buildInfoChip(
                Icons.location_on_rounded,
                '10 km',
                'Radio',
                AppColors.warning,
              ),
              if (_isUpdatingLocation) ...[
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.border,
                ),
                _buildInfoChip(
                  Icons.gps_fixed_rounded,
                  'GPS',
                  'Actualizando',
                  AppColors.info,
                ),
              ],
            ],
          ),
        ),

        // Mapa
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 500,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppShadows.large,
          ),
          clipBehavior: Clip.antiAlias,
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
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderColor: AppColors.success,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Tu ubicación
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
                            gradient: LinearGradient(
                              colors: [
                                AppColors.success,
                                AppColors.success.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppShadows.medium,
                          ),
                          child: const Text(
                            'Tú',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.medium,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.success,
                                  AppColors.success.withValues(alpha: 0.8),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_pin_circle_rounded,
                              color: AppColors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Solicitudes
                  ..._requests
                      .where((r) => r.latitude != 0.0 && r.longitude != 0.0)
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
                                requestId: request.id,
                              ),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                                boxShadow: AppShadows.medium,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    request.serviceType,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    LocationHelper.formatDistance(distance),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                shape: BoxShape.circle,
                                boxShadow: AppShadows.small,
                              ),
                              child: const Icon(
                                Icons.location_on_rounded,
                                color: AppColors.primary,
                                size: 36,
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
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildListView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _requests.isEmpty
          ? EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No hay solicitudes cercanas',
              message: 'Revisa más tarde o amplía tu radio de búsqueda',
              action: ElevatedButton.icon(
                onPressed: _loadDataAndUpdateLocation,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Actualizar'),
              ),
            )
          : Column(
              children: _requests.map((request) {
                final distance = _currentPosition != null
                    ? LocationHelper.calculateDistance(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                        request.latitude,
                        request.longitude,
                      )
                    : null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRequestCard(request, distance),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildRequestCard(ServiceRequestModel request, double? distance) {
    final iSentQuotation = _myQuotationsCache[request.id] ?? false;
    final statusColor = iSentQuotation
        ? AppColors.success
        : Color(ServiceStates.getStateColor(request.status));

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TechnicianRequestDetailPage(requestId: request.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: iSentQuotation 
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.border,
            width: iSentQuotation ? 2 : 1,
          ),
          boxShadow: AppShadows.small,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getServiceIcon(request.serviceType),
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            request.serviceType,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (distance != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.info,
                            AppColors.info.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: AppColors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            LocationHelper.formatDistance(distance),
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Contenido
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: LocationBadge(location: request.address),
                      ),
                      if (iSentQuotation)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.success,
                              width: 1.5,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: AppColors.success,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Cotización Enviada',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  IconData _getServiceIcon(String serviceType) {
    switch (serviceType) {
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
      default:
        return Icons.handyman_rounded;
    }
  }

  String _getDisplayStatusForTechnician(ServiceRequestModel request) {
    final iSentQuotation = _myQuotationsCache[request.id] ?? false;
    
    if (iSentQuotation) {
      return '📤 Cotización Enviada';
    }
    
    if (request.status == 'quotation_sent') {
      return '🟢 Disponible';
    }
    
    return ServiceStates.getDisplayName(request.status);
  }
}