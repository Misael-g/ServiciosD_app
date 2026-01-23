import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../data/datasources/quotations_remote_ds.dart';
import '../../data/datasources/profiles_remote_ds.dart';
import '../../data/models/quotation_model.dart';
import '../../data/models/profile_model.dart';
import '../../core/utils/snackbar_helper.dart';

/// Pantalla para ver y comparar cotizaciones (Cliente)
class ViewQuotationsPage extends StatefulWidget {
  final String serviceRequestId;

  const ViewQuotationsPage({
    super.key,
    required this.serviceRequestId,
  });

  @override
  State<ViewQuotationsPage> createState() => _ViewQuotationsPageState();
}

class _ViewQuotationsPageState extends State<ViewQuotationsPage> {
  final QuotationsRemoteDataSource _quotationsDS = QuotationsRemoteDataSource();
  final ProfilesRemoteDataSource _profilesDS = ProfilesRemoteDataSource();

  List<QuotationModel> _quotations = [];
  Map<String, ProfileModel> _technicians = {};
  bool _isLoading = true;
  String _sortBy = 'price'; // price, rating, time

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('es', timeago.EsMessages());
    _loadQuotations();
  }

  Future<void> _loadQuotations() async {
    setState(() => _isLoading = true);

    try {
      print('🔵 [VIEW_QUOTATIONS] Cargando cotizaciones');
      print('   Solicitud: ${widget.serviceRequestId}');

      // Cargar cotizaciones
      final quotations =
          await _quotationsDS.getQuotationsByRequest(widget.serviceRequestId);

      print('✅ [VIEW_QUOTATIONS] ${quotations.length} cotizaciones encontradas');

      // Cargar perfiles de técnicos
      final technicians = <String, ProfileModel>{};
      for (var quotation in quotations) {
        if (!technicians.containsKey(quotation.technicianId)) {
          try {
            final profile =
                await _profilesDS.getProfileById(quotation.technicianId);
            technicians[quotation.technicianId] = profile;
            print('   Técnico cargado: ${profile.fullName}');
          } catch (e) {
            print('   ⚠️ Error cargando técnico ${quotation.technicianId}: $e');
          }
        }
      }

      setState(() {
        _quotations = quotations;
        _technicians = technicians;
        _isLoading = false;
      });

      _sortQuotations();
    } catch (e) {
      print('❌ [VIEW_QUOTATIONS] Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(context, 'Error al cargar cotizaciones');
      }
    }
  }

  void _sortQuotations() {
    setState(() {
      if (_sortBy == 'price') {
        _quotations.sort((a, b) => a.estimatedPrice.compareTo(b.estimatedPrice));
      } else if (_sortBy == 'rating') {
        _quotations.sort((a, b) {
          final ratingA = _technicians[a.technicianId]?.averageRating ?? 0;
          final ratingB = _technicians[b.technicianId]?.averageRating ?? 0;
          return ratingB.compareTo(ratingA); // Mayor a menor
        });
      } else if (_sortBy == 'time') {
        _quotations.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Más reciente primero
      }
    });
  }

  Future<void> _acceptQuotation(QuotationModel quotation) async {
    final technician = _technicians[quotation.technicianId];
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aceptar Cotización'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Confirmas que deseas aceptar la cotización de ${technician?.fullName ?? "este técnico"}?'),
            const SizedBox(height: 16),
            const Text(
              'Desglose:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (quotation.laborCost != null)
              _buildPriceRow('Mano de obra', quotation.laborCost!),
            if (quotation.materialsCost != null)
              _buildPriceRow('Materiales', quotation.materialsCost!),
            const Divider(),
            _buildPriceRow('TOTAL', quotation.estimatedPrice, isTotal: true),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El precio quedará bloqueado y no se podrá cambiar',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      print('📤 [VIEW_QUOTATIONS] Aceptando cotización: ${quotation.id}');
      
      await _quotationsDS.acceptQuotation(quotation.id);
      
      print('✅ [VIEW_QUOTATIONS] Cotización aceptada');
      
      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          '¡Cotización aceptada! El técnico ha sido notificado',
        );
        Navigator.pop(context, true); // Regresar con resultado
      }
    } catch (e) {
      print('❌ [VIEW_QUOTATIONS] Error al aceptar: $e');
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'Error al aceptar cotización',
        );
      }
    }
  }

  Future<void> _rejectQuotation(QuotationModel quotation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Cotización'),
        content: const Text('¿Estás seguro que deseas rechazar esta cotización?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _quotationsDS.rejectQuotation(quotation.id);
      
      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Cotización rechazada');
        _loadQuotations();
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error al rechazar cotización');
      }
    }
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotizaciones Recibidas'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quotations.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Filtros de ordenamiento
                    _buildSortOptions(),
                    
                    // Lista de cotizaciones
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _quotations.length,
                        itemBuilder: (context, index) {
                          final quotation = _quotations[index];
                          final technician = _technicians[quotation.technicianId];
                          final isLowestPrice = _quotations
                              .where((q) => q.status == 'pending')
                              .fold<double?>(
                                null,
                                (lowest, q) =>
                                    lowest == null || q.estimatedPrice < lowest
                                        ? q.estimatedPrice
                                        : lowest,
                              ) ==
                              quotation.estimatedPrice;

                          return _buildQuotationCard(
                            quotation,
                            technician,
                            isLowestPrice: isLowestPrice && quotation.status == 'pending',
                          );
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
            'No hay cotizaciones aún',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Espera a que los técnicos envíen sus propuestas',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ordenar por:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'price',
                label: Text('Precio'),
                icon: Icon(Icons.attach_money, size: 18),
              ),
              ButtonSegment(
                value: 'rating',
                label: Text('Rating'),
                icon: Icon(Icons.star, size: 18),
              ),
              ButtonSegment(
                value: 'time',
                label: Text('Reciente'),
                icon: Icon(Icons.schedule, size: 18),
              ),
            ],
            selected: {_sortBy},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _sortBy = newSelection.first;
              });
              _sortQuotations();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuotationCard(
    QuotationModel quotation,
    ProfileModel? technician, {
    bool isLowestPrice = false,
  }) {
    final isAccepted = quotation.status == 'accepted';
    final isRejected = quotation.status == 'rejected';
    final isPending = quotation.status == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isLowestPrice ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isLowestPrice
            ? const BorderSide(color: Colors.green, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        children: [
          // Badge de mejor precio
          if (isLowestPrice)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.workspace_premium, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'MEJOR PRECIO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // Contenido principal
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con info del técnico
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue,
                      backgroundImage: technician?.profilePictureUrl != null
                          ? NetworkImage(technician!.profilePictureUrl!)
                          : null,
                      child: technician?.profilePictureUrl == null
                          ? Text(
                              technician?.fullName[0].toUpperCase() ?? 'T',
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            technician?.fullName ?? 'Técnico',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (technician?.averageRating != null) ...[
                                const Icon(Icons.star,
                                    size: 16, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  '${technician!.averageRating!.toStringAsFixed(1)} ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '(${technician.totalReviews ?? 0})',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ],
                          ),
                          if (technician?.completedServices != null)
                            Text(
                              '${technician!.completedServices} trabajos completados',
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

                // Precio destacado
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Precio Total',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 4),
                        ],
                      ),
                      Text(
                        '\$${quotation.estimatedPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Desglose
                if (quotation.laborCost != null || quotation.materialsCost != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        if (quotation.laborCost != null)
                          _buildDetailRow(
                            '💪 Mano de obra',
                            '\$${quotation.laborCost!.toStringAsFixed(2)}',
                          ),
                        if (quotation.materialsCost != null)
                          _buildDetailRow(
                            '🛠️ Materiales',
                            '\$${quotation.materialsCost!.toStringAsFixed(2)}',
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                // Duración y llegada
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        Icons.schedule,
                        '${quotation.estimatedDuration} min',
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (quotation.estimatedArrivalTime != null)
                      Expanded(
                        child: _buildInfoChip(
                          Icons.delivery_dining,
                          _formatArrivalTime(quotation.estimatedArrivalTime!),
                          Colors.orange,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Descripción
                if (quotation.description != null &&
                    quotation.description!.isNotEmpty) ...[
                  const Text(
                    'Descripción:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    quotation.description!,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Timestamp
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      timeago.format(quotation.createdAt, locale: 'es'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                // Botones de acción
                if (isPending) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _rejectQuotation(quotation),
                          icon: const Icon(Icons.close),
                          label: const Text('Rechazar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _acceptQuotation(quotation),
                          icon: const Icon(Icons.check),
                          label: const Text('Aceptar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Estado
                if (isAccepted)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'ACEPTADA',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (isRejected)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.cancel, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'RECHAZADA',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
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