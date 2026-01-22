import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../models/review_model.dart';

/// Fuente de datos remota para reseñas
/// Compatible con schema existente (reviewer_id, reviewed_id)
class ReviewsRemoteDataSource {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Crear reseña usando función RPC
  Future<void> createReview({
    required String serviceRequestId,
    required double rating,
    required String comment,
    int? punctualityRating,
    int? qualityRating,
    int? communicationRating,
  }) async {
    try {
      final clientId = SupabaseConfig.currentUserId;
      if (clientId == null) {
        throw Exception('No hay cliente autenticado');
      }

      print('📤 [REVIEWS_DS] Creando reseña');
      print('   Cliente: $clientId');
      print('   Rating: $rating');
      print('   Solicitud: $serviceRequestId');

      // Usar función RPC que maneja todo automáticamente
      await _supabase.rpc('create_review', params: {
        'p_service_request_id': serviceRequestId,
        'p_rating': rating,
        'p_comment': comment,
        'p_punctuality_rating': punctualityRating,
        'p_quality_rating': qualityRating,
        'p_communication_rating': communicationRating,
      });

      print('✅ [REVIEWS_DS] Reseña creada exitosamente');
    } catch (e, stackTrace) {
      print('❌ [REVIEWS_DS] Error al crear reseña:');
      print('   Error: $e');
      print('   StackTrace: $stackTrace');
      throw Exception('Error al crear reseña: $e');
    }
  }

  /// Obtener reseñas de un técnico (reviewed_id)
  Future<List<ReviewModel>> getReviewsByTechnician(String technicianId) async {
    try {
      print('🔵 [REVIEWS_DS] Obteniendo reseñas del técnico: $technicianId');

      final response = await _supabase
          .from('reviews')
          .select()
          .eq('reviewed_id', technicianId)  // ← reviewed_id es el técnico
          .order('created_at', ascending: false);

      final reviews = (response as List)
          .map((json) => ReviewModel.fromJson(json as Map<String, dynamic>))
          .toList();

      print('✅ [REVIEWS_DS] ${reviews.length} reseñas encontradas');

      return reviews;
    } catch (e, stackTrace) {
      print('❌ [REVIEWS_DS] Error al obtener reseñas:');
      print('   Error: $e');
      print('   StackTrace: $stackTrace');
      throw Exception('Error al obtener reseñas: $e');
    }
  }

  /// Verificar si el cliente ya dejó reseña para esta solicitud
  Future<bool> hasReviewForRequest(String serviceRequestId) async {
    try {
      final clientId = SupabaseConfig.currentUserId;
      if (clientId == null) return false;

      print('🔵 [REVIEWS_DS] Verificando reseña existente');
      print('   Cliente: $clientId');
      print('   Solicitud: $serviceRequestId');

      final response = await _supabase
          .from('reviews')
          .select('id')
          .eq('service_request_id', serviceRequestId)
          .eq('reviewer_id', clientId)  // ← reviewer_id es el cliente
          .maybeSingle();

      final exists = response != null;
      print(exists ? '✅ Ya tiene reseña' : '✅ No tiene reseña');

      return exists;
    } catch (e) {
      print('❌ [REVIEWS_DS] Error al verificar: $e');
      return false;
    }
  }

  /// Obtener reseña del cliente para una solicitud
  Future<ReviewModel?> getMyReviewForRequest(String serviceRequestId) async {
    try {
      final clientId = SupabaseConfig.currentUserId;
      if (clientId == null) return null;

      print('🔵 [REVIEWS_DS] Obteniendo mi reseña');
      print('   Cliente: $clientId');
      print('   Solicitud: $serviceRequestId');

      final response = await _supabase
          .from('reviews')
          .select()
          .eq('service_request_id', serviceRequestId)
          .eq('reviewer_id', clientId)  // ← reviewer_id es el cliente
          .maybeSingle();

      if (response == null) {
        print('✅ No hay reseña');
        return null;
      }

      print('✅ Reseña encontrada: ${response['id']}');
      return ReviewModel.fromJson(response);
    } catch (e) {
      print('❌ [REVIEWS_DS] Error: $e');
      return null;
    }
  }
}