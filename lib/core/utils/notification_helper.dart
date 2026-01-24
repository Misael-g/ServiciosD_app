import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/supabase_config.dart';

/// Helper para manejar notificaciones
class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _currentToken;
  String? get currentToken => _currentToken;

  /// Inicializar notificaciones y obtener token
  Future<String?> initialize() async {
    try {
      print('🔔 [NOTIF] Inicializando...');

      // 1. Solicitar permisos
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        print('⚠️ [NOTIF] Permisos denegados');
        return null;
      }

      print('✅ [NOTIF] Permisos concedidos');

      // 2. Configurar notificaciones locales
      await _setupLocalNotifications();

      // 3. Obtener token FCM
      _currentToken = await _messaging.getToken();
      print('📱 [NOTIF] Token: ${_currentToken?.substring(0, 30)}...');

      // 4. Configurar listeners
      _setupListeners();

      // 5. Escuchar cambios de token
      _messaging.onTokenRefresh.listen((newToken) {
        print('🔄 [NOTIF] Token actualizado');
        _currentToken = newToken;
        _saveTokenToDatabase(newToken);
      });

      return _currentToken;
    } catch (e) {
      print('❌ [NOTIF] Error: $e');
      return null;
    }
  }

  /// Configurar notificaciones locales (foreground)
  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings);

    // Canal Android
    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notificaciones Importantes',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    print('✅ [NOTIF] Notificaciones locales configuradas');
  }

  /// Configurar listeners de mensajes
  void _setupListeners() {
    // Mensaje en foreground
    FirebaseMessaging.onMessage.listen((message) {
      print('🔔 [NOTIF] Mensaje en foreground');
      print('   Título: ${message.notification?.title}');
      print('   Cuerpo: ${message.notification?.body}');

      _showLocalNotification(message);
    });

    // Mensaje en background (tap)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('🔔 [NOTIF] App abierta desde notificación');
      // TODO: Navegar según message.data['type']
    });

    // App iniciada desde notificación (cerrada)
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        print('🔔 [NOTIF] App iniciada desde notificación');
        // TODO: Navegar según message.data['type']
      }
    });
  }

  /// Mostrar notificación local cuando app en foreground
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'Notificaciones Importantes',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
    );

    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Nueva notificación',
      message.notification?.body ?? '',
      details,
    );
  }

  /// Guardar token en Supabase
  Future<void> saveTokenForCurrentUser() async {
    if (_currentToken == null) {
      print('⚠️ [NOTIF] No hay token para guardar');
      return;
    }

    final userId = SupabaseConfig.currentUserId;
    if (userId == null) {
      print('⚠️ [NOTIF] No hay usuario logueado');
      return;
    }

    await _saveTokenToDatabase(_currentToken!);
  }

  /// Guardar token en BD
  Future<void> _saveTokenToDatabase(String token) async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        print('⚠️ [NOTIF] No hay usuario logueado para guardar token');
        return;
      }

      print('💾 [NOTIF] Guardando token en BD...');

      await SupabaseConfig.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', userId);

      print('✅ [NOTIF] Token guardado en BD');

      // Verificar que se guardó
      final result = await SupabaseConfig.client
          .from('profiles')
          .select('fcm_token')
          .eq('id', userId)
          .single();

      print('🔍 [NOTIF] Token en BD: ${result['fcm_token']?.substring(0, 30)}...');
    } catch (e) {
      print('❌ [NOTIF] Error guardando token: $e');
    }
  }

  /// Eliminar token (logout)
  Future<void> deleteToken() async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) return;

      await SupabaseConfig.client
          .from('profiles')
          .update({'fcm_token': null})
          .eq('id', userId);

      await _messaging.deleteToken();
      _currentToken = null;

      print('✅ [NOTIF] Token eliminado');
    } catch (e) {
      print('❌ [NOTIF] Error eliminando token: $e');
    }
  }
}