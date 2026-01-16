import 'package:flutter/material.dart';
import 'home_page.dart';
import 'available_requests_page.dart';
import 'profile_page.dart';
import 'verification_page.dart';
import '../../data/datasources/profiles_remote_ds.dart';
import '../../core/utils/snackbar_helper.dart';

/// Navegación principal del técnico con Bottom Navigation Bar
class TechnicianMainNavigation extends StatefulWidget {
  const TechnicianMainNavigation({super.key});

  @override
  State<TechnicianMainNavigation> createState() =>
      _TechnicianMainNavigationState();
}

class _TechnicianMainNavigationState extends State<TechnicianMainNavigation> {
  int _currentIndex = 0;
  String? _verificationStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final profilesDS = ProfilesRemoteDataSource();
      final profile = await profilesDS.getCurrentUserProfile();
      setState(() {
        _verificationStatus = profile.verificationStatus;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(context, 'Error al cargar perfil');
      }
    }
  }

  List<Widget> get _pages {
    // Si no está verificado, mostrar solo verificación y perfil
    if (_verificationStatus != 'approved') {
      return [
        const VerificationPage(),
        const TechnicianProfilePage(),
      ];
    }

    // Si está verificado, mostrar todas las páginas
    return [
      const TechnicianHomePage(),
      const AvailableRequestsPage(),
      const TechnicianProfilePage(),
    ];
  }

  List<BottomNavigationBarItem> get _navItems {
    if (_verificationStatus != 'approved') {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.verified_user_outlined),
          activeIcon: Icon(Icons.verified_user),
          label: 'Verificación',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ];
    }

    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Inicio',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.work_outline),
        activeIcon: Icon(Icons.work),
        label: 'Solicitudes',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Perfil',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: _navItems,
      ),
    );
  }
}