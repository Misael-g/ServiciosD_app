import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/datasources/profiles_remote_ds.dart';
import '../../data/models/profile_model.dart';
import '../../core/utils/location_helper.dart';
import '../../core/utils/snackbar_helper.dart';

/// Pantalla de mapa con técnicos cercanos
class ClientMapPage extends StatefulWidget {
  const ClientMapPage({super.key});

  @override
  State<ClientMapPage> createState() => _ClientMapPageState();
}

class _ClientMapPageState extends State<ClientMapPage> {
  final ProfilesRemoteDataSource _profilesDS = ProfilesRemoteDataSource();
  final MapController _mapController = MapController();

  Position? _currentPosition;
  List<ProfileModel> _nearbyTechnicians = [];
  bool _isLoading = true;
  String? _selectedSpecialty;

  // Lista de especialidades
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
    _loadMap();
  }

  Future<void> _loadMap() async {
    setState(() => _isLoading = true);

    try {
      // Obtener ubicación actual
      final position = await LocationHelper.getCurrentLocation();

      if (position == null) {
        if (mounted) {
          SnackbarHelper.showError(
            context,
            'No se pudo obtener tu ubicación',
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      setState(() {
        _currentPosition = position;
      });

      // Cargar técnicos cercanos
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
      // Si hay filtro de especialidad, buscar por especialidad
      if (_selectedSpecialty != null && _selectedSpecialty != 'Todos') {
        final technicians = await _profilesDS.getNearbyTechnicians(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          serviceType: _selectedSpecialty!,
          radiusMeters: 10000, // 10km
        );
        setState(() {
          _nearbyTechnicians = technicians;
        });
      } else {
        // Buscar todos los técnicos cercanos
        final technicians = await _profilesDS.getAllNearbyTechnicians(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          radiusMeters: 10000,
        );
        setState(() {
          _nearbyTechnicians = technicians;
        });
      }
    } catch (e) {
      print('Error al cargar técnicos: $e');
    }
  }

  void _showTechnicianInfo(ProfileModel technician) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage: technician.profilePictureUrl != null
                      ? NetworkImage(technician.profilePictureUrl!)
                      : null,
                  child: technician.profilePictureUrl == null
                      ? Text(
                          technician.fullName[0].toUpperCase(),
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
                        technician.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (technician.averageRating != null)
                        Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              '${technician.averageRating!.toStringAsFixed(1)} '
                              '(${technician.totalReviews ?? 0} reseñas)',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (technician.specialties != null &&
                technician.specialties!.isNotEmpty) ...[
              const Text(
                'Especialidades:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: technician.specialties!
                    .map((s) => Chip(label: Text(s)))
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
            if (technician.phone != null) ...[
              Row(
                children: [
                  const Icon(Icons.phone, size: 20),
                  const SizedBox(width: 8),
                  Text(technician.phone!),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (technician.baseRate != null)
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 20),
                  const SizedBox(width: 8),
                  Text('Tarifa base: \$${technician.baseRate!.toStringAsFixed(0)}/hora'),
                ],
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
        title: const Text('Técnicos Cercanos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _isLoading ? null : _loadMap,
            tooltip: 'Actualizar ubicación',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentPosition == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No se pudo obtener tu ubicación'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadMap,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Filtro de especialidades
                    Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _specialties.length,
                        itemBuilder: (context, index) {
                          final specialty = _specialties[index];
                          final isSelected = _selectedSpecialty == specialty ||
                              (specialty == 'Todos' && _selectedSpecialty == null);

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: FilterChip(
                              label: Text(specialty),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedSpecialty =
                                      selected && specialty != 'Todos'
                                          ? specialty
                                          : null;
                                });
                                _loadNearbyTechnicians();
                              },
                            ),
                          );
                        },
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
                          initialZoom: 14,
                          minZoom: 10,
                          maxZoom: 18,
                        ),
                        children: [
                          // Capa de tiles (OpenStreetMap)
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.servicios_app',
                          ),

                          // Marcadores
                          MarkerLayer(
                            markers: [
                              // Marcador de ubicación actual
                              Marker(
                                point: LatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                ),
                                width: 80,
                                height: 80,
                                child: const Icon(
                                  Icons.my_location,
                                  color: Colors.blue,
                                  size: 40,
                                ),
                              ),

                              // Marcadores de técnicos
                              ..._nearbyTechnicians.map((technician) {
                                if (technician.latitude == null ||
                                    technician.longitude == null) {
                                  return null;
                                }

                                return Marker(
                                  point: LatLng(
                                    technician.latitude!,
                                    technician.longitude!,
                                  ),
                                  width: 100,
                                  height: 100,
                                  child: GestureDetector(
                                    onTap: () => _showTechnicianInfo(technician),
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
                                          child: Text(
                                            technician.fullName.split(' ').first,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
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
                              }).whereType<Marker>(),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Info panel
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person, color: Colors.blue),
                              const SizedBox(height: 4),
                              Text(
                                '${_nearbyTechnicians.length}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Técnicos',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on, color: Colors.red),
                              const SizedBox(height: 4),
                              const Text(
                                '10 km',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Radio',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
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
}