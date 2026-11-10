import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/navigation_entities.dart';

/// Datasource quản lý chuyến đi (Trip) — lưu trữ cục bộ Drift SQLite
@injectable
class TripLocalDatasource {
  final AppDatabase db;
  final _uuid = const Uuid();

  TripLocalDatasource(this.db);

  /// Tạo chuyến đi mới
  Future<TripEntity> createTrip({required String name, String? notes}) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    await db.into(db.trips).insert(TripsCompanion(
      id: Value(id),
      name: Value(name),
      notes: Value(notes),
      startedAt: Value(now),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));

    return TripEntity(
      id: id,
      name: name,
      notes: notes,
      startedAt: now,
    );
  }

  /// Lấy danh sách tất cả chuyến đi (chưa xoá)
  Future<List<TripEntity>> getAllTrips() async {
    final rows = await (db.select(db.trips)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map((row) => _rowToEntity(row)).toList();
  }

  /// Lấy chuyến đi theo ID
  Future<TripEntity?> getTripById(String id) async {
    final row = await (db.select(db.trips)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _rowToEntity(row) : null;
  }

  /// Lấy chuyến đi đang hoạt động (chưa kết thúc)
  Future<TripEntity?> getActiveTrip() async {
    final row = await (db.select(db.trips)
          ..where((t) => t.endedAt.isNull() & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
          ..limit(1))
        .getSingleOrNull();
    return row != null ? _rowToEntity(row) : null;
  }

  /// Cập nhật thông tin chuyến đi
  Future<void> updateTrip({
    required String id,
    String? name,
    String? notes,
    double? totalDistanceKm,
    double? maxAltitude,
  }) async {
    await (db.update(db.trips)..where((t) => t.id.equals(id))).write(
      TripsCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        notes: notes != null ? Value(notes) : const Value.absent(),
        totalDistanceKm: totalDistanceKm != null
            ? Value(totalDistanceKm)
            : const Value.absent(),
        maxAltitude: maxAltitude != null
            ? Value(maxAltitude)
            : const Value.absent(),
        updatedAt: Value(DateTime.now()),
        synced: const Value(false),
      ),
    );
  }

  /// Kết thúc chuyến đi
  Future<void> endTrip(String id) async {
    await (db.update(db.trips)..where((t) => t.id.equals(id))).write(
      TripsCompanion(
        endedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        synced: const Value(false),
      ),
    );
  }

  /// Xoá mềm chuyến đi (đánh dấu deletedAt)
  Future<void> softDeleteTrip(String id) async {
    await (db.update(db.trips)..where((t) => t.id.equals(id))).write(
      TripsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        synced: const Value(false),
      ),
    );
  }

  /// Lấy danh sách chuyến đi chưa đồng bộ
  Future<List<TripEntity>> getUnsyncedTrips() async {
    final rows = await (db.select(db.trips)
          ..where((t) => t.synced.equals(false)))
        .get();
    return rows.map((row) => _rowToEntity(row)).toList();
  }

  /// Đánh dấu đã đồng bộ
  Future<void> markTripSynced(String id) async {
    await (db.update(db.trips)..where((t) => t.id.equals(id))).write(
      const TripsCompanion(synced: Value(true)),
    );
  }

  /// Đếm số track points của chuyến đi
  Future<int> countTrackPoints(String tripId) async {
    final count = await (db.select(db.trackPoints)
          ..where((t) => t.tripId.equals(tripId)))
        .get();
    return count.length;
  }

  /// Đếm số waypoints của chuyến đi
  Future<int> countWaypoints(String tripId) async {
    final count = await (db.select(db.waypoints)
          ..where((t) => t.tripId.equals(tripId) & t.deletedAt.isNull()))
        .get();
    return count.length;
  }

  // ─── Private helpers ──────────────────────────────────────

  TripEntity _rowToEntity(Trip row) {
    return TripEntity(
      id: row.id,
      name: row.name,
      notes: row.notes,
      startedAt: row.startedAt,
      endedAt: row.endedAt,
      totalDistanceKm: row.totalDistanceKm,
      maxAltitude: row.maxAltitude,
      synced: row.synced,
    );
  }
}

// Drift type alias - no longer needed as generated class is Trip
// typedef Trip = TripsData;
