import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Widget reutilizable de mapa
class MapWidget extends StatelessWidget {
  final LatLng center;
  final double zoom;
  final List<Marker> markers;
  final Function(LatLng)? onTap;

  const MapWidget({
    super.key,
    required this.center,
    this.zoom = 15.0,
    this.markers = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        onTap: (tapPosition, point) => onTap?.call(point),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.servicios_app',
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }
}