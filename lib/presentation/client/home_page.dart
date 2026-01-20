import 'package:flutter/material.dart';
import '../../data/datasources/service_requests_remote_ds.dart';
import '../../data/datasources/profiles_remote_ds.dart';
import '../../data/models/service_request_model.dart';
import '../../data/models/profile_model.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/constants/service_states.dart';
import 'create_request_page.dart';
import 'request_detail_page.dart';

/// Página principal del cliente con saludo personalizado
class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  final ServiceRequestsRemoteDataSource _serviceRequestsDataSource =
      ServiceRequestsRemoteDataSource();
  final ProfilesRemoteDataSource _profilesDataSource =
      ProfilesRemoteDataSource();

  List<ServiceRequestModel> _activeRequests = [];
  ProfileModel? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Cargar perfil y solicitudes en paralelo
      final results = await Future.wait([
        _profilesDataSource.getCurrentUserProfile(),
        _serviceRequestsDataSource.getMyServiceRequests(),
      ]);

      final profile = results[0] as ProfileModel;
      final requests = results[1] as List<ServiceRequestModel>;

      // Filtrar solo solicitudes activas
      final activeRequests = requests
          .where((r) =>
              r.status != 'completed' &&
              r.status != 'rated' &&
              r.status != 'cancelled')
          .toList();

      setState(() {
        _profile = profile;
        _activeRequests = activeRequests;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(context, 'Error al cargar datos');
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return '¡Buenos días';
    } else if (hour < 19) {
      return '¡Buenas tardes';
    } else {
      return '¡Buenas noches';
    }
  }

  String _getFirstName() {
    if (_profile == null) return '';
    final names = _profile!.fullName.trim().split(' ');
    return names.isNotEmpty ? names[0] : '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              SnackbarHelper.showInfo(
                  context, 'Notificaciones - Por implementar');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tarjeta de bienvenida PERSONALIZADA
                    _buildWelcomeCard(),
                    const SizedBox(height: 24),

                    // Servicios disponibles
                    _buildServicesSection(),
                    const SizedBox(height: 24),

                    // Solicitudes activas
                    _buildActiveRequestsSection(),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateRequestPage(),
            ),
          );

          if (result == true) {
            _loadData();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva Solicitud'),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(
              Icons.waving_hand,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_getGreeting()}, ${_getFirstName()}!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '¿Qué servicio necesitas hoy?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    final services = [
      {
        'name': 'Electricista',
        'icon': Icons.electrical_services,
        'color': Colors.amber
      },
      {'name': 'Plomero', 'icon': Icons.plumbing, 'color': Colors.blue},
      {'name': 'Carpintero', 'icon': Icons.carpenter, 'color': Colors.brown},
      {'name': 'Pintor', 'icon': Icons.format_paint, 'color': Colors.purple},
      {'name': 'Mecánico', 'icon': Icons.build, 'color': Colors.grey},
      {'name': 'Otros', 'icon': Icons.more_horiz, 'color': Colors.green},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Servicios Disponibles',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateRequestPage(
                      preselectedService: service['name'] as String,
                    ),
                  ),
                ).then((result) {
                  if (result == true) {
                    _loadData();
                  }
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Card(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      service['icon'] as IconData,
                      size: 32,
                      color: service['color'] as Color,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      service['name'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActiveRequestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Solicitudes Activas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (_activeRequests.isNotEmpty)
              TextButton(
                onPressed: () {
                  // Cambiar a tab de solicitudes
                  // TODO: Implementar navegación
                },
                child: const Text('Ver Todas'),
              ),
          ],
        ),
        const SizedBox(height: 16),

        if (_activeRequests.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes solicitudes activas',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea una nueva solicitud para comenzar',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount:
                _activeRequests.length > 3 ? 3 : _activeRequests.length,
            itemBuilder: (context, index) {
              final request = _activeRequests[index];
              return _buildRequestCard(request);
            },
          ),
      ],
    );
  }

  Widget _buildRequestCard(ServiceRequestModel request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RequestDetailPage(requestId: request.id),
            ),
          ).then((_) => _loadData());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          Color(ServiceStates.getStateColor(request.status))
                              .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ServiceStates.getDisplayName(request.status),
                      style: TextStyle(
                        color: Color(ServiceStates.getStateColor(
                            request.status)),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.location_on_outlined,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      request.address,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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