import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuración de Supabase
/// 
/// Este archivo maneja la inicialización y configuración de Supabase
class SupabaseConfig {
  static Future<void> initialize() async {
    // Cargar variables de entorno
    await dotenv.load(fileName: ".env");

    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw Exception(
        'SUPABASE_URL y SUPABASE_ANON_KEY deben estar definidos en .env',
      );
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  /// Cliente de Supabase para usar en toda la app
  static SupabaseClient get client => Supabase.instance.client;

  /// Referencia rápida al usuario autenticado
  static User? get currentUser => client.auth.currentUser;

  /// ID del usuario autenticado
  static String? get currentUserId => currentUser?.id;

  /// Email del usuario autenticado
  static String? get currentUserEmail => currentUser?.email;

  /// Stream de cambios en la autenticación
  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}