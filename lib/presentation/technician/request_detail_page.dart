import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../data/datasources/service_requests_remote_ds.dart';
import '../../data/datasources/profiles_remote_ds.dart';
import '../../data/datasources/quotations_remote_ds.dart';
import '../../data/models/service_request_model.dart';
import '../../data/models/profile_model.dart';
import '../../data/models/quotation_model.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/config/supabase_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_widgets.dart';
import 'send_quotation_page.dart';

class TechnicianRequestDetailPage extends StatefulWidget {
  final String requestId;

  const TechnicianRequestDetailPage({
    super.key,
    required this.requestId,
  });

  @override
  State<TechnicianRequestDetailPage> createState() =>
      _TechnicianRequestDetailPageState();
}

class _TechnicianRequestDetailPageState
    extends State<TechnicianRequestDetailPage> with SingleTickerProviderStateMixin {
  final ServiceRequestsRemoteDataSource _requestsDS =
      ServiceRequestsRemoteDataSource();
  final ProfilesRemoteDataSource _profilesDS = ProfilesRemoteDataSource();
  final QuotationsRemoteDataSource _quotationsDS =
      QuotationsRemoteDataSource();

  ServiceRequestModel? _request;
  ProfileModel? _clientProfile;
  ProfileModel? _technicianProfile;
  QuotationModel? _myQuotation;
  bool _isLoading = true;
  bool _hasQuotation = false;
  double? _distanceKm;
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
      final myQuotation = await _quotationsDS.getMyQuotationForRequest(widget.requestId);
      final hasQuotation = myQuotation != null;
      final clientProfile = await _profilesDS.getProfileById(request.clientId);

      final technicianId = SupabaseConfig.currentUserId;
      ProfileModel? techProfile;
      if (technicianId != null) {
        techProfile = await _profilesDS.getProfileById(technicianId);

        if (techProfile.latitude != null &&
            techProfile.longitude != null &&
            request.latitude != null &&
            request.longitude != null) {
          final distance = Geolocator.distanceBetween(
            techProfile.latitude!,
            techProfile.longitude!,
            request.latitude!,
            request.longitude!,
          );
          _distanceKm = distance / 1000;
        }
      }

      setState(() {
        _request = request;
        _clientProfile = clientProfile;
        _technicianProfile = techProfile;
        _myQuotation = myQuotation;
        _hasQuotation = hasQuotation;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(context, 'Error al cargar solicitud');
      }
    }
  }

  Future<void> _completeWork() async {
    if (_request == null) return;

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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Confirmas que has completado este trabajo?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.payments_rounded, color: AppColors.success),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Precio: \$${_myQuotation?.estimatedPrice.toStringAsFixed(2) ?? "0.00"}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
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
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check_rounded),
            label: const Text('Sí, Completar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _requestsDS.completeService(_request!.id);

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          '¡Trabajo completado! El cliente puede dejar una reseña',
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error al completar trabajo');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _request == null
              ? const Center(child: Text('No se encontró la solicitud'))
              : CustomScrollView(
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
                                AppColors.info,
                                AppColors.info.withValues(alpha: 0.8),
                              ],
                            ),
                          ),
                        ),
                        title: const Text(
                          'Detalle de Solicitud',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        centerTitle: true,
                      ),
                    ),

                    // Contenido
                    SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _animationController,
                        child: Column(
                          children: [
                            const SizedBox(height: 16),

                            // Info Principal
                            _buildMainInfo(),
                            const SizedBox(height: 16),

                            // Cliente
                            _buildClientSection(),
                            const SizedBox(height: 16),

                            // Fotos
                            if (_request!.images != null &&
                                _request!.images!.isNotEmpty) ...[
                              _buildPhotosSection(),
                              const SizedBox(height: 16),
                            ],

                            // Mapa
                            _buildMapSection(),
                            const SizedBox(height: 16),

                            // Distancia
                            if (_distanceKm != null) _buildDistanceCard(),

                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: _buildActionButton(),
    );
  }

  Widget _buildMainInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getServiceIcon(_request!.serviceType),
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _request!.serviceType,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _request!.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _request!.description,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(_request!.createdAt),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientSection() {
    if (_clientProfile == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_rounded, color: AppColors.info, size: 20),
              SizedBox(width: 8),
              Text(
                'Cliente',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ProfileAvatar(
                name: _clientProfile!.fullName,
                imageUrl: _clientProfile!.profilePictureUrl,
                radius: 32,
                showBorder: true,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _clientProfile!.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (_clientProfile!.phone != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _clientProfile!.phone!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.call_rounded,
                  color: AppColors.success,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Fotos del Problema',
            icon: Icons.photo_library_rounded,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _request!.images!.length,
              itemBuilder: (context, index) {
                final imageUrl = _request!.images![index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
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

  Widget _buildMapSection() {
    if (_request!.latitude == null || _request!.longitude == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.medium,
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(_request!.latitude!, _request!.longitude!),
          initialZoom: 14,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.servicios_app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(_request!.latitude!, _request!.longitude!),
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.error,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.info.withValues(alpha: 0.15),
            AppColors.info.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.straighten_rounded,
              color: AppColors.info,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Distancia: ${_distanceKm!.toStringAsFixed(2)} km',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.info,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final canComplete = _hasQuotation &&
        _myQuotation?.status == 'accepted' &&
        (_request!.status == 'quotation_accepted' ||
            _request!.status == 'in_progress') &&
        _request!.status != 'completed' &&
        _request!.status != 'rated';

    final isCompleted = _request!.status == 'completed' || _request!.status == 'rated';

    if (_hasQuotation && _myQuotation != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getQuotationStatusColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getQuotationStatusColor(),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getQuotationStatusIcon(),
                      color: _getQuotationStatusColor(),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getQuotationStatusText(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _getQuotationStatusColor(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (canComplete) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _completeWork,
                    icon: const Icon(Icons.check_circle_rounded, size: 24),
                    label: const Text(
                      'Marcar como Completado',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SendQuotationPage(serviceRequest: _request!),
                ),
              ).then((sent) {
                if (sent == true && mounted) {
                  Navigator.pop(context, true);
                }
              });
            },
            icon: const Icon(Icons.send_rounded, size: 24),
            label: const Text(
              'Enviar Cotización',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getQuotationStatusColor() {
    switch (_myQuotation?.status) {
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  IconData _getQuotationStatusIcon() {
    switch (_myQuotation?.status) {
      case 'accepted':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.hourglass_empty_rounded;
    }
  }

  String _getQuotationStatusText() {
    if (_request!.status == 'completed' || _request!.status == 'rated') {
      return '✅ Trabajo Completado';
    }

    switch (_myQuotation?.status) {
      case 'accepted':
        return '🎉 ¡Cotización Aceptada!';
      case 'rejected':
        return 'Cotización Rechazada';
      default:
        return 'Cotización Enviada - Pendiente';
    }
  }

  IconData _getServiceIcon(String serviceType) {
    switch (serviceType) {
      case 'Electricista':
        return Icons.electrical_services_rounded;
      case 'Plomero':
        return Icons.plumbing_rounded;
      case 'Carpintero':
        return Icons.carpenter_rounded;
      case 'Pintor':
        return Icons.format_paint_rounded;
      case 'Mecánico':
        return Icons.build_circle_rounded;
      default:
        return Icons.handyman_rounded;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return 'Hace ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Hace ${diff.inHours} h';
    } else if (diff.inDays < 7) {
      return 'Hace ${diff.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}