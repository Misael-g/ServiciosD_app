import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/datasources/profiles_remote_ds.dart';
import '../../data/models/profile_model.dart';
import '../../core/utils/location_helper.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_widgets.dart';

class ClientMapPage extends StatefulWidget {
  const ClientMapPage({super.key});

  @override
  State<ClientMapPage> createState() => _ClientMapPageState();
}

class _ClientMapPageState extends State<ClientMapPage> 
    with SingleTickerProviderStateMixin {
  final ProfilesRemoteDataSource _profilesDS = ProfilesRemoteDataSource();
  final MapController _mapController = MapController();

  Position? _currentPosition;
  List<ProfileModel> _nearbyTechnicians = [];
  bool _isLoading = true;
  String? _selectedSpecialty;
  ProfileModel? _selectedTechnician;
  late AnimationController _animationController;

  final List<String> _specialties = [
    'Todos',
    'Electricista',
    'Plomero',
    'Carpintero',
    'Pintor',
    'Mecánico',
    'Jardinero',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadMap();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadMap() async {
    setState(() => _isLoading = true);

    try {
      final position = await LocationHelper.getCurrentLocation();

      if (position == null) {
        if (mounted) {
          SnackbarHelper.showError(context, 'No se pudo obtener tu ubicación');
        }
        setState(() => _isLoading = false);
        return;
      }

      setState(() {
        _currentPosition = position;
      });

      await _loadNearbyTechnicians();
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error al cargar mapa: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadNearbyTechnicians() async {
    if (_currentPosition == null) return;

    try {
      List<ProfileModel> technicians;
      
      if (_selectedSpecialty != null && _selectedSpecialty != 'Todos') {
        technicians = await _profilesDS.getNearbyTechnicians(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          serviceType: _selectedSpecialty!,
          radiusMeters: 10000,
        );
      } else {
        technicians = await _profilesDS.getAllNearbyTechnicians(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          radiusMeters: 10000,
        );
      }

      setState(() {
        _nearbyTechnicians = technicians;
      });
    } catch (e) {
      print('Error al cargar técnicos: $e');
    }
  }

  void _showTechnicianInfo(ProfileModel technician) {
    setState(() {
      _selectedTechnician = technician;
    });
    _animationController.forward();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildTechnicianSheet(technician),
    ).then((_) {
      setState(() {
        _selectedTechnician = null;
      });
      _animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Mapa
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _currentPosition == null
                  ? _buildNoLocationWidget()
                  : _buildMapView(),

          // AppBar flotante
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Botón atrás con diseño mejorado
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.medium,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Título
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: AppShadows.medium,
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.explore_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Técnicos Cercanos',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Botón actualizar
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.medium,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.my_location_rounded),
                      color: AppColors.white,
                      onPressed: _isLoading ? null : _loadMap,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Filtros flotantes
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: _buildFloatingFilters(),
          ),

          // Panel de información flotante
          if (_currentPosition != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildInfoPanel(),
            ),
        ],
      ),
    );
  }

  Widget _buildNoLocationWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
              'Verifica que tengas los permisos de ubicación activados',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadMap,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        initialZoom: 14,
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
              color: AppColors.primary.withValues(alpha: 0.1),
              borderColor: AppColors.primary,
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
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primaryDark,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppShadows.medium,
                    ),
                    child: const Text(
                      'Tu ubicación',
                      style: TextStyle(
                        fontSize: 11,
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
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primaryDark,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_pin_circle_rounded,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Técnicos
            ..._nearbyTechnicians
                .where((t) => t.latitude != null && t.longitude != null)
                .map((technician) {
              final isSelected = _selectedTechnician?.id == technician.id;
              
              return Marker(
                point: LatLng(technician.latitude!, technician.longitude!),
                width: 120,
                height: 120,
                child: GestureDetector(
                  onTap: () => _showTechnicianInfo(technician),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppColors.success
                              : AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected 
                                ? AppColors.success
                                : AppColors.warning,
                            width: 2,
                          ),
                          boxShadow: AppShadows.medium,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (technician.averageRating != null) ...[
                              const Icon(
                                Icons.star_rounded,
                                size: 12,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                technician.averageRating!.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected 
                                      ? AppColors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.medium,
                        ),
                        child: ProfileAvatar(
                          name: technician.fullName,
                          imageUrl: technician.profilePictureUrl,
                          radius: 18,
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
    );
  }

  Widget _buildFloatingFilters() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _specialties.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final specialty = _specialties[index];
          final isSelected = _selectedSpecialty == specialty ||
              (specialty == 'Todos' && _selectedSpecialty == null);

          return InkWell(
            onTap: () {
              setState(() {
                _selectedSpecialty =
                    isSelected && specialty != 'Todos' ? null : specialty;
              });
              _loadNearbyTechnicians();
            },
            borderRadius: BorderRadius.circular(25),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primaryDark,
                        ],
                      )
                    : null,
                color: isSelected ? null : AppColors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.border,
                  width: 1.5,
                ),
                boxShadow: AppShadows.small,
              ),
              child: Text(
                specialty,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColors.white
                      : AppColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.large,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            Icons.people_rounded,
            _nearbyTechnicians.length.toString(),
            'Técnicos',
            AppColors.primary,
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.border,
          ),
          _buildInfoItem(
            Icons.location_on_rounded,
            '10 km',
            'Radio',
            AppColors.success,
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.border,
          ),
          _buildInfoItem(
            Icons.star_rounded,
            '4.5+',
            'Rating',
            AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
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
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicianSheet(ProfileModel technician) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Contenido
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Avatar
                ProfileAvatar(
                  name: technician.fullName,
                  imageUrl: technician.profilePictureUrl,
                  radius: 50,
                  showBorder: true,
                ),
                const SizedBox(height: 16),

                // Nombre
                Text(
                  technician.fullName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Rating
                if (technician.averageRating != null)
                  RatingDisplay(
                    rating: technician.averageRating!,
                    totalReviews: technician.totalReviews ?? 0,
                    size: 20,
                  ),

                const SizedBox(height: 20),

                // Especialidades
                if (technician.specialties != null &&
                    technician.specialties!.isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Especialidades:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: technician.specialties!
                        .map((s) => SpecialtyChip(
                              label: s,
                              isSelected: true,
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // Teléfono
                if (technician.phone != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.phone_rounded,
                          color: AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          technician.phone!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Bio
                if (technician.bio != null && technician.bio!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    technician.bio!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 24),

                // Botón cerrar
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}