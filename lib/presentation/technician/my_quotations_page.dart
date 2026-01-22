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

/// Pantalla para ver mis cotizaciones enviadas (Técnico)
class MyQuotationsPage extends StatefulWidget {
  const MyQuotationsPage({super.key});

  @override
  State<MyQuotationsPage> createState() => _MyQuotationsPageState();
}

class _MyQuotationsPageState extends State<MyQuotationsPage> {
  final QuotationsRemoteDataSource _quotationsDS = QuotationsRemoteDataSource();
  final ServiceRequestsRemoteDataSource _requestsDS = ServiceRequestsRemoteDataSource();
  final ProfilesRemoteDataSource _profilesDS = ProfilesRemoteDataSource();

  List<QuotationModel> _quotations = [];
  Map<String, ServiceRequestModel> _requests = {};
  Map<String, ProfileModel> _clients = {};
  bool _isLoading = true;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('es', timeago.EsMessages());
    _loadMyQuotations();
  }

  Future<void> _loadMyQuotations() async {
    setState(() => _isLoading = true);

    try {
      final technicianId = SupabaseConfig.currentUserId;
      if (technicianId == null) {
        throw Exception('No hay técnico autenticado');
      }

      print('🔵 [MY_QUOTATIONS] Cargando cotizaciones del técnico: $technicianId');

      final quotations = await _quotationsDS.getQuotationsByTechnician(technicianId);

      print('✅ [MY_QUOTATIONS] ${quotations.length} cotizaciones encontradas');

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
            print('⚠️ Error cargando solicitud ${quotation.serviceRequestId}: $e');
          }
        }
      }

      setState(() {
        _quotations = quotations;
        _requests = requests;
        _clients = clients;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [MY_QUOTATIONS] Error: $e');
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
        title: const Text('Completar Trabajo'),
        content: const Text(
          '¿Confirmas que has completado este trabajo?\n\n'
          'El cliente podrá verificar y dejar una reseña.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Completar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      print('📤 [MY_QUOTATIONS] Completando trabajo: ${request.id}');

      await _requestsDS.completeService(request.id);

      print('✅ [MY_QUOTATIONS] Trabajo marcado como completado');

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          '¡Trabajo completado! El cliente puede dejar una reseña',
        );
        _loadMyQuotations();
      }
    } catch (e) {
      print('❌ [MY_QUOTATIONS] Error al completar: $e');
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
      appBar: AppBar(
        title: const Text('Mis Cotizaciones'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quotations.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildFilterChips(),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredQuotations.length,
                        itemBuilder: (context, index) {
                          final quotation = _filteredQuotations[index];
                          final request = _requests[quotation.serviceRequestId];
                          final client = request != null ? _clients[request.clientId] : null;

                          return _buildQuotationCard(quotation, request, client);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No has enviado cotizaciones',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Busca solicitudes y envía tus propuestas',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Todas', 'all', _quotations.length),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Pendientes',
              'pending',
              _quotations.where((q) => q.status == 'pending').length,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Aceptadas',
              'accepted',
              _quotations.where((q) => q.status == 'accepted').length,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Rechazadas',
              'rejected',
              _quotations.where((q) => q.status == 'rejected').length,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _filterStatus = value);
        }
      },
      selectedColor: Colors.orange.shade100,
      checkmarkColor: Colors.orange,
    );
  }

  Widget _buildQuotationCard(
    QuotationModel quotation,
    ServiceRequestModel? request,
    ProfileModel? client,
  ) {
    if (request == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Error al cargar solicitud'),
        ),
      );
    }

    final isPending = quotation.status == 'pending';
    final isAccepted = quotation.status == 'accepted';
    final isRejected = quotation.status == 'rejected';
    final isCompleted = request.status == 'completed' || request.status == 'rated';
    
    // ✅ LÓGICA CORRECTA: El técnico puede completar si:
    // 1. La cotización fue aceptada
    // 2. El servicio está en 'quotation_accepted' o 'in_progress'
    // 3. No está ya completado
    final canComplete = isAccepted && 
                       (request.status == 'quotation_accepted' || request.status == 'in_progress') &&
                       !isCompleted;

    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.hourglass_empty;
    String statusText = quotation.status;

    if (isPending) {
      statusColor = Colors.orange;
      statusIcon = Icons.hourglass_empty;
      statusText = 'Pendiente';
    } else if (isAccepted) {
      if (isCompleted) {
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        statusText = 'Completada';
      } else {
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Aceptada';
      }
    } else if (isRejected) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      statusText = 'Rechazada';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Header con estado
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  statusText.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  timeago.format(quotation.createdAt, locale: 'es'),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info de la solicitud
                Text(
                  request.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  request.description,
                  style: TextStyle(color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Info del cliente
                if (client != null)
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blue,
                        backgroundImage: client.profilePictureUrl != null
                            ? NetworkImage(client.profilePictureUrl!)
                            : null,
                        child: client.profilePictureUrl == null
                            ? Text(
                                client.fullName[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              client.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (client.phone != null)
                              Text(
                                client.phone!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                const Divider(height: 24),

                // Desglose de precio
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
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
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '\$${quotation.estimatedPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.green.shade700,
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
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${quotation.estimatedDuration} min',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    if (quotation.estimatedArrivalTime != null) ...[
                      Icon(Icons.delivery_dining, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _formatArrivalTime(quotation.estimatedArrivalTime!),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),

                // Descripción
                if (quotation.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    quotation.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],

                // ✅ BOTÓN DE COMPLETAR - Solo si puede completar
                if (canComplete) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _completeWork(request),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Marcar como Completado'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],

                // Mensajes de estado
                if (isCompleted) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.done_all, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Trabajo completado. Esperando reseña del cliente.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (isRejected) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'El cliente eligió otra cotización',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (isPending) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.hourglass_empty, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Esperando respuesta del cliente',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (isAccepted && !isCompleted) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            request.status == 'in_progress'
                                ? 'Trabajo en progreso. Márcalo como completado cuando termines.'
                                : '¡Cotización aceptada! Dirígete al lugar y comienza el trabajo.',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
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

  String _formatArrivalTime(int hours) {
    if (hours == 0) return '30 min';
    if (hours == 1) return '1 hora';
    if (hours < 24) return '$hours horas';
    return 'Mañana';
  }
}