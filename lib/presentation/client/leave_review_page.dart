import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../data/datasources/reviews_remote_ds.dart';
import '../../data/models/service_request_model.dart';
import '../../data/models/profile_model.dart';
import '../../core/utils/snackbar_helper.dart';

/// Pantalla para dejar reseña al técnico (Cliente)
/// Compatible con ratings detallados (punctuality, quality, communication)
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

class _LeaveReviewPageState extends State<LeaveReviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final ReviewsRemoteDataSource _reviewsDS = ReviewsRemoteDataSource();

  double _overallRating = 5.0;
  int _punctualityRating = 5;
  int _qualityRating = 5;
  int _communicationRating = 5;
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
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
      print('📤 [LEAVE_REVIEW] Enviando reseña');
      print('   Técnico: ${widget.technician.id}');
      print('   Rating general: $_overallRating');
      print('   Puntualidad: $_punctualityRating');
      print('   Calidad: $_qualityRating');
      print('   Comunicación: $_communicationRating');

      await _reviewsDS.createReview(
        serviceRequestId: widget.serviceRequest.id,
        rating: _overallRating,
        comment: _commentController.text.trim(),
        punctualityRating: _punctualityRating,
        qualityRating: _qualityRating,
        communicationRating: _communicationRating,
      );

      print('✅ [LEAVE_REVIEW] Reseña enviada exitosamente');

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          '¡Gracias por tu reseña!',
        );
        Navigator.pop(context, true); // Regresar con éxito
      }
    } catch (e) {
      print('❌ [LEAVE_REVIEW] Error: $e');
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'Error al enviar reseña',
        );
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
      appBar: AppBar(
        title: const Text('Dejar Reseña'),
        backgroundColor: Colors.blue,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info del técnico
            _buildTechnicianCard(),
            const SizedBox(height: 24),

            // Servicio realizado
            _buildServiceCard(),
            const SizedBox(height: 32),

            // Calificación general
            const Text(
              'Calificación General',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Center(
              child: RatingBar.builder(
                initialRating: _overallRating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 50,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  setState(() => _overallRating = rating);
                },
              ),
            ),

            const SizedBox(height: 8),

            Center(
              child: Text(
                _getRatingText(_overallRating),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _getRatingColor(_overallRating),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Ratings detallados
            const Text(
              'Calificaciones Específicas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildDetailedRating(
              'Puntualidad',
              Icons.schedule,
              _punctualityRating,
              (value) => setState(() => _punctualityRating = value.toInt()),
            ),

            const SizedBox(height: 16),

            _buildDetailedRating(
              'Calidad del Trabajo',
              Icons.verified,
              _qualityRating,
              (value) => setState(() => _qualityRating = value.toInt()),
            ),

            const SizedBox(height: 16),

            _buildDetailedRating(
              'Comunicación',
              Icons.chat_bubble,
              _communicationRating,
              (value) => setState(() => _communicationRating = value.toInt()),
            ),

            const SizedBox(height: 32),

            // Comentario
            const Text(
              'Cuéntanos tu experiencia',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _commentController,
              maxLines: 6,
              maxLength: 500,
              decoration: InputDecoration(
                hintText:
                    '¿Qué te pareció el trabajo? ¿Fue puntual? ¿El trabajo quedó bien hecho?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
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
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 32),

            // Botón enviar
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitReview,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, size: 24),
              label: Text(
                _isLoading ? 'Enviando...' : 'Enviar Reseña',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Nota
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tu reseña ayuda a otros clientes a elegir al mejor técnico',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
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
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue,
              backgroundImage: widget.technician.profilePictureUrl != null
                  ? NetworkImage(widget.technician.profilePictureUrl!)
                  : null,
              child: widget.technician.profilePictureUrl == null
                  ? Text(
                      widget.technician.fullName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              widget.technician.fullName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.technician.averageRating != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.technician.averageRating!.toStringAsFixed(1)} ',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '(${widget.technician.totalReviews ?? 0} reseñas)',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.build, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Servicio Realizado',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.serviceRequest.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.serviceRequest.description,
              style: TextStyle(color: Colors.grey[700]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedRating(
    String label,
    IconData icon,
    int value,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: '$value',
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$value',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getRatingText(double rating) {
    if (rating >= 4.5) return 'Excelente ⭐';
    if (rating >= 3.5) return 'Muy Bueno 👍';
    if (rating >= 2.5) return 'Bueno';
    if (rating >= 1.5) return 'Regular';
    return 'Malo';
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 3.5) return Colors.blue;
    if (rating >= 2.5) return Colors.orange;
    return Colors.red;
  }
}