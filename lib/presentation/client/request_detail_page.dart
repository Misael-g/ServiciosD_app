import 'package:flutter/material.dart';

/// Pantalla de detalle de solicitud
/// 
/// TODO: Implementar
/// - Mostrar información completa de la solicitud
/// - Mostrar cotizaciones recibidas
/// - Permitir aceptar/rechazar cotizaciones
/// - Mostrar técnico asignado
/// - Chat con técnico (opcional)
/// - Cambiar estado del servicio
class RequestDetailPage extends StatelessWidget {
  final String requestId;

  const RequestDetailPage({
    super.key,
    required this.requestId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Solicitud'),
      ),
      body: Center(
        child: Text('Detalle de solicitud: $requestId'),
      ),
    );
  }
}