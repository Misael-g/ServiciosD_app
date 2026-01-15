import 'package:flutter/material.dart';
import 'home_page.dart';
import 'map_page.dart';
import 'my_requests_page.dart';
import 'profile_page.dart';

/// Navegación principal del cliente con Bottom Navigation Bar
class ClientMainNavigation extends StatefulWidget {
  const ClientMainNavigation({super.key});

  @override
  State<ClientMainNavigation> createState() => _ClientMainNavigationState();
}

class _ClientMainNavigationState extends State<ClientMainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const ClientHomePage(),
    const ClientMapPage(),
    const MyRequestsPage(),
    const ClientProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Solicitudes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}