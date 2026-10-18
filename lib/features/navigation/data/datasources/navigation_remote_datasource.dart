import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/navigation_entities.dart';

abstract class NavigationRemoteDatasource {
  Future<void> uploadTrackPoints({required String tripId, required List<GpsPoint> points});
  Future<void> uploadWaypoints({required String tripId, required List<WaypointEntity> waypoints});
  Future<List<GpsPoint>> getTrackPoints(String tripId);
}

@Injectable(as: NavigationRemoteDatasource)
class NavigationRemoteDatasourceImpl implements NavigationRemoteDatasource {
  final SupabaseClient client;
  NavigationRemoteDatasourceImpl(this.client);

  @override
  Future<void> uploadTrackPoints({required String tripId, required List<GpsPoint> points}) async {
    final rows = points.map((p) => {
      'trip_id': tripId,
      // PostGIS format: POINT(longitude latitude)
      'location': 'POINT(${p.longitude} ${p.latitude})',
      'altitude': p.altitude,
      'accuracy': p.accuracy,
      'recorded_at': p.recordedAt.toIso8601String(),
    }).toList();

    await client.from('track_points').insert(rows);
  }

  @override
  Future<void> uploadWaypoints({required String tripId, required List<WaypointEntity> waypoints}) async {
    final rows = waypoints.map((w) => {
      'id': w.id,
      'trip_id': tripId,
      'user_id': client.auth.currentUser?.id,
      'name': w.name,
      'note': w.note,
      'location': 'POINT(${w.position.longitude} ${w.position.latitude})',
      'altitude': w.position.altitude,
    }).toList();

    await client.from('waypoints').upsert(rows);
  }

  @override
  Future<List<GpsPoint>> getTrackPoints(String tripId) async {
    final response = await client
        .from('track_points')
        .select('altitude, accuracy, recorded_at, ST_X(location::geometry) as lng, ST_Y(location::geometry) as lat')
        .eq('trip_id', tripId)
        .order('recorded_at');

    return (response as List).map((r) => GpsPoint(
      latitude: (r['lat'] as num).toDouble(),
      longitude: (r['lng'] as num).toDouble(),
      altitude: r['altitude'] != null ? (r['altitude'] as num).toDouble() : null,
      accuracy: r['accuracy'] != null ? (r['accuracy'] as num).toDouble() : null,
      recordedAt: DateTime.parse(r['recorded_at'] as String),
    )).toList();
  }
}
