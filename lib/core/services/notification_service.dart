// ============================================
// ARCHIVO: lib/core/services/notification_service.dart
// Copiar este archivo completo
// ============================================

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/supabase_config.dart';

/// 🔔 Servicio de Notificaciones Push
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Inicializar todo
  Future<void> initialize() async {
    try {
      print('🔔 Inicializando notificaciones...');

      // 1. Pedir permisos
      await _requestPermissions();

      // 2. Configurar notificaciones locales
      await _setupLocalNotifications();

      // 3. Obtener y guardar token
      await _getAndSaveToken();

      // 4. Configurar listeners
      _setupListeners();

      print('✅ Notificaciones listas');
    } catch (e) {
      print('❌ Error inicialización: $e');
    }
  }

  /// Pedir permisos
  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permisos concedidos');
    } else {
      print('❌ Permisos denegados');
    }
  }

  /// Configurar notificaciones locales
  Future<void> _setupLocalNotifications() async {
    // Android
    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    
    // iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

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
  }

  /// Obtener token y guardarlo
  Future<void> _getAndSaveToken() async {
    _fcmToken = await _messaging.getToken();
    print('📱 Token FCM: $_fcmToken');

    // Guardar en Supabase
    final userId = SupabaseConfig.currentUserId;
    if (userId != null && _fcmToken != null) {
      await SupabaseConfig.client
          .from('profiles')
          .update({'fcm_token': _fcmToken})
          .eq('id', userId);
      print('✅ Token guardado en BD');
    }

    // Escuchar cambios de token
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      _saveTokenToDatabase(newToken);
    });
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final userId = SupabaseConfig.currentUserId;
    if (userId != null) {
      await SupabaseConfig.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', userId);
    }
  }

  /// Configurar listeners de mensajes
  void _setupListeners() {
    // Cuando app está abierta (foreground)
    FirebaseMessaging.onMessage.listen((message) {
      print('🔔 Notificación recibida (foreground)');
      print('   ${message.notification?.title}');
      print('   ${message.notification?.body}');
      
      _showLocalNotification(message);
    });

    // Cuando tocas notificación y app estaba en background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('🔔 App abierta desde notificación');
      _handleNotificationTap(message);
    });

    // Cuando tocas notificación y app estaba cerrada
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        print('🔔 App iniciada desde notificación');
        _handleNotificationTap(message);
      }
    });
  }

  /// Mostrar notificación cuando app abierta
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'Notificaciones Importantes',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Nueva notificación',
      message.notification?.body ?? '',
      details,
    );
  }

  /// Manejar tap en notificación
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    print('📍 Navegando según tipo: ${data['type']}');
    
    // TODO: Implementar navegación según data['type']
    // Ejemplo:
    // if (data['type'] == 'new_quotation') {
    //   Navigator.push(...);
    // }
  }

  /// Eliminar token al hacer logout
  Future<void> deleteToken() async {
    final userId = SupabaseConfig.currentUserId;
    if (userId != null) {
      await SupabaseConfig.client
          .from('profiles')
          .update({'fcm_token': null})
          .eq('id', userId);
    }
    await _messaging.deleteToken();
    _fcmToken = null;
    print('✅ Token eliminado');
  }
}

/// Handler para mensajes en background (DEBE estar top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔔 Mensaje background: ${message.notification?.title}');
}