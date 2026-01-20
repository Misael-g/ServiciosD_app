import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../data/datasources/quotations_remote_ds.dart';
import '../../data/datasources/profiles_remote_ds.dart';
import '../../data/models/quotation_model.dart';
import '../../data/models/profile_model.dart';
import '../../core/utils/snackbar_helper.dart';

/// Pantalla para que el cliente vea y compare cotizaciones
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
  String _sortBy = 'price'; // 'price', 'rating', 'time'

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('es', timeago.EsMessages());
    _loadQuotations();
  }

  Future<void> _loadQuotations() async {
    setState(() => _isLoading = true);

    try {
      // Cargar cotizaciones
      final quotations = await _quotationsDS.getQuotationsByRequest(
        widget.serviceRequestId,
      );

      // Cargar perfiles de técnicos
      final technicians = <String, ProfileModel>{};
      for (final quotation in quotations) {
        if (!technicians.containsKey(quotation.technicianId)) {
          final profile = await _profilesDS.getProfileById(
            quotation.technicianId,
          );
          technicians[quotation.technicianId] = profile;
        }
      }

      setState(() {
        _quotations = quotations;
        _technicians = technicians;
        _isLoading = false;
      });

      _sortQuotations();
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'Error al cargar cotizaciones: $e',
        );
        setState(() => _isLoading = false);
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
        _quotations.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      }
    });
  }

  Future<void> _acceptQuotation(QuotationModel quotation) async {
    // Confirmar
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aceptar Cotización'),
        content: Text(
          '¿Estás seguro de aceptar esta cotización por '
          '\$${quotation.estimatedPrice.toStringAsFixed(2)}?',
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
              foregroundColor: Colors.white,
            ),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _quotationsDS.acceptQuotation(quotation.id);

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          '¡Cotización aceptada! El técnico ha sido notificado',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'Error al aceptar cotización: $e',
        );
      }
    }
  }

  Future<void> _rejectQuotation(QuotationModel quotation) async {
    // Confirmar
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Cotización'),
        content: const Text('¿Estás seguro de rechazar esta cotización?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _quotationsDS.rejectQuotation(quotation.id);

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          'Cotización rechazada',
        );
        _loadQuotations(); // Recargar
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'Error al rechazar cotización: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotizaciones Recibidas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuotations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quotations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aún no hay cotizaciones',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Los técnicos cercanos podrán enviarte sus precios',
                        style: TextStyle(color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Filtros de ordenamiento
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Text(
                            'Ordenar por:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'price',
                                  label: Text('Precio'),
                                  icon: Icon(Icons.attach_money, size: 16),
                                ),
                                ButtonSegment(
                                  value: 'rating',
                                  label: Text('Rating'),
                                  icon: Icon(Icons.star, size: 16),
                                ),
                                ButtonSegment(
                                  value: 'time',
                                  label: Text('Fecha'),
                                  icon: Icon(Icons.access_time, size: 16),
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
                          ),
                        ],
                      ),
                    ),

                    // Lista de cotizaciones
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _quotations.length,
                        itemBuilder: (context, index) {
                          final quotation = _quotations[index];
                          final technician = _technicians[quotation.technicianId];

                          if (technician == null) {
                            return const SizedBox.shrink();
                          }

                          final isLowest = index == 0 && _sortBy == 'price';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: isLowest ? 4 : 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: isLowest
                                  ? const BorderSide(color: Colors.green, width: 2)
                                  : BorderSide.none,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header con info del técnico
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 25,
                                        backgroundColor:
                                            Theme.of(context).colorScheme.primary,
                                        backgroundImage:
                                            technician.profilePictureUrl != null
                                                ? NetworkImage(
                                                    technician.profilePictureUrl!)
                                                : null,
                                        child: technician.profilePictureUrl == null
                                            ? Text(
                                                technician.fullName[0]
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              technician.fullName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                if (technician.averageRating !=
                                                    null) ...[
                                                  const Icon(
                                                    Icons.star,
                                                    size: 16,
                                                    color: Colors.amber,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    technician.averageRating!
                                                        .toStringAsFixed(1),
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    ' (${technician.totalReviews ?? 0})',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                ],
                                                if (technician.completedServices !=
                                                    null)
                                                  Text(
                                                    '${technician.completedServices} trabajos',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isLowest)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'Mejor Precio',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),

                                  const Divider(height: 24),

                                  // Precio y detalles
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'PRECIO TOTAL',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '\$${quotation.estimatedPrice.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.access_time,
                                                  size: 16),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${quotation.estimatedDuration} min',
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            timeago.format(
                                              quotation.createdAt,
                                              locale: 'es',
                                            ),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Descripción
                                  Text(
                                    'Descripción del trabajo:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(quotation.description),

                                  const SizedBox(height: 16),

                                  // Botones de acción
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              _rejectQuotation(quotation),
                                          icon: const Icon(Icons.close),
                                          label: const Text('Rechazar'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 2,
                                        child: ElevatedButton.icon(
                                          onPressed: () =>
                                              _acceptQuotation(quotation),
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
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}