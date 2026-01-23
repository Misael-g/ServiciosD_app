import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../data/datasources/quotations_remote_ds.dart';
import '../../data/datasources/service_requests_remote_ds.dart';
import '../../data/datasources/profiles_remote_ds.dart';
import '../../data/models/quotation_model.dart';
import '../../data/models/service_request_model.dart';
import '../../data/models/profile_model.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/config/supabase_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_widgets.dart';

class MyQuotationsPage extends StatefulWidget {
  const MyQuotationsPage({super.key});

  @override
  State<MyQuotationsPage> createState() => _MyQuotationsPageState();
}

class _MyQuotationsPageState extends State<MyQuotationsPage> 
    with SingleTickerProviderStateMixin {
  final QuotationsRemoteDataSource _quotationsDS = QuotationsRemoteDataSource();
  final ServiceRequestsRemoteDataSource _requestsDS = ServiceRequestsRemoteDataSource();
  final ProfilesRemoteDataSource _profilesDS = ProfilesRemoteDataSource();

  List<QuotationModel> _quotations = [];
  Map<String, ServiceRequestModel> _requests = {};
  Map<String, ProfileModel> _clients = {};
  bool _isLoading = true;
  String _filterStatus = 'all';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('es', timeago.EsMessages());
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadMyQuotations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadMyQuotations() async {
    setState(() => _isLoading = true);

    try {
      final technicianId = SupabaseConfig.currentUserId;
      if (technicianId == null) {
        throw Exception('No hay técnico autenticado');
      }

      final quotations = await _quotationsDS.getQuotationsByTechnician(technicianId);
      final requests = <String, ServiceRequestModel>{};
      final clients = <String, ProfileModel>{};

      for (var quotation in quotations) {
        if (!requests.containsKey(quotation.serviceRequestId)) {
          try {
            final request = await _requestsDS.getServiceRequestById(quotation.serviceRequestId);
            requests[quotation.serviceRequestId] = request;

            if (!clients.containsKey(request.clientId)) {
              final client = await _profilesDS.getProfileById(request.clientId);
              clients[request.clientId] = client;
            }
          } catch (e) {
            print('⚠️ Error cargando solicitud: $e');
          }
        }
      }

      setState(() {
        _quotations = quotations;
        _requests = requests;
        _clients = clients;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(context, 'Error al cargar cotizaciones');
      }
    }
  }

  Future<void> _completeWork(ServiceRequestModel request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
            SizedBox(width: 12),
            Text('Completar Trabajo'),
          ],
        ),
        content: const Text(
          '¿Confirmas que has completado este trabajo?\n\nEl cliente podrá verificar y dejar una reseña.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('Completar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _requestsDS.completeService(request.id);

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          '¡Trabajo completado! El cliente puede dejar una reseña',
        );
        _loadMyQuotations();
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error al completar trabajo');
      }
    }
  }

  List<QuotationModel> get _filteredQuotations {
    if (_filterStatus == 'all') return _quotations;
    return _quotations.where((q) => q.status == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // AppBar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.warning,
                      AppColors.warning.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
              title: const Text(
                'Mis Cotizaciones',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              centerTitle: true,
            ),
          ),

          // Filtros
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.small,
              ),
              child: Row(
                children: [
                  _buildFilterChip('Todas', 'all', _quotations.length),
                  _buildFilterChip(
                    'Pendientes',
                    'pending',
                    _quotations.where((q) => q.status == 'pending').length,
                  ),
                  _buildFilterChip(
                    'Aceptadas',
                    'accepted',
                    _quotations.where((q) => q.status == 'accepted').length,
                  ),
                ],
              ),
            ),
          ),

          // Lista
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : _filteredQuotations.isEmpty
                  ? SliverFillRemaining(
                      child: EmptyState(
                        icon: Icons.receipt_long_rounded,
                        title: 'No hay cotizaciones',
                        message: _filterStatus == 'all'
                            ? 'Aún no has enviado cotizaciones'
                            : 'No tienes cotizaciones en esta categoría',
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final quotation = _filteredQuotations[index];
                            final request = _requests[quotation.serviceRequestId];
                            final client = request != null ? _clients[request.clientId] : null;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: FadeTransition(
                                opacity: _animationController,
                                child: _buildQuotationCard(quotation, request, client),
                              ),
                            );
                          },
                          childCount: _filteredQuotations.length,
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _filterStatus == value;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _filterStatus = value;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppColors.warning,
                      AppColors.warning.withOpacity(0.8),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.white : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.white : AppColors.warning,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuotationCard(
    QuotationModel quotation,
    ServiceRequestModel? request,
    ProfileModel? client,
  ) {
    if (request == null) {
      return Card(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: const Text('Error al cargar solicitud'),
        ),
      );
    }

    final isPending = quotation.status == 'pending';
    final isAccepted = quotation.status == 'accepted';
    final isRejected = quotation.status == 'rejected';
    final isCompleted = request.status == 'completed' || request.status == 'rated';

    final canComplete = isAccepted &&
        (request.status == 'quotation_accepted' || request.status == 'in_progress') &&
        !isCompleted;

    Color statusColor = AppColors.warning;
    IconData statusIcon = Icons.hourglass_empty_rounded;
    String statusText = 'Pendiente';

    if (isAccepted) {
      if (isCompleted) {
        statusColor = AppColors.info;
        statusIcon = Icons.done_all_rounded;
        statusText = 'Completada';
      } else {
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
        statusText = 'Aceptada';
      }
    } else if (isRejected) {
      statusColor = AppColors.error;
      statusIcon = Icons.cancel_rounded;
      statusText = 'Rechazada';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: AppShadows.small,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  statusText.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  timeago.format(quotation.createdAt, locale: 'es'),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Contenido
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Solicitud
                Text(
                  request.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  request.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 16),

                // Cliente
                if (client != null)
                  Row(
                    children: [
                      ProfileAvatar(
                        name: client.fullName,
                        imageUrl: client.profilePictureUrl,
                        radius: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              client.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (client.phone != null)
                              Text(
                                client.phone!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // Precio
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.success.withOpacity(0.15),
                        AppColors.success.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      if (quotation.laborCost != null)
                        _buildPriceRow('Mano de obra', quotation.laborCost!),
                      if (quotation.materialsCost != null)
                        _buildPriceRow('Materiales', quotation.materialsCost!),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '\$${quotation.estimatedPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                              color: AppColors.success,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Tiempo
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${quotation.estimatedDuration} min',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),

                // Botón completar
                if (canComplete) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _completeWork(request),
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Marcar como Completado'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],

                // Estados informativos
                if (isCompleted) ...[
                  const SizedBox(height: 12),
                  InfoCard(
                    message: 'Trabajo completado. Esperando reseña del cliente.',
                    icon: Icons.done_all_rounded,
                    color: AppColors.info,
                  ),
                ],

                if (isRejected) ...[
                  const SizedBox(height: 12),
                  InfoCard(
                    message: 'El cliente eligió otra cotización',
                    icon: Icons.info_outline_rounded,
                    color: AppColors.error,
                  ),
                ],

                if (isPending) ...[
                  const SizedBox(height: 12),
                  InfoCard(
                    message: 'Esperando respuesta del cliente',
                    icon: Icons.hourglass_empty_rounded,
                    color: AppColors.warning,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}