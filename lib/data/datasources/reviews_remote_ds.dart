import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../models/review_model.dart';

/// Fuente de datos remota para reseñas
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

  /// Obtener reseñas de un usuario (las que ha recibido)
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

  /// Obtener reseñas que un usuario ha hecho
  Future<List<ReviewModel>> getReviewsByReviewer(String reviewerId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('reviewer_id', reviewerId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ReviewModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener reseñas hechas: $e');
    }
  }

  /// Obtener reseñas de una solicitud de servicio
  Future<List<ReviewModel>> getReviewsByServiceRequest(
    String serviceRequestId,
  ) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('service_request_id', serviceRequestId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ReviewModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener reseñas del servicio: $e');
    }
  }

  /// Obtener reseña por ID
  Future<ReviewModel> getReviewById(String reviewId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('id', reviewId)
          .single();

      return ReviewModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener reseña: $e');
    }
  }

  /// Actualizar reseña (solo en las primeras 24 horas)
  Future<ReviewModel> updateReview({
    required String reviewId,
    required int rating,
    int? punctualityRating,
    int? qualityRating,
    int? communicationRating,
    String? comment,
  }) async {
    try {
      final response = await _supabase
          .from('reviews')
          .update({
            'rating': rating,
            'punctuality_rating': punctualityRating,
            'quality_rating': qualityRating,
            'communication_rating': communicationRating,
            'comment': comment,
          })
          .eq('id', reviewId)
          .select()
          .single();

      return ReviewModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar reseña: $e');
    }
  }

  /// Verificar si un usuario ya calificó un servicio
  Future<bool> hasUserReviewedService({
    required String serviceRequestId,
    String? userId,
  }) async {
    try {
      final reviewerId = userId ?? SupabaseConfig.currentUserId;
      if (reviewerId == null) return false;

      final response = await _supabase
          .from('reviews')
          .select()
          .eq('service_request_id', serviceRequestId)
          .eq('reviewer_id', reviewerId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Obtener mi reseña para un servicio
  Future<ReviewModel?> getMyReviewForService(String serviceRequestId) async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) return null;

      final response = await _supabase
          .from('reviews')
          .select()
          .eq('service_request_id', serviceRequestId)
          .eq('reviewer_id', userId)
          .maybeSingle();

      if (response == null) return null;

      return ReviewModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Eliminar reseña (normalmente no permitido)
  Future<void> deleteReview(String reviewId) async {
    try {
      await _supabase.from('reviews').delete().eq('id', reviewId);
    } catch (e) {
      throw Exception('Error al eliminar reseña: $e');
    }
  }

  /// Obtener estadísticas de reseñas de un usuario
  Future<Map<String, dynamic>> getReviewStats(String userId) async {
    try {
      final reviews = await getReviewsByUser(userId);

      if (reviews.isEmpty) {
        return {
          'total': 0,
          'average': 0.0,
          'averagePunctuality': 0.0,
          'averageQuality': 0.0,
          'averageCommunication': 0.0,
        };
      }

      final total = reviews.length;
      final avgRating = reviews
              .map((r) => r.rating)
              .reduce((a, b) => a + b) /
          total;

      final punctualityRatings = reviews
          .where((r) => r.punctualityRating != null)
          .map((r) => r.punctualityRating!)
          .toList();

      final qualityRatings = reviews
          .where((r) => r.qualityRating != null)
          .map((r) => r.qualityRating!)
          .toList();

      final communicationRatings = reviews
          .where((r) => r.communicationRating != null)
          .map((r) => r.communicationRating!)
          .toList();

      return {
        'total': total,
        'average': avgRating,
        'averagePunctuality': punctualityRatings.isEmpty
            ? 0.0
            : punctualityRatings.reduce((a, b) => a + b) /
                punctualityRatings.length,
        'averageQuality': qualityRatings.isEmpty
            ? 0.0
            : qualityRatings.reduce((a, b) => a + b) / qualityRatings.length,
        'averageCommunication': communicationRatings.isEmpty
            ? 0.0
            : communicationRatings.reduce((a, b) => a + b) /
                communicationRatings.length,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }
}