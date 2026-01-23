import 'package:flutter/material.dart';
import '../../data/datasources/service_requests_remote_ds.dart';
import '../../data/datasources/profiles_remote_ds.dart';
import '../../data/models/service_request_model.dart';
import '../../data/models/profile_model.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/constants/service_states.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_widgets.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        title: const Text('TecniHogar'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ��� Tarjeta de bienvenida moderna
                  _buildWelcomeCard(),
                  const SizedBox(height: 24),

                  // ��� Sección de servicios
                  const SectionHeader(
                    title: '¿Qué servicio necesitas?',
                    icon: Icons.build_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildServicesGrid(),
                  const SizedBox(height: 32),

                  // ��� Solicitudes activas
                  SectionHeader(
                    title: 'Solicitudes Activas',
                    subtitle: '${_activeRequests.length} en progreso',
                  ),
                  const SizedBox(height: 12),
                  _buildActiveRequestsList(),
                ],
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.waving_hand,
            size: 40,
            color: AppColors.white,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()}, ${_getFirstName()}!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '¿Qué servicio necesitas hoy?',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesGrid() {
    final services = [
      {
        'name': 'Electricista',
        'icon': Icons.electrical_services,
        'color': AppColors.warning
      },
      {'name': 'Plomero', 'icon': Icons.plumbing, 'color': AppColors.info},
      {
        'name': 'Carpintero',
        'icon': Icons.carpenter,
        'color': const Color(0xFF8B4513)
      },
      {
        'name': 'Pintor',
        'icon': Icons.format_paint,
        'color': const Color(0xFF9B59B6)
      },
      {
        'name': 'Mecánico',
        'icon': Icons.build,
        'color': AppColors.secondary
      },
      {
        'name': 'Otros',
        'icon': Icons.more_horiz,
        'color': AppColors.success
      },
    ];

    return GridView.builder(
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
        return _buildServiceCard(
          service['name'] as String,
          service['icon'] as IconData,
          service['color'] as Color,
        );
      },
    );
  }

  Widget _buildServiceCard(String name, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateRequestPage(preselectedService: name),
          ),
        ).then((result) {
          if (result == true) {
            _loadData();
          }
        });
      },
      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveRequestsList() {
    if (_activeRequests.isEmpty) {
      return const EmptyState(
        icon: Icons.inbox_outlined,
        title: 'No tienes solicitudes activas',
        message: 'Crea una nueva solicitud para comenzar',
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _activeRequests.length,
      itemBuilder: (context, index) {
        final request = _activeRequests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildRequestCard(ServiceRequestModel request) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RequestDetailPage(requestId: request.id),
          ),
        ).then((_) => _loadData());
      },
      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                StatusBadge(
                  label: ServiceStates.getDisplayName(request.status),
                  color: Color(ServiceStates.getStateColor(request.status)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              request.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    request.serviceType,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                LocationBadge(location: request.address),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
