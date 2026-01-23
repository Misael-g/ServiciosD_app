import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'home_page.dart';
import 'map_page.dart';
import 'my_requests_page.dart';
import 'profile_page.dart';

class ClientMainNavigation extends StatefulWidget {
  const ClientMainNavigation({super.key});

  @override
  State<ClientMainNavigation> createState() => _ClientMainNavigationState();
}

class _ClientMainNavigationState extends State<ClientMainNavigation> 
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late List<AnimationController> _iconAnimations;

  final List<Widget> _pages = [
    const ClientHomePage(),
    const ClientMapPage(),
    const MyRequestsPage(),
    const ClientProfilePage(),
  ];

  final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Inicio',
      color: AppColors.primary,
    ),
    _NavItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
      label: 'Explorar',
      color: AppColors.success,
    ),
    _NavItem(
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment_rounded,
      label: 'Solicitudes',
      color: AppColors.warning,
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Perfil',
      color: AppColors.info,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _iconAnimations = List.generate(
      _navItems.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
        value: index == 0 ? 1.0 : 0.0,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _iconAnimations) {
      controller.dispose();
    }
    super.dispose();
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

    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
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