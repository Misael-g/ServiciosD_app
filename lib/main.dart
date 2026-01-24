import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'core/config/supabase_config.dart';
import 'data/datasources/auth_remote_ds.dart';
import 'data/datasources/profiles_remote_ds.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'presentation/auth/login_page.dart';
import 'presentation/auth/register_page.dart';
import 'presentation/client/main_navigation.dart';
import 'presentation/technician/main_navigation.dart';
import 'presentation/admin/main_navigation.dart';

// ============================================
// HANDLER BACKGROUND (DEBE ESTAR AQUI ARRIBA)
// ============================================
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔔 [BACKGROUND] Mensaje: ${message.notification?.title}');
}

// Variable temporal para el token
String? _tempFcmToken;
String? get tempFcmToken => _tempFcmToken;

// ============================================
// MAIN
// ============================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1. Cargar .env
    await dotenv.load(fileName: ".env");
    print('✅ .env cargado');

    // 2. Inicializar Firebase
    await Firebase.initializeApp();
    print('✅ Firebase inicializado');

    // 3. Configurar handler de background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    print('✅ Background handler configurado');

    // 4. Inicializar Supabase
    await SupabaseConfig.initialize();
    print('✅ Supabase inicializado');

    // 5. Solicitar permisos de notificaciones
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permisos de notificaciones concedidos');
      
      // Obtener token FCM
      final token = await messaging.getToken();
      print('📱 FCM Token obtenido: ${token?.substring(0, 20)}...');
      
      // IMPORTANTE: Guardar en variable temporal
      // Se guardará en BD después del login
      _tempFcmToken = token;
    } else {
      print('⚠️ Permisos de notificaciones denegados');
    }

  } catch (e) {
    print('❌ Error en inicialización: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Proveer el repositorio de autenticación
        Provider<AuthRepository>(
          create: (_) => AuthRepositoryImpl(
            authDataSource: AuthRemoteDataSource(),
            profilesDataSource: ProfilesRemoteDataSource(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'ServiciosD',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.orange,
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
        },
      ),
    );
  }
}

/// Wrapper que decide qué pantalla mostrar según el estado de autenticación
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    final authRepository = context.read<AuthRepository>();

    return FutureBuilder(
      future: authRepository.getCurrentUserProfile(),
      builder: (context, snapshot) {
        print('🔍 [AuthWrapper] ConnectionState: ${snapshot.connectionState}');
        print('🔍 [AuthWrapper] HasData: ${snapshot.hasData}');
        print('🔍 [AuthWrapper] HasError: ${snapshot.hasError}');
        
        // Mientras carga, mostrar splash screen
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Si hay error, mostrar login
        if (snapshot.hasError) {
          print('❌ [AuthWrapper] Error: ${snapshot.error}');
          // IMPORTANTE: Usar WidgetsBinding para evitar errores de navegación
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Si hay usuario autenticado
        if (snapshot.hasData && snapshot.data != null) {
          final profile = snapshot.data!;
          print('✅ [AuthWrapper] Usuario autenticado: ${profile.email}');
          print('✅ [AuthWrapper] Rol: ${profile.role}');

          // CORRECCIÓN: Redirigir según el rol sin errores de navegación
          // Usar addPostFrameCallback para evitar setState durante build
          Widget targetScreen;
          
          switch (profile.role) {
            case 'client':
              targetScreen = const ClientMainNavigation();
              break;
            case 'technician':
              targetScreen = const TechnicianMainNavigation();
              break;
            case 'admin':
              targetScreen = const AdminMainNavigation();
              break;
            default:
              print('⚠️ [AuthWrapper] Rol desconocido: ${profile.role}');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              });
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
          }

          return targetScreen;
        }

        // Si no hay usuario autenticado, mostrar login
        print('ℹ️ [AuthWrapper] No hay usuario autenticado');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        });
        
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}