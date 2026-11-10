import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/navigation_entities.dart';

/// Remote datasource cho Trip — đồng bộ với Supabase
@injectable
class TripRemoteDatasource {
  final SupabaseClient _client;
  final Logger _logger = Logger();
  static const String _tag = 'TripRemoteDatasource';

  TripRemoteDatasource(this._client);

  /// Tải chuyến đi lên Supabase
  Future<void> uploadTrip(TripEntity trip) async {
    try {
      await _client.from('trips').upsert({
        'id': trip.id,
        'user_id': _client.auth.currentUser?.id,
        'name': trip.name,
        'notes': trip.notes,
        'started_at': trip.startedAt?.toIso8601String(),
        'ended_at': trip.endedAt?.toIso8601String(),
        'total_distance_km': trip.totalDistanceKm,
        'max_altitude': trip.maxAltitude,
      });
      _logger.i('[$_tag] ✅ Trip uploaded: ${trip.name}');
    } catch (e) {
      _logger.e('[$_tag] ❌ Upload trip failed: $e');
      rethrow;
    }
  }

  /// Lấy danh sách chuyến đi từ server
  Future<List<TripEntity>> getTrips() async {
    final response = await _client
        .from('trips')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((row) {
      final map = row as Map<String, dynamic>;
      return TripEntity(
        id: map['id'] as String,
        name: map['name'] as String,
        notes: map['notes'] as String?,
        startedAt: map['started_at'] != null
            ? DateTime.parse(map['started_at'] as String)
            : null,
        endedAt: map['ended_at'] != null
            ? DateTime.parse(map['ended_at'] as String)
            : null,
        totalDistanceKm: (map['total_distance_km'] as num?)?.toDouble() ?? 0,
        maxAltitude: (map['max_altitude'] as num?)?.toDouble(),
        synced: true,
      );
    }).toList();
  }

  /// Lấy thông tin tóm tắt chuyến đi (qua view trip_summaries)
  Future<Map<String, dynamic>?> getTripSummary(String tripId) async {
    try {
      final response = await _client
          .from('trip_summaries')
          .select()
          .eq('id', tripId)
          .maybeSingle();
      return response;
    } catch (e) {
      _logger.w('[$_tag] Không thể lấy trip summary: $e');
      return null;
    }
  }

  /// Tính khoảng cách chuyến đi qua PostGIS RPC function
  Future<double> calculateTripDistance(String tripId) async {
    try {
      final response = await _client
          .rpc('calculate_trip_distance', params: {'p_trip_id': tripId});
      return (response as num?)?.toDouble() ?? 0;
    } catch (e) {
      _logger.w('[$_tag] Không thể tính khoảng cách: $e');
      return 0;
    }
  }

  /// Lấy bounding box của chuyến đi qua PostGIS RPC function
  Future<Map<String, double>?> getTripBounds(String tripId) async {
    try {
      final response = await _client
          .rpc('get_trip_bounds', params: {'p_trip_id': tripId});
      if (response is List && response.isNotEmpty) {
        final row = response[0] as Map<String, dynamic>;
        return {
          'min_lat': (row['min_lat'] as num).toDouble(),
          'max_lat': (row['max_lat'] as num).toDouble(),
          'min_lng': (row['min_lng'] as num).toDouble(),
          'max_lng': (row['max_lng'] as num).toDouble(),
        };
      }
    } catch (e) {
      _logger.w('[$_tag] Không thể lấy trip bounds: $e');
    }
    return null;
  }

  /// Tìm waypoint gần nhất qua PostGIS RPC function
  Future<List<Map<String, dynamic>>> findNearestWaypoints({
    required double latitude,
    required double longitude,
    double radiusMeters = 5000,
    int limit = 10,
  }) async {
    try {
      final response = await _client.rpc('find_nearest_waypoints', params: {
        'p_lat': latitude,
        'p_lng': longitude,
        'p_radius_meters': radiusMeters,
        'p_limit': limit,
      });
      return (response as List)
          .map((r) => r as Map<String, dynamic>)
          .toList();
    } catch (e) {
      _logger.w('[$_tag] Không thể tìm waypoint: $e');
      return [];
    }
  }
}

