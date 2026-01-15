import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/supabase_config.dart';
import 'data/datasources/auth_remote_ds.dart';
import 'data/datasources/profiles_remote_ds.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'presentation/auth/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase
  await SupabaseConfig.initialize();

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
        title: 'Servicios Técnicos',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

/// Wrapper que decide qué pantalla mostrar según el estado de autenticación
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = context.read<AuthRepository>();

    return FutureBuilder(
      future: authRepository.getCurrentUserProfile(),
      builder: (context, snapshot) {
        // Mientras carga, mostrar splash screen
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Si hay usuario autenticado
        if (snapshot.hasData && snapshot.data != null) {
          final profile = snapshot.data!;

          // Redirigir según el rol
          // TODO: Implementar las navegaciones por rol
          switch (profile.role) {
            case 'client':
              return const Scaffold(
                body: Center(
                  child: Text('Cliente Home - Por implementar'),
                ),
              );
            case 'technician':
              return const Scaffold(
                body: Center(
                  child: Text('Técnico Home - Por implementar'),
                ),
              );
            case 'admin':
              return const Scaffold(
                body: Center(
                  child: Text('Admin Home - Por implementar'),
                ),
              );
            default:
              return const LoginPage();
          }
        }

        // Si no hay usuario autenticado, mostrar login
        return const LoginPage();
      },
    );
  }
}