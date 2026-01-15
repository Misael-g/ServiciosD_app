import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../models/quotation_model.dart';

class QuotationsRemoteDataSource {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Crear cotización (Técnico)
  Future<QuotationModel> createQuotation({
    required String serviceRequestId,
    required double estimatedPrice,
    required int estimatedDuration,
    required String description,
  }) async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw Exception('No hay usuario autenticado');
      }

      final response = await _supabase
          .from('quotations')
          .insert({
            'service_request_id': serviceRequestId,
            'technician_id': userId,
            'estimated_price': estimatedPrice,
            'estimated_duration': estimatedDuration,
            'description': description,
            'status': 'pending',
          })
          .select()
          .single();

      // Actualizar estado de la solicitud
      await _supabase
          .from('service_requests')
          .update({'status': 'quotation_sent'})
          .eq('id', serviceRequestId);

      return QuotationModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear cotización: $e');
    }
  }

  /// Obtener cotizaciones de una solicitud
  Future<List<QuotationModel>> getQuotationsByRequest(
    String serviceRequestId,
  ) async {
    try {
      final response = await _supabase
          .from('quotations')
          .select()
          .eq('service_request_id', serviceRequestId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => QuotationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener cotizaciones: $e');
    }
  }

  /// Aceptar cotización (Cliente)
  Future<QuotationModel> acceptQuotation(String quotationId) async {
    try {
      // Obtener la cotización para saber el service_request_id y technician_id
      final quotation = await _supabase
          .from('quotations')
          .select()
          .eq('id', quotationId)
          .single();

      // Actualizar cotización a accepted
      await _supabase
          .from('quotations')
          .update({'status': 'accepted'})
          .eq('id', quotationId);

      // Rechazar las demás cotizaciones
      await _supabase
          .from('quotations')
          .update({'status': 'rejected'})
          .eq('service_request_id', quotation['service_request_id'])
          .neq('id', quotationId);

      // Asignar técnico a la solicitud
      await _supabase
          .from('service_requests')
          .update({
            'assigned_technician_id': quotation['technician_id'],
            'assigned_at': DateTime.now().toIso8601String(),
            'status': 'quotation_accepted',
          })
          .eq('id', quotation['service_request_id']);

      final updated = await _supabase
          .from('quotations')
          .select()
          .eq('id', quotationId)
          .single();

      return QuotationModel.fromJson(updated);
    } catch (e) {
      throw Exception('Error al aceptar cotización: $e');
    }
  }

  /// Rechazar cotización (Cliente)
  Future<QuotationModel> rejectQuotation(String quotationId) async {
    try {
      final response = await _supabase
          .from('quotations')
          .update({'status': 'rejected'})
          .eq('id', quotationId)
          .select()
          .single();

      return QuotationModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al rechazar cotización: $e');
    }
  }
}