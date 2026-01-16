import '../../domain/entities/quotation.dart';
import '../datasources/quotations_remote_ds.dart';

/// Implementación del repositorio de cotizaciones
/// 
/// Nota: No tiene interfaz en domain/repositories porque no se definió previamente
/// Este repositorio actúa como capa adicional sobre el datasource
class QuotationsRepositoryImpl {
  final QuotationsRemoteDataSource _remoteDataSource;

  QuotationsRepositoryImpl(this._remoteDataSource);

  Future<Quotation> createQuotation({
    required String serviceRequestId,
    required double estimatedPrice,
    required int estimatedDuration,
    required String description,
  }) async {
    try {
      final quotationModel = await _remoteDataSource.createQuotation(
        serviceRequestId: serviceRequestId,
        estimatedPrice: estimatedPrice,
        estimatedDuration: estimatedDuration,
        description: description,
      );
      return quotationModel.toEntity();
    } catch (e) {
      throw Exception('Error al crear cotización: $e');
    }
  }

  Future<List<Quotation>> getQuotationsByRequest(String serviceRequestId) async {
    try {
      final quotationModels =
          await _remoteDataSource.getQuotationsByRequest(serviceRequestId);
      return quotationModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Error al obtener cotizaciones: $e');
    }
  }

  Future<Quotation> acceptQuotation(String quotationId) async {
    try {
      final quotationModel = await _remoteDataSource.acceptQuotation(quotationId);
      return quotationModel.toEntity();
    } catch (e) {
      throw Exception('Error al aceptar cotización: $e');
    }
  }

  Future<Quotation> rejectQuotation(String quotationId) async {
    try {
      final quotationModel = await _remoteDataSource.rejectQuotation(quotationId);
      return quotationModel.toEntity();
    } catch (e) {
      throw Exception('Error al rechazar cotización: $e');
    }
  }

  Future<List<Quotation>> getMyQuotations() async {
    try {
      final quotationModels = await _remoteDataSource.getMyQuotations();
      return quotationModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Error al obtener mis cotizaciones: $e');
    }
  }
}