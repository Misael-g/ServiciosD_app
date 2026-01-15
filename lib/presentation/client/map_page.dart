import 'package:flutter/material.dart';

/// Pantalla de mapa con técnicos cercanos
/// 
/// TODO Semana 4: Implementar
/// - Mostrar mapa con OpenStreetMap
/// - Marcar ubicación actual
/// - Mostrar técnicos cercanos como marcadores
/// - Filtro por especialidad
/// - Al tap en marcador, mostrar perfil del técnico
class ClientMapPage extends StatefulWidget {
  const ClientMapPage({super.key});

  @override
  State<ClientMapPage> createState() => _ClientMapPageState();
}

class _ClientMapPageState extends State<ClientMapPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Técnicos Cercanos'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Mapa de Técnicos'),
            const SizedBox(height: 8),
            Text(
              'Por implementar en Semana 4',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}