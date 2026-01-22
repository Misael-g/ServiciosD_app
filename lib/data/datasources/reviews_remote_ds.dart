import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../models/review_model.dart';

/// Fuente de datos remota para reseñas
class ReviewsRemoteDataSource {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Crear reseña
  Future<ReviewModel> createReview({
    required String technicianId,
    required String serviceRequestId,
    required double rating,
    required String comment,
  }) async {
    try {
      final clientId = SupabaseConfig.currentUserId;
      if (clientId == null) {
        throw Exception('No hay cliente autenticado');
      }

      print('📤 [REVIEWS_DS] Creando reseña');
      print('   Cliente: $clientId');
      print('   Técnico: $technicianId');
      print('   Rating: $rating');
      print('   Solicitud: $serviceRequestId');

      final response = await _supabase.from('reviews').insert({
        'client_id': clientId,
        'technician_id': technicianId,
        'service_request_id': serviceRequestId,
        'rating': rating,
        'comment': comment,
      }).select().single();

      print('✅ [REVIEWS_DS] Reseña creada: ${response['id']}');

      return ReviewModel.fromJson(response);
    } catch (e, stackTrace) {
      print('❌ [REVIEWS_DS] Error al crear reseña:');
      print('   Error: $e');
      print('   StackTrace: $stackTrace');
      throw Exception('Error al crear reseña: $e');
    }
  }

  /// Obtener reseñas de un técnico
  Future<List<ReviewModel>> getReviewsByTechnician(String technicianId) async {
    try {
      print('🔵 [REVIEWS_DS] Obteniendo reseñas del técnico: $technicianId');

      final response = await _supabase
          .from('reviews')
          .select()
          .eq('technician_id', technicianId)
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
          .eq('client_id', clientId)
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
          .eq('client_id', clientId)
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