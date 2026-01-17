import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/datasources/service_requests_remote_ds.dart';
import '../../data/models/service_request_model.dart';
import '../../core/utils/location_helper.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/constants/service_states.dart';
import 'send_quotation_page.dart';

/// Pantalla de solicitudes disponibles para el técnico
class AvailableRequestsPage extends StatefulWidget {
  const AvailableRequestsPage({super.key});

  @override
  State<AvailableRequestsPage> createState() => _AvailableRequestsPageState();
}

class _AvailableRequestsPageState extends State<AvailableRequestsPage> {
  final ServiceRequestsRemoteDataSource _serviceRequestsDS =
      ServiceRequestsRemoteDataSource();

  List<ServiceRequestModel> _requests = [];
  Position? _currentPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Obtener ubicación
      _currentPosition = await LocationHelper.getCurrentLocation();

      if (_currentPosition != null) {
        // Obtener solicitudes cercanas
        final requests = await _serviceRequestsDS.getAllNearbyRequests(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          radiusMeters: 10000,
        );

        setState(() {
          _requests = requests;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          SnackbarHelper.showError(
            context,
            'No se pudo obtener tu ubicación',
          );
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(context, 'Error al cargar solicitudes');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes Disponibles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _loadData,
            tooltip: 'Actualizar ubicación',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _requests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay solicitudes cercanas',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
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
              builder: (_) => SendQuotationPage(request: request),
            ),
          ).then((_) => _loadData());
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
                          Icon(Icons.location_on, size: 14, color: Colors.blue[700]),
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
                        color: Color(ServiceStates.getStateColor(request.status)),
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
}