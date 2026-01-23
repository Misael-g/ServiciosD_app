import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final ServiceRequestsRemoteDataSource _requestsDS = ServiceRequestsRemoteDataSource();
  final ProfilesRemoteDataSource _profilesDS = ProfilesRemoteDataSource();
  final QuotationsRemoteDataSource _quotationsDS = QuotationsRemoteDataSource();

  ServiceRequestModel? _request;
  ProfileModel? _clientProfile;
  ProfileModel? _technicianProfile;
  QuotationModel? _myQuotation;
  bool _isLoading = true;
  bool _hasQuotation = false;
  double? _distanceKm;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
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

  void _navigateToSendQuotation() {
    if (_request == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SendQuotationPage(
          serviceRequest: _request!,
        ),
      ),
    ).then((sent) {
      if (sent == true && mounted) {
        Navigator.pop(context, true);
      }
    });
  }

  Future<void> _callPhone(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    try {
      if (!await launchUrl(url)) {
        if (mounted) {
          SnackbarHelper.showError(context, 'No se pudo abrir el teléfono');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error al realizar la llamada');
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
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 32),
            SizedBox(width: 12),
            Text(
              'Completar Trabajo',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Confirmas que has completado este trabajo?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.info.withOpacity(0.1),
                    AppColors.info.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.info.withOpacity(0.3),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppColors.info, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Al marcar como completado:',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text('• El cliente será notificado'),
                  Text('• Podrá verificar el trabajo'),
                  Text('• Podrá dejar una reseña'),
                  Text('• Se incrementarán tus trabajos completados'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.success.withOpacity(0.15),
                    AppColors.success.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payments_rounded, color: AppColors.success, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Precio acordado: \$${_myQuotation?.estimatedPrice.toStringAsFixed(2) ?? "0.00"}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: AppColors.success,
                      ),
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
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check_rounded),
            label: const Text('Sí, Completar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
        SnackbarHelper.showError(
          context,
          'Error al completar trabajo: ${e.toString().replaceAll("Exception: ", "")}',
        );
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
                    // AppBar con Hero Image
                    _buildSliverAppBar(),

                    // Contenido
                    SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            children: [
                              // Header con info principal
                              _buildHeaderSection(),
                              const SizedBox(height: 16),

                              // Cliente Card
                              _buildClientCard(),
                              const SizedBox(height: 16),

                              // Distancia Badge
                              if (_distanceKm != null) _buildDistanceBadge(),
                              if (_distanceKm != null) const SizedBox(height: 16),

                              // Galería de fotos
                              if (_request!.images != null && _request!.images!.isNotEmpty) ...[
                                _buildPhotoGallery(),
                                const SizedBox(height: 16),
                              ],

                              // Mapa
                              _buildMapSection(),
                              const SizedBox(height: 120),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
      // Botón de acción flotante
      bottomNavigationBar: _isLoading ? null : _buildActionButton(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.success,
                    AppColors.success.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            // Pattern overlay
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: Image.asset(
                  'assets/pattern.png',
                  repeat: ImageRepeat.repeat,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),
            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getServiceIcon(_request!.serviceType),
                            color: AppColors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _request!.serviceType,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _request!.title,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Descripción
          const Row(
            children: [
              Icon(Icons.description_rounded, color: AppColors.secondary, size: 20),
              SizedBox(width: 8),
              Text(
                'Descripción',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _request!.description,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
          // Fecha
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.info,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fecha de solicitud',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(_request!.createdAt),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard() {
    if (_clientProfile == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.primary.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Cliente',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Avatar con border gradient
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.6),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(3),
                child: ProfileAvatar(
                  name: _clientProfile!.fullName,
                  imageUrl: _clientProfile!.profilePictureUrl,
                  radius: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _clientProfile!.fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (_clientProfile!.phone != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.phone_rounded,
                              size: 16,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _clientProfile!.phone!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Botón de llamar
              if (_clientProfile!.phone != null)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.success,
                        AppColors.success.withOpacity(0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _callPhone(_clientProfile!.phone!),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        child: const Icon(
                          Icons.phone_rounded,
                          color: AppColors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceBadge() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warning.withOpacity(0.15),
            AppColors.warning.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.warning,
                  AppColors.warning.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.near_me_rounded,
              color: AppColors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Distancia estimada',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_distanceKm!.toStringAsFixed(2)} km',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.warning,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.directions_car_rounded,
                  size: 16,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 4),
                Text(
                  '~${(_distanceKm! * 2).toInt()} min',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.photo_library_rounded, color: AppColors.secondary, size: 20),
              SizedBox(width: 8),
              Text(
                'Fotos del Problema',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _request!.images!.length,
            itemBuilder: (context, index) {
              final imageUrl = _request!.images![index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Hero(
                  tag: 'request_image_$index',
                  child: GestureDetector(
                    onTap: () => _viewImageFullscreen(imageUrl, index),
                    child: Container(
                      width: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppShadows.medium,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.background,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.background,
                              child: const Icon(
                                Icons.broken_image_rounded,
                                color: AppColors.error,
                                size: 48,
                              ),
                            ),
                          ),
                          // Overlay gradient
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.4),
                                ],
                              ),
                            ),
                          ),
                          // Número de foto
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.image_rounded,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${index + 1}/${_request!.images!.length}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildMapSection() {
    if (_request!.latitude == null || _request!.longitude == null) {
      return const SizedBox.shrink();
    }

    final requestLocation = LatLng(_request!.latitude!, _request!.longitude!);
    LatLng? technicianLocation;
    if (_technicianProfile?.latitude != null && _technicianProfile?.longitude != null) {
      technicianLocation = LatLng(
        _technicianProfile!.latitude!,
        _technicianProfile!.longitude!,
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.large,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del mapa
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.info,
                  AppColors.info.withOpacity(0.8),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.map_rounded,
                    color: AppColors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ubicación',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Ubicación exacta del servicio',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Mapa
          SizedBox(
            height: 300,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: requestLocation,
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.servicios_app',
                ),
                MarkerLayer(
                  markers: [
                    // Marcador solicitud
                    Marker(
                      point: requestLocation,
                      width: 80,
                      height: 80,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: AppShadows.small,
                            ),
                            child: const Text(
                              'Cliente',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.error,
                            size: 40,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Marcador técnico
                    if (technicianLocation != null)
                      Marker(
                        point: technicianLocation,
                        width: 80,
                        height: 80,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.success,
                                    AppColors.success.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: AppShadows.small,
                              ),
                              child: const Text(
                                'Tú',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Icon(
                              Icons.my_location_rounded,
                              color: AppColors.success,
                              size: 40,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Dirección
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.white,
            child: Row(
              children: [
                const Icon(
                  Icons.place_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _request!.address ?? 'Dirección no disponible',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final canComplete = _hasQuotation &&
        _myQuotation?.status == 'accepted' &&
        (_request!.status == 'quotation_accepted' || _request!.status == 'in_progress') &&
        _request!.status != 'completed' &&
        _request!.status != 'rated';

    final isCompleted = _request!.status == 'completed' || _request!.status == 'rated';

    // Si ya envió cotización
    if (_hasQuotation && _myQuotation != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Estado de cotización
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getQuotationStatusColor().withOpacity(0.15),
                      _getQuotationStatusColor().withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getQuotationStatusColor().withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getQuotationStatusColor(),
                            _getQuotationStatusColor().withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _getQuotationStatusColor().withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getQuotationStatusIcon(),
                        color: AppColors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getQuotationStatusText(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _getQuotationStatusColor(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Botón de completar
              if (canComplete) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _completeWork,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      shadowColor: AppColors.success.withOpacity(0.3),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'Marcar como Completado',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Mensaje si completado
              if (isCompleted) ...[
                const SizedBox(height: 16),
                InfoCard(
                  message: '✅ Trabajo completado. Esperando reseña del cliente.',
                  icon: Icons.done_all_rounded,
                  color: AppColors.info,
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Botón para enviar cotización
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _navigateToSendQuotation,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              shadowColor: AppColors.success.withOpacity(0.3),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send_rounded, size: 28),
                SizedBox(width: 12),
                Text(
                  'Enviar Cotización',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _viewImageFullscreen(String imageUrl, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppColors.white),
            title: Text(
              'Foto ${index + 1} de ${_request!.images!.length}',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: Center(
            child: Hero(
              tag: 'request_image_$index',
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                    ),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_rounded,
                          color: AppColors.white,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Error al cargar imagen',
                          style: TextStyle(color: AppColors.white),
                        ),
                      ],
                    ),
                  ),
                ),
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
        return Icons.hourglass_bottom_rounded;
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
        return 'Cotización Enviada';
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
      case 'Jardinero':
        return Icons.grass_rounded;
      case 'Limpieza':
        return Icons.cleaning_services_rounded;
      default:
        return Icons.handyman_rounded;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}