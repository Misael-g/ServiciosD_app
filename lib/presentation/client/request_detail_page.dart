import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/datasources/service_requests_remote_ds.dart';
import '../../data/datasources/quotations_remote_ds.dart';
import '../../data/datasources/profiles_remote_ds.dart';
import '../../data/datasources/reviews_remote_ds.dart';
import '../../data/models/service_request_model.dart';
import '../../data/models/quotation_model.dart';
import '../../data/models/profile_model.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/constants/service_states.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_widgets.dart';
import 'leave_review_page.dart';

/// Pantalla de detalle completo de solicitud (Cliente)
class RequestDetailPage extends StatefulWidget {
  final String requestId;

  const RequestDetailPage({
    super.key,
    required this.requestId,
  });

  @override
  State<RequestDetailPage> createState() => _RequestDetailPageState();
}

class _RequestDetailPageState extends State<RequestDetailPage> 
    with SingleTickerProviderStateMixin {
  final ServiceRequestsRemoteDataSource _requestsDS =
      ServiceRequestsRemoteDataSource();
  final QuotationsRemoteDataSource _quotationsDS =
      QuotationsRemoteDataSource();
  final ProfilesRemoteDataSource _profilesDS = ProfilesRemoteDataSource();
  final ReviewsRemoteDataSource _reviewsDS = ReviewsRemoteDataSource();

  ServiceRequestModel? _request;
  List<QuotationModel> _quotations = [];
  ProfileModel? _assignedTechnician;
  bool _isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
      final request = await _requestsDS.getServiceRequestById(widget.requestId);
      final quotations =
          await _quotationsDS.getQuotationsByRequest(widget.requestId);

      ProfileModel? technician;
      if (request.assignedTechnicianId != null) {
        technician =
            await _profilesDS.getProfileById(request.assignedTechnicianId!);
      }

      setState(() {
        _request = request;
        _quotations = quotations;
        _assignedTechnician = technician;
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

  Future<void> _acceptQuotation(QuotationModel quotation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success),
            SizedBox(width: 12),
            Text('Aceptar Cotización'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Confirmas que deseas aceptar esta cotización de \$${quotation.estimatedPrice.toStringAsFixed(2)}?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Desglose:',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (quotation.laborCost != null)
                    _buildPriceRow('Mano de obra', quotation.laborCost!),
                  if (quotation.materialsCost != null)
                    _buildPriceRow('Materiales', quotation.materialsCost!),
                  const Divider(height: 16),
                  _buildPriceRow('TOTAL', quotation.estimatedPrice, isTotal: true),
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
              backgroundColor: AppColors.success,
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
        SnackbarHelper.showSuccess(context, '¡Cotización aceptada!');
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error al aceptar cotización');
      }
    }
  }

  Future<void> _rejectQuotation(QuotationModel quotation) async {
    try {
      await _quotationsDS.rejectQuotation(quotation.id);
      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Cotización rechazada');
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error al rechazar cotización');
      }
    }
  }

  Future<void> _callPhone(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (!await launchUrl(url)) {
      if (mounted) {
        SnackbarHelper.showError(context, 'No se pudo abrir el teléfono');
      }
    }
  }

  Future<void> _cancelRequest() async {
    if (_request!.status != 'pending' && 
        _request!.status != 'quotation_sent') {
      SnackbarHelper.showError(
        context,
        'Solo puedes cancelar solicitudes pendientes',
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: AppColors.error),
            SizedBox(width: 12),
            Text('Cancelar Solicitud'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '¿Estás seguro que deseas cancelar esta solicitud?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            InfoCard(
              message: 'Esta acción no se puede deshacer',
              icon: Icons.warning_rounded,
              color: AppColors.error,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, mantener'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _requestsDS.cancelServiceRequest(widget.requestId);
      
      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          'Solicitud cancelada exitosamente',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'Error al cancelar solicitud',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detalle de Solicitud'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: FadeTransition(
                opacity: _animationController,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRequestInfo(),
                            const SizedBox(height: 16),
                            _buildStatusCard(),
                            const SizedBox(height: 16),
                            if (_assignedTechnician != null) ...[
                              _buildTechnicianCard(),
                              const SizedBox(height: 16),
                              // Botón Dejar Reseña
                              if (_request?.status == 'completed')
                                FutureBuilder<bool>(
                                  future: _reviewsDS.hasReviewForRequest(widget.requestId),
                                  builder: (context, snapshot) {
                                    final hasReview = snapshot.data ?? false;
                                    if (hasReview) {
                                      return InfoCard(
                                        message: '¡Gracias por tu reseña!',
                                        icon: Icons.check_circle_rounded,
                                        color: AppColors.success,
                                      );
                                    }
                                    return SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => LeaveReviewPage(
                                                serviceRequest: _request!,
                                                technician: _assignedTechnician!,
                                              ),
                                            ),
                                          ).then((_) => _loadData());
                                        },
                                        icon: const Icon(Icons.star_rounded),
                                        label: const Text('Dejar Reseña'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.warning,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                            // Botón cancelar
                            if (_request!.status == 'pending' || 
                                _request!.status == 'quotation_sent') ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: OutlinedButton.icon(
                                  onPressed: _cancelRequest,
                                  icon: const Icon(Icons.cancel_rounded),
                                  label: const Text('Cancelar Solicitud'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                    side: const BorderSide(color: AppColors.error),
                                  ),
                                ),
                              ),
                            ],
                            if (_quotations.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              const SectionHeader(
                                title: 'Cotizaciones Recibidas',
                                icon: Icons.receipt_long_rounded,
                              ),
                              const SizedBox(height: 16),
                              ..._quotations.map((q) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildQuotationCard(q),
                              )),
                            ],
                            if (_request?.images != null && 
                                _request!.images!.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              _buildImagesSection(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRequestInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _request?.title ?? '',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              _request?.description ?? '',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.work_outline, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  _request?.serviceType ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_request?.address ?? ''),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(_formatDate(_request?.createdAt)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = _request?.status ?? 'pending';
    final color = Color(ServiceStates.getStateColor(status));

    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estado',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    ServiceStates.getDisplayName(status),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicianCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Técnico Asignado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage: _assignedTechnician?.profilePictureUrl != null
                      ? NetworkImage(_assignedTechnician!.profilePictureUrl!)
                      : null,
                  child: _assignedTechnician?.profilePictureUrl == null
                      ? Text(
                          _assignedTechnician?.fullName[0].toUpperCase() ?? '?',
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
                        _assignedTechnician?.fullName ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_assignedTechnician?.averageRating != null)
                        Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              '${_assignedTechnician!.averageRating!.toStringAsFixed(1)} '
                              '(${_assignedTechnician!.totalReviews ?? 0})',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (_assignedTechnician?.phone != null) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _callPhone(_assignedTechnician!.phone!),
                icon: const Icon(Icons.phone),
                label: Text(_assignedTechnician!.phone!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuotationCard(QuotationModel quotation) {
    final isAccepted = quotation.status == 'accepted';
    final isRejected = quotation.status == 'rejected';
    final isPending = quotation.status == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${quotation.estimatedPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isAccepted
                        ? Colors.green[50]
                        : isRejected
                            ? Colors.red[50]
                            : Colors.orange[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    QuotationStates.getDisplayName(quotation.status),
                    style: TextStyle(
                      color: isAccepted
                          ? Colors.green[700]
                          : isRejected
                              ? Colors.red[700]
                              : Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Duración: ${quotation.formattedDuration}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(quotation.description),
            if (isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectQuotation(quotation),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _acceptQuotation(quotation),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Aceptar'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImagesSection() {
    if (_request!.images == null || _request!.images!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado
        Row(
          children: [
            const Icon(Icons.photo_library, size: 20, color: Colors.blue),
            const SizedBox(width: 8),
            const Text(
              'Mis Fotos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_request!.images!.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Scroll horizontal de fotos
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _request!.images!.length,
            itemBuilder: (context, index) {
              final imageUrl = _request!.images![index];
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    // Ver imagen en grande
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          backgroundColor: Colors.black,
                          appBar: AppBar(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            title: Text('Foto ${index + 1} de ${_request!.images!.length}'),
                          ),
                          body: Center(
                            child: InteractiveViewer(
                              minScale: 0.5,
                              maxScale: 4.0,
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(color: Colors.white),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image, color: Colors.white, size: 64),
                                        SizedBox(height: 16),
                                        Text('Error al cargar imagen', style: TextStyle(color: Colors.white)),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue.shade200, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.network(
                        imageUrl,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                              size: 40,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Hoy';
    } else if (diff.inDays == 1) {
      return 'Ayer';
    } else if (diff.inDays < 7) {
      return 'Hace ${diff.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            fontSize: isTotal ? 16 : 14,
            color: isTotal ? AppColors.success : AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );
}