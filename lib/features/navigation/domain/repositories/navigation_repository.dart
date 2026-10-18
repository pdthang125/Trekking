import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/navigation_entities.dart';

abstract class NavigationRepository {
  /// Start GPS tracking — periodic updates every [intervalSeconds]
  Stream<Either<Failure, GpsPoint>> startTracking({int intervalSeconds = 10});

  /// Stop GPS tracking
  Future<void> stopTracking();

  /// Get current GPS position (one-shot)
  Future<Either<Failure, GpsPoint>> getCurrentPosition();

  /// Save track point to local Drift DB
  Future<Either<Failure, void>> saveTrackPoint({
    required String tripId,
    required GpsPoint point,
  });

  /// Get all track points for a trip (from local DB)
  Future<Either<Failure, List<GpsPoint>>> getTrackPoints(String tripId);

  /// Add waypoint
  Future<Either<Failure, WaypointEntity>> addWaypoint({
    required String tripId,
    required String name,
    required GpsPoint position,
    String? note,
  });

  /// Get all waypoints for a trip
  Future<Either<Failure, List<WaypointEntity>>> getWaypoints(String tripId);

  /// Delete waypoint
  Future<Either<Failure, void>> deleteWaypoint(String waypointId);

  /// Sync unsynced data to Supabase when online
  Future<Either<Failure, void>> syncPendingData();
}
