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

  /// Kiểm tra chuyến đi đang hoạt động
  bool get isActive => endedAt == null;

  /// Thời gian chuyến đi
  Duration? get duration {
    if (startedAt == null) return null;
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt!);
  }

  /// Tốc độ trung bình (km/h)
  double? get avgSpeedKmh {
    final d = duration;
    if (d == null || d.inSeconds == 0 || totalDistanceKm == 0) return null;
    return totalDistanceKm / (d.inSeconds / 3600);
  }

  TripEntity copyWith({
    String? id,
    String? name,
    String? notes,
    DateTime? startedAt,
    DateTime? endedAt,
    double? totalDistanceKm,
    double? maxAltitude,
    bool? synced,
  }) {
    return TripEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      maxAltitude: maxAltitude ?? this.maxAltitude,
      synced: synced ?? this.synced,
    );
  }
}

/// Thống kê tóm tắt chuyến đi
class TripSummary {
  final TripEntity trip;
  final int trackPointCount;
  final int waypointCount;
  final Duration? duration;

  const TripSummary({
    required this.trip,
    required this.trackPointCount,
    required this.waypointCount,
    this.duration,
  });
}
