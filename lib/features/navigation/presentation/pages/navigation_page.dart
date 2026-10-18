import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/entities/navigation_entities.dart';
import '../widgets/waypoint_dialog.dart';

/// Offline Map Navigation Screen
/// Uses flutter_map + OpenStreetMap tiles
class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  final MapController _mapController = MapController();

  // Mặc định: Đỉnh Bàn Cờ, Bán đảo Sơn Trà, Đà Nẵng
  static const _defaultCenter = LatLng(16.1189, 108.2782);

  bool _isTracking = false;
  final List<LatLng> _trackPoints = [];
  final List<Marker> _waypoints = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Map Layer ────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 14,
              maxZoom: 18,
              minZoom: 3,
            ),
            children: [
              // Tile Layer — OSM (swap URL for offline tiles)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.vku.trekguard',
              ),

              // Track polyline
              if (_trackPoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _trackPoints,
                      strokeWidth: 4,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),

              // Waypoints layer
              MarkerLayer(markers: _waypoints),
            ],
          ),

          // ── Top AppBar overlay ────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: const Color(0xFF1B2232).withAlpha(220),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.terrain_rounded, color: Colors.greenAccent, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Sơn Trà (621m) · Offline',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.download_rounded, color: Colors.white70, size: 20),
                                tooltip: 'Quản lý bản đồ ngoại tuyến',
                                onPressed: () => context.push(AppRoutes.offlineMaps),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // GPS Tracking toggle
                    FloatingActionButton.small(
                      heroTag: 'tracking_btn',
                      backgroundColor: _isTracking
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                      onPressed: _toggleTracking,
                      child: Icon(
                        _isTracking
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom controls ───────────────────────────────────
          Positioned(
            bottom: 24, right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'add_waypoint',
                  tooltip: 'Tạo mốc toạ độ (Waypoint)',
                  onPressed: _addWaypoint,
                  child: const Icon(Icons.add_location_rounded),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'my_location',
                  tooltip: 'Căn giữa GPS',
                  onPressed: _goToMyLocation,
                  child: const Icon(Icons.my_location_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleTracking() {
    setState(() => _isTracking = !_isTracking);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isTracking ? '🛰️ Bắt đầu ghi vết GPS ngầm...' : '⏹️ Đã tạm dừng ghi vết GPS'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addWaypoint() {
    final center = _mapController.camera.center;
    final currentGps = GpsPoint(
      latitude: center.latitude,
      longitude: center.longitude,
      altitude: 621.0,
      accuracy: 3.0,
      recordedAt: DateTime.now(),
    );

    showDialog(
      context: context,
      builder: (ctx) => WaypointDialog(
        currentPosition: currentGps,
        onSave: (waypoint) {
          setState(() {
            _waypoints.add(Marker(
              point: LatLng(waypoint.position.latitude, waypoint.position.longitude),
              width: 44,
              height: 44,
              child: Tooltip(
                message: '${waypoint.name}${waypoint.note != null ? '\n${waypoint.note}' : ''}',
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amberAccent, width: 2),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Colors.amberAccent,
                    size: 26,
                  ),
                ),
              ),
            ));
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('📍 Đã ghim mốc "${waypoint.name}" lên bản đồ!')),
          );
        },
      ),
    );
  }

  void _goToMyLocation() {
    // TODO: Get real GPS location
    _mapController.move(_defaultCenter, 15);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
