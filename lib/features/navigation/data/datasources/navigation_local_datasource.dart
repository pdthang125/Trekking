import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/navigation_entities.dart';
import 'package:drift/drift.dart';

abstract class NavigationLocalDatasource {
  Stream<GpsPoint> startLocationStream({int intervalSeconds = 10});
  Future<void> stopLocationStream();
  Future<GpsPoint> getCurrentPosition();
  Future<void> saveTrackPoint({required String tripId, required GpsPoint point});
  Future<List<GpsPoint>> getTrackPoints(String tripId);
  Future<WaypointEntity> addWaypoint({required String tripId, required String name, required GpsPoint position, String? note});
  Future<List<WaypointEntity>> getWaypoints(String tripId);
  Future<void> deleteWaypoint(String waypointId);
  Future<List<int>> getUnsyncedTrackPointIds();
  Future<void> markTrackPointsSynced(List<int> ids);
}

@Injectable(as: NavigationLocalDatasource)
class NavigationLocalDatasourceImpl implements NavigationLocalDatasource {
  final AppDatabase db;
  final _uuid = const Uuid();
  StreamSubscription<Position>? _positionSub;
  StreamController<GpsPoint>? _streamController;

  NavigationLocalDatasourceImpl(this.db);

  @override
  Stream<GpsPoint> startLocationStream({int intervalSeconds = 10}) {
    _streamController?.close();
    _streamController = StreamController<GpsPoint>.broadcast();

    // Request permission first
    _startTracking(intervalSeconds);
    return _streamController!.stream;
  }

  Future<void> _startTracking(int intervalSeconds) async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // meters — only update if moved 10m
        intervalDuration: Duration(seconds: intervalSeconds),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: 'TrekGuard đang theo dõi vị trí của bạn',
          notificationTitle: '🏔️ TrekGuard GPS',
          enableWakeLock: true,
        ),
      );

      _positionSub = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (position) {
          final point = GpsPoint(
            latitude: position.latitude,
            longitude: position.longitude,
            altitude: position.altitude,
            accuracy: position.accuracy,
            recordedAt: DateTime.now(),
          );
          _streamController?.add(point);
        },
        onError: (e) => _streamController?.addError(e),
      );
    } catch (e) {
      _streamController?.addError(e);
    }
  }

  @override
  Future<void> stopLocationStream() async {
    await _positionSub?.cancel();
    _positionSub = null;
    await _streamController?.close();
    _streamController = null;
  }

  @override
  Future<GpsPoint> getCurrentPosition() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return GpsPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      accuracy: position.accuracy,
      recordedAt: DateTime.now(),
    );
  }

  @override
  Future<void> saveTrackPoint({required String tripId, required GpsPoint point}) async {
    await db.into(db.trackPoints).insert(TrackPointsCompanion(
      tripId: Value(tripId),
      latitude: Value(point.latitude),
      longitude: Value(point.longitude),
      altitude: Value(point.altitude),
      accuracy: Value(point.accuracy),
      recordedAt: Value(point.recordedAt),
    ));
  }

  @override
  Future<List<GpsPoint>> getTrackPoints(String tripId) async {
    final rows = await (db.select(db.trackPoints)
      ..where((t) => t.tripId.equals(tripId))
      ..orderBy([(t) => OrderingTerm.asc(t.recordedAt)]))
      .get();

    return rows.map((r) => GpsPoint(
      latitude: r.latitude,
      longitude: r.longitude,
      altitude: r.altitude,
      accuracy: r.accuracy,
      recordedAt: r.recordedAt,
    )).toList();
  }

  @override
  Future<WaypointEntity> addWaypoint({
    required String tripId,
    required String name,
    required GpsPoint position,
    String? note,
  }) async {
    final id = _uuid.v4();
    await db.into(db.waypoints).insert(WaypointsCompanion(
      id: Value(id),
      tripId: Value(tripId),
      name: Value(name),
      note: Value(note),
      latitude: Value(position.latitude),
      longitude: Value(position.longitude),
      altitude: Value(position.altitude),
    ));
    return WaypointEntity(id: id, tripId: tripId, name: name, note: note, position: position);
  }

  @override
  Future<List<WaypointEntity>> getWaypoints(String tripId) async {
    final rows = await (db.select(db.waypoints)
      ..where((t) => t.tripId.equals(tripId)))
      .get();
    return rows.map((r) => WaypointEntity(
      id: r.id,
      tripId: r.tripId,
      name: r.name,
      note: r.note,
      position: GpsPoint(latitude: r.latitude, longitude: r.longitude, altitude: r.altitude, recordedAt: DateTime.now()),
      synced: r.synced,
    )).toList();
  }

  @override
  Future<void> deleteWaypoint(String waypointId) async {
    await (db.delete(db.waypoints)..where((t) => t.id.equals(waypointId))).go();
  }

  @override
  Future<List<int>> getUnsyncedTrackPointIds() async {
    final rows = await (db.select(db.trackPoints)
      ..where((t) => t.synced.equals(false)))
      .get();
    return rows.map((r) => r.id).toList();
  }

  @override
  Future<void> markTrackPointsSynced(List<int> ids) async {
    await (db.update(db.trackPoints)
      ..where((t) => t.id.isIn(ids)))
      .write(const TrackPointsCompanion(synced: Value(true)));
  }
}
