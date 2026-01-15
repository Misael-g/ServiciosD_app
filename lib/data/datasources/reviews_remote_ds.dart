import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../models/review_model.dart';

class ReviewsRemoteDataSource {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Crear reseña
  Future<ReviewModel> createReview({
    required String serviceRequestId,
    required String reviewedId,
    required int rating,
    int? punctualityRating,
    int? qualityRating,
    int? communicationRating,
    String? comment,
  }) async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw Exception('No hay usuario autenticado');
      }

      final response = await _supabase
          .from('reviews')
          .insert({
            'service_request_id': serviceRequestId,
            'reviewer_id': userId,
            'reviewed_id': reviewedId,
            'rating': rating,
            'punctuality_rating': punctualityRating,
            'quality_rating': qualityRating,
            'communication_rating': communicationRating,
            'comment': comment,
          })
          .select()
          .single();

      // Verificar si ambas partes ya calificaron
      final reviews = await _supabase
          .from('reviews')
          .select()
          .eq('service_request_id', serviceRequestId);

      if (reviews.length == 2) {
        // Ambas partes calificaron, actualizar estado a 'rated'
        await _supabase
            .from('service_requests')
            .update({'status': 'rated'})
            .eq('id', serviceRequestId);
      }

      return ReviewModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear reseña: $e');
    }
  }

  /// Obtener reseñas de un usuario
  Future<List<ReviewModel>> getReviewsByUser(String userId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('reviewed_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ReviewModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener reseñas: $e');
    }
  }
}