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

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> with SingleTickerProviderStateMixin {
  final ServiceRequestsRemoteDataSource _serviceRequestsDataSource =
      ServiceRequestsRemoteDataSource();
  final ProfilesRemoteDataSource _profilesDataSource =
      ProfilesRemoteDataSource();

  List<ServiceRequestModel> _activeRequests = [];
  ProfileModel? _profile;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _profilesDataSource.getCurrentUserProfile(),
        _serviceRequestsDataSource.getMyServiceRequests(),
      ]);

      final profile = results[0] as ProfileModel;
      final requests = results[1] as List<ServiceRequestModel>;

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

      _animationController.forward();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(context, 'Error al cargar datos');
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '¡Buenos días';
    if (hour < 19) return '¡Buenas tardes';
    return '¡Buenas noches';
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // App Bar Expandible
                  SliverAppBar(
                    expandedHeight: 200,
                    floating: false,
                    pinned: true,
                    backgroundColor: AppColors.primary,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.primaryDark,
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
                                FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: ProfileAvatar(
                                          name: _profile?.fullName ?? '?',
                                          imageUrl: _profile?.profilePictureUrl,
                                          radius: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${_getGreeting()},',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: AppColors.white,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _getFirstName(),
                                              style: const TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.white,
                                                letterSpacing: -0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
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

                  // Contenido
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Quick Stats
                            _buildQuickStats(),
                            const SizedBox(height: 32),

                            // Servicios
                            const SectionHeader(
                              title: '¿Qué servicio necesitas?',
                              icon: Icons.home_repair_service_rounded,
                            ),
                            const SizedBox(height: 16),
                            _buildServicesGrid(),
                            const SizedBox(height: 32),

                            // Solicitudes activas
                            SectionHeader(
                              title: 'Solicitudes Activas',
                              subtitle: _activeRequests.isEmpty
                                  ? 'No tienes solicitudes activas'
                                  : '${_activeRequests.length} en progreso',
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Lista de solicitudes activas
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: _buildActiveRequestsList(),
                  ),

                  // Espacio al final
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
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
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Nueva Solicitud',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 4,
      ),
    );
  }

  Widget _buildQuickStats() {
    final totalRequests = _activeRequests.length;
    final pendingQuotations = _activeRequests
        .where((r) => r.status == 'quotation_sent')
        .length;
    final inProgress = _activeRequests
        .where((r) => r.status == 'in_progress')
        .length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Activas',
            totalRequests.toString(),
            Icons.assignment_outlined,
            AppColors.info,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Cotizaciones',
            pendingQuotations.toString(),
            Icons.request_quote_outlined,
            AppColors.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'En Progreso',
            inProgress.toString(),
            Icons.build_circle_outlined,
            AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.small,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildServicesGrid() {
    final services = [
      {
        'name': 'Electricista',
        'icon': Icons.electrical_services_rounded,
        'color': const Color(0xFFFFA726),
        'gradient': [const Color(0xFFFFA726), const Color(0xFFFF8A65)]
      },
      {
        'name': 'Plomero',
        'icon': Icons.plumbing_rounded,
        'color': const Color(0xFF42A5F5),
        'gradient': [const Color(0xFF42A5F5), const Color(0xFF1E88E5)]
      },
      {
        'name': 'Carpintero',
        'icon': Icons.carpenter_rounded,
        'color': const Color(0xFF8D6E63),
        'gradient': [const Color(0xFF8D6E63), const Color(0xFF6D4C41)]
      },
      {
        'name': 'Pintor',
        'icon': Icons.format_paint_rounded,
        'color': const Color(0xFFAB47BC),
        'gradient': [const Color(0xFFAB47BC), const Color(0xFF8E24AA)]
      },
      {
        'name': 'Mecánico',
        'icon': Icons.build_circle_rounded,
        'color': const Color(0xFF26A69A),
        'gradient': [const Color(0xFF26A69A), const Color(0xFF00897B)]
      },
      {
        'name': 'Otros',
        'icon': Icons.more_horiz_rounded,
        'color': const Color(0xFF66BB6A),
        'gradient': [const Color(0xFF66BB6A), const Color(0xFF43A047)]
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return _buildServiceCard(
          service['name'] as String,
          service['icon'] as IconData,
          service['gradient'] as List<Color>,
        );
      },
    );
  }

  Widget _buildServiceCard(String name, IconData icon, List<Color> gradient) {
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: AppColors.white),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveRequestsList() {
    if (_activeRequests.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyState(
          icon: Icons.inbox_outlined,
          title: 'No tienes solicitudes activas',
          message: 'Crea una nueva solicitud para comenzar',
          action: ElevatedButton.icon(
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
            label: const Text('Crear Solicitud'),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final request = _activeRequests[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildRequestCard(request),
          );
        },
        childCount: _activeRequests.length,
      ),
    );
  }

  Widget _buildRequestCard(ServiceRequestModel request) {
    final statusColor = Color(ServiceStates.getStateColor(request.status));

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RequestDetailPage(requestId: request.id),
          ),
        ).then((_) => _loadData());
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.small,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.assignment_outlined,
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                    color: statusColor,
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.build_circle_outlined,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              request.serviceType,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LocationBadge(location: request.address),
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
}