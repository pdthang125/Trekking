import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Offline Map Navigation Screen
/// Uses flutter_map + OpenStreetMap tiles
class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  final MapController _mapController = MapController();

  // Default center: Fansipan, Vietnam (3143m)
  static const _defaultCenter = LatLng(22.3076, 103.7763);

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
              initialZoom: 13,
              maxZoom: 18,
              minZoom: 3,
            ),
            children: [
              // Tile Layer — OSM (swap URL for offline tiles)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.vku.trekguard',
                // TODO: Replace with offline MBTiles source
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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8,
                          ),
                          child: Text(
                            '🗺️ Bản Đồ Ngoại Tuyến',
                            style: Theme.of(context).textTheme.titleSmall,
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
                  onPressed: _addWaypoint,
                  child: const Icon(Icons.add_location_rounded),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'my_location',
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
    // TODO: Start/stop GPS tracking service
  }

  void _addWaypoint() {
    // TODO: Add waypoint at current GPS position
    final center = _mapController.camera.center;
    setState(() {
      _waypoints.add(Marker(
        point: center,
        width: 40, height: 40,
        child: const Icon(
          Icons.location_on_rounded,
          color: Colors.orange,
          size: 36,
        ),
      ));
    });
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
