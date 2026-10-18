import 'package:latlong2/latlong.dart';

/// GPS coordinate point with altitude
class GpsPoint {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final DateTime recordedAt;

  const GpsPoint({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    required this.recordedAt,
  });

  LatLng toLatLng() => LatLng(latitude, longitude);

  @override
  String toString() => 'GpsPoint($latitude, $longitude, alt: $altitude)';
}

/// Waypoint entity — user-defined named location on the map
class WaypointEntity {
  final String id;
  final String tripId;
  final String name;
  final String? note;
  final GpsPoint position;
  final bool synced;

  const WaypointEntity({
    required this.id,
    required this.tripId,
    required this.name,
    this.note,
    required this.position,
    this.synced = false,
  });
}

/// A trekking trip entity
class TripEntity {
  final String id;
  final String name;
  final String? notes;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final double totalDistanceKm;
  final double? maxAltitude;
  final bool synced;

  const TripEntity({
    required this.id,
    required this.name,
    this.notes,
    this.startedAt,
    this.endedAt,
    this.totalDistanceKm = 0,
    this.maxAltitude,
    this.synced = false,
  });
}
