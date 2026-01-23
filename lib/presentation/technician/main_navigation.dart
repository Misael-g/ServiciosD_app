import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'home_page.dart';
import 'available_requests_page.dart';
import 'profile_page.dart';
import 'verification_page.dart';
import 'my_quotations_page.dart';
import '../../data/datasources/profiles_remote_ds.dart';
import '../../core/utils/snackbar_helper.dart';

class TechnicianMainNavigation extends StatefulWidget {
  const TechnicianMainNavigation({super.key});

  @override
  State<TechnicianMainNavigation> createState() =>
      _TechnicianMainNavigationState();
}

class _TechnicianMainNavigationState extends State<TechnicianMainNavigation>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  String? _verificationStatus;
  bool _isLoading = true;
  late List<AnimationController> _iconAnimations;

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  @override
  void dispose() {
    for (var controller in _iconAnimations) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final profilesDS = ProfilesRemoteDataSource();
      final profile = await profilesDS.getCurrentUserProfile();
      
      setState(() {
        _verificationStatus = profile.verificationStatus;
        _isLoading = false;
      });

      // Inicializar animaciones
      final itemCount = _verificationStatus == 'approved' ? 3 : 2;
      _iconAnimations = List.generate(
        itemCount,
        (index) => AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
          value: index == 0 ? 1.0 : 0.0,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(context, 'Error al cargar perfil');
      }
    }
  }

  List<Widget> get _pages {
    if (_verificationStatus != 'approved') {
      return [
        const VerificationPage(),
        const TechnicianProfilePage(),
      ];
    }

    return [
      const TechnicianHomePage(),
      const AvailableRequestsPage(),
      const TechnicianProfilePage(),
    ];
  }

  List<_NavItem> get _navItems {
    if (_verificationStatus != 'approved') {
      return [
        _NavItem(
          icon: Icons.verified_user_outlined,
          activeIcon: Icons.verified_user_rounded,
          label: 'Verificación',
          color: AppColors.warning,
        ),
        _NavItem(
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          label: 'Perfil',
          color: AppColors.info,
        ),
      ];
    }

    return [
      _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Inicio',
        color: AppColors.primary,
      ),
      _NavItem(
        icon: Icons.work_outline_rounded,
        activeIcon: Icons.work_rounded,
        label: 'Solicitudes',
        color: AppColors.success,
      ),
      _NavItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Perfil',
        color: AppColors.info,
      ),
    ];
  }

  void _onItemTapped(int index) {
    if (_currentIndex == index) return;

    // Animar el ícono seleccionado
    _iconAnimations[index].forward();

    // Desanimar los otros íconos
    for (int i = 0; i < _iconAnimations.length; i++) {
      if (i != index) {
        _iconAnimations[i].reverse();
      }
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primaryDark,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.build_circle_rounded,
                  color: AppColors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'TecniHogar',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      drawer: _verificationStatus == 'approved' ? _buildDrawer() : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                _navItems.length,
                (index) => _buildNavItem(index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _navItems[index];
    final isActive = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      item.color.withValues(alpha: 0.15),
                      item.color.withValues(alpha: 0.05),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícono animado
              ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: 1.2).animate(
                  CurvedAnimation(
                    parent: _iconAnimations[index],
                    curve: Curves.easeInOut,
                  ),
                ),
                child: Icon(
                  isActive ? item.activeIcon : item.icon,
                  color: isActive ? item.color : AppColors.textSecondary,
                  size: 26,
                ),
              ),
              const SizedBox(height: 4),

              // Label con animación
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: isActive ? 12 : 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? item.color : AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Indicador de activo
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isActive ? 20 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primaryDark,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.build_circle_rounded,
                      size: 48,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Menú Técnico',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Menu Items
            _buildDrawerItem(
              icon: Icons.receipt_long_rounded,
              title: 'Mis Cotizaciones',
              subtitle: 'Ver todas mis propuestas',
              color: AppColors.warning,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyQuotationsPage(),
                  ),
                );
              },
            ),

            _buildDrawerItem(
              icon: Icons.notifications_rounded,
              title: 'Notificaciones',
              subtitle: 'Gestionar alertas',
              color: AppColors.info,
              onTap: () {
                Navigator.pop(context);
                SnackbarHelper.showInfo(context, 'Por implementar');
              },
            ),

            _buildDrawerItem(
              icon: Icons.help_rounded,
              title: 'Ayuda y Soporte',
              subtitle: 'Centro de ayuda',
              color: AppColors.success,
              onTap: () {
                Navigator.pop(context);
                SnackbarHelper.showInfo(context, 'Por implementar');
              },
            ),

            const Spacer(),

            // Version
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'TecniHogar v1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;

  _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}