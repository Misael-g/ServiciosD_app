import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/constants/verification_states.dart';

/// Fuente de datos remota para Storage de Supabase
class StorageRemoteDataSource {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Nombres de buckets
  static const String verificationDocsBucket = 'verification-docs';
  static const String portfolioBucket = 'portfolio-images';
  static const String serviceImagesBucket = 'service-images';
  static const String profilePicturesBucket = 'profile-pictures';

  /// Subir documento de verificación
  /// 
  /// [technicianId] - ID del técnico
  /// [documentType] - Tipo de documento (id_front, id_back, certificate)
  /// [file] - Archivo a subir
  Future<String> uploadVerificationDocument({
    required String technicianId,
    required String documentType,
    required File file,
  }) async {
    try {
      // Validar tipo de documento
      if (!DocumentTypes.allTypes.contains(documentType)) {
        throw Exception('Tipo de documento inválido');
      }

      final extension = file.path.split('.').last;
      final fileName = '$documentType.$extension';
      final path = '$technicianId/$fileName';

      // Subir archivo
      await _supabase.storage
          .from(verificationDocsBucket)
          .upload(path, file, fileOptions: const FileOptions(upsert: true));

      // Obtener URL del archivo
      final url = _supabase.storage
          .from(verificationDocsBucket)
          .getPublicUrl(path);

      return url;
    } catch (e) {
      throw Exception('Error al subir documento: $e');
    }
  }

  /// Obtener URL de documento de verificación
  Future<String> getVerificationDocumentUrl({
    required String technicianId,
    required String documentType,
  }) async {
    try {
      // Buscar archivos en la carpeta del técnico
      final files = await _supabase.storage
          .from(verificationDocsBucket)
          .list(path: technicianId);

      // Buscar archivo que empiece con el tipo de documento
      final file = files.firstWhere(
        (f) => f.name.startsWith(documentType),
        orElse: () => throw Exception('Documento no encontrado'),
      );

      final path = '$technicianId/${file.name}';

      // Para documentos privados, usar signed URL
      final url = await _supabase.storage
          .from(verificationDocsBucket)
          .createSignedUrl(path, 3600); // 1 hora

      return url;
    } catch (e) {
      throw Exception('Error al obtener URL del documento: $e');
    }
  }

  /// Eliminar documento de verificación
  Future<void> deleteVerificationDocument({
    required String technicianId,
    required String documentType,
  }) async {
    try {
      final files = await _supabase.storage
          .from(verificationDocsBucket)
          .list(path: technicianId);

      final file = files.firstWhere(
        (f) => f.name.startsWith(documentType),
        orElse: () => throw Exception('Documento no encontrado'),
      );

      final path = '$technicianId/${file.name}';

      await _supabase.storage
          .from(verificationDocsBucket)
          .remove([path]);
    } catch (e) {
      throw Exception('Error al eliminar documento: $e');
    }
  }

  /// Subir imagen al portafolio
  Future<String> uploadPortfolioImage({
    required String technicianId,
    required File file,
    String? description,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.path.split('.').last;
      final fileName = 'work_$timestamp.$extension';
      final path = '$technicianId/$fileName';

      await _supabase.storage
          .from(portfolioBucket)
          .upload(path, file);

      // URL pública (el bucket es público)
      final url = _supabase.storage
          .from(portfolioBucket)
          .getPublicUrl(path);

      return url;
    } catch (e) {
      throw Exception('Error al subir imagen al portafolio: $e');
    }
  }

  /// Obtener imágenes del portafolio
  Future<List<String>> getPortfolioImages(String technicianId) async {
    try {
      final files = await _supabase.storage
          .from(portfolioBucket)
          .list(path: technicianId);

      return files.map((file) {
        final path = '$technicianId/${file.name}';
        return _supabase.storage
            .from(portfolioBucket)
            .getPublicUrl(path);
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener imágenes del portafolio: $e');
    }
  }

  /// Eliminar imagen del portafolio
  Future<void> deletePortfolioImage({
    required String technicianId,
    required String fileName,
  }) async {
    try {
      final path = '$technicianId/$fileName';

      await _supabase.storage
          .from(portfolioBucket)
          .remove([path]);
    } catch (e) {
      throw Exception('Error al eliminar imagen del portafolio: $e');
    }
  }

  /// Subir imagen de servicio
  Future<String> uploadServiceImage({
    required String serviceRequestId,
    required File file,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.path.split('.').last;
      final fileName = 'image_$timestamp.$extension';
      final path = '$serviceRequestId/$fileName';

      await _supabase.storage
          .from(serviceImagesBucket)
          .upload(path, file);

      final url = await _supabase.storage
          .from(serviceImagesBucket)
          .createSignedUrl(path, 3600 * 24); // 24 horas

      return url;
    } catch (e) {
      throw Exception('Error al subir imagen del servicio: $e');
    }
  }

  /// Subir foto de perfil
  Future<String> uploadProfilePicture({
    required String userId,
    required File file,
  }) async {
    try {
      final extension = file.path.split('.').last;
      final fileName = 'avatar.$extension';
      final path = '$userId/$fileName';

      await _supabase.storage
          .from(profilePicturesBucket)
          .upload(path, file, fileOptions: const FileOptions(upsert: true));

      // URL pública (el bucket es público)
      final url = _supabase.storage
          .from(profilePicturesBucket)
          .getPublicUrl(path);

      return url;
    } catch (e) {
      throw Exception('Error al subir foto de perfil: $e');
    }
  }

  /// Eliminar foto de perfil
  Future<void> deleteProfilePicture(String userId) async {
    try {
      final files = await _supabase.storage
          .from(profilePicturesBucket)
          .list(path: userId);

      if (files.isEmpty) return;

      final paths = files.map((f) => '$userId/${f.name}').toList();

      await _supabase.storage
          .from(profilePicturesBucket)
          .remove(paths);
    } catch (e) {
      throw Exception('Error al eliminar foto de perfil: $e');
    }
  }

  /// Verificar si un documento existe
  Future<bool> documentExists({
    required String bucket,
    required String path,
  }) async {
    try {
      final folder = path.split('/').first;
      final fileName = path.split('/').last;

      final files = await _supabase.storage
          .from(bucket)
          .list(path: folder);

      return files.any((f) => f.name == fileName);
    } catch (e) {
      return false;
    }
  }

  /// Obtener lista de documentos subidos por un técnico
  Future<List<String>> getUploadedDocumentTypes(String technicianId) async {
    try {
      final files = await _supabase.storage
          .from(verificationDocsBucket)
          .list(path: technicianId);

      return files.map((file) {
        final fileName = file.name;
        if (fileName.startsWith('id_front')) return DocumentTypes.idFront;
        if (fileName.startsWith('id_back')) return DocumentTypes.idBack;
        if (fileName.startsWith('certificate')) return DocumentTypes.certificate;
        return '';
      }).where((type) => type.isNotEmpty).toList();
    } catch (e) {
      return [];
    }
  }
}