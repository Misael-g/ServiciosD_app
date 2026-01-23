import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../data/datasources/reviews_remote_ds.dart';
import '../../data/models/service_request_model.dart';
import '../../data/models/profile_model.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_widgets.dart';

class LeaveReviewPage extends StatefulWidget {
  final ServiceRequestModel serviceRequest;
  final ProfileModel technician;

  const LeaveReviewPage({
    super.key,
    required this.serviceRequest,
    required this.technician,
  });

  @override
  State<LeaveReviewPage> createState() => _LeaveReviewPageState();
}

class _LeaveReviewPageState extends State<LeaveReviewPage> 
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final ReviewsRemoteDataSource _reviewsDS = ReviewsRemoteDataSource();

  double _overallRating = 5.0;
  int _punctualityRating = 5;
  int _qualityRating = 5;
  int _communicationRating = 5;
  bool _isLoading = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    if (_overallRating < 1) {
      SnackbarHelper.showError(context, 'Debes dar al menos 1 estrella');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _reviewsDS.createReview(
        serviceRequestId: widget.serviceRequest.id,
        rating: _overallRating,
        comment: _commentController.text.trim(),
        punctualityRating: _punctualityRating,
        qualityRating: _qualityRating,
        communicationRating: _communicationRating,
      );

      if (mounted) {
        SnackbarHelper.showSuccess(context, '¡Gracias por tu reseña!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error al enviar reseña');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dejar Reseña'),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _animationController,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Técnico card
              _buildTechnicianCard(),
              const SizedBox(height: 24),

              // Servicio
              _buildServiceCard(),
              const SizedBox(height: 32),

              // Rating general
              const SectionHeader(
                title: 'Calificación General',
                icon: Icons.star_rounded,
              ),
              const SizedBox(height: 20),

              Center(
                child: Column(
                  children: [
                    RatingBar.builder(
                      initialRating: _overallRating,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemSize: 56,
                      itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                      glowColor: AppColors.warning.withValues(alpha: 0.3),
                      itemBuilder: (context, _) => const Icon(
                        Icons.star_rounded,
                        color: AppColors.warning,
                      ),
                      onRatingUpdate: (rating) {
                        setState(() => _overallRating = rating);
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getRatingColor(_overallRating).withValues(alpha: 0.15),
                            _getRatingColor(_overallRating).withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getRatingColor(_overallRating).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getRatingIcon(_overallRating),
                            color: _getRatingColor(_overallRating),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _getRatingText(_overallRating),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _getRatingColor(_overallRating),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Ratings detallados
              const SectionHeader(
                title: 'Calificaciones Específicas',
                icon: Icons.checklist_rounded,
              ),
              const SizedBox(height: 16),

              _buildDetailedRating(
                'Puntualidad',
                Icons.schedule_rounded,
                _punctualityRating,
                AppColors.info,
                (value) => setState(() => _punctualityRating = value.toInt()),
              ),

              const SizedBox(height: 16),

              _buildDetailedRating(
                'Calidad del Trabajo',
                Icons.verified_rounded,
                _qualityRating,
                AppColors.success,
                (value) => setState(() => _qualityRating = value.toInt()),
              ),

              const SizedBox(height: 16),

              _buildDetailedRating(
                'Comunicación',
                Icons.chat_bubble_rounded,
                _communicationRating,
                AppColors.warning,
                (value) => setState(() => _communicationRating = value.toInt()),
              ),

              const SizedBox(height: 32),

              // Comentario
              const SectionHeader(
                title: 'Cuéntanos tu experiencia',
                icon: Icons.edit_note_rounded,
              ),

              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.small,
                ),
                child: TextFormField(
                  controller: _commentController,
                  maxLines: 6,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    hintText: '¿Qué te pareció el trabajo? ¿Fue puntual? ¿El trabajo quedó bien hecho?',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(20),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor escribe un comentario';
                    }
                    if (value.trim().length < 20) {
                      return 'El comentario debe tener al menos 20 caracteres';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Botón enviar
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.white,
                            ),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'Enviar Reseña',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Nota
              InfoCard(
                message: 'Tu reseña ayuda a otros clientes a elegir al mejor técnico',
                icon: Icons.info_rounded,
                color: AppColors.info,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTechnicianCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.medium,
      ),
      child: Column(
        children: [
          ProfileAvatar(
            name: widget.technician.fullName,
            imageUrl: widget.technician.profilePictureUrl,
            radius: 50,
            showBorder: true,
          ),
          const SizedBox(height: 16),
          Text(
            widget.technician.fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.technician.averageRating != null) ...[
            const SizedBox(height: 12),
            RatingDisplay(
              rating: widget.technician.averageRating!,
              totalReviews: widget.technician.totalReviews ?? 0,
              size: 20,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.build_circle_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Servicio Realizado',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.serviceRequest.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.serviceRequest.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedRating(
    String label,
    IconData icon,
    int value,
    Color color,
    Function(double) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: color,
                    inactiveTrackColor: color.withValues(alpha: 0.2),
                    thumbColor: color,
                    overlayColor: color.withValues(alpha: 0.2),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: value.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    onChanged: onChanged,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.15),
                      color.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getRatingText(double rating) {
    if (rating >= 4.5) return 'Excelente ⭐';
    if (rating >= 3.5) return 'Muy Bueno 👍';
    if (rating >= 2.5) return 'Bueno';
    if (rating >= 1.5) return 'Regular';
    return 'Malo';
  }

  IconData _getRatingIcon(double rating) {
    if (rating >= 4.5) return Icons.emoji_emotions_rounded;
    if (rating >= 3.5) return Icons.sentiment_satisfied_rounded;
    if (rating >= 2.5) return Icons.sentiment_neutral_rounded;
    return Icons.sentiment_dissatisfied_rounded;
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return AppColors.success;
    if (rating >= 3.5) return AppColors.info;
    if (rating >= 2.5) return AppColors.warning;
    return AppColors.error;
  }
}