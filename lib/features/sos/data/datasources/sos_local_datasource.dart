import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' hide SosEvent;
import '../../domain/entities/sos_entities.dart';

/// Local datasource cho SOS Events — Drift SQLite
@injectable
class SosLocalDatasource {
  final AppDatabase db;
  final _uuid = const Uuid();

  SosLocalDatasource(this.db);

  /// Tạo sự kiện SOS mới
  Future<SosEvent> createEvent({
    double? latitude,
    double? longitude,
    String? message,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    await db.into(db.sosEvents).insert(SosEventsCompanion(
      id: Value(id),
      latitude: Value(latitude),
      longitude: Value(longitude),
      locationTime: Value(now),
      message: Value(message),
      createdAt: Value(now),
    ));

    return SosEvent(
      id: id,
      latitude: latitude,
      longitude: longitude,
      locationTime: now,
      message: message,
      createdAt: now,
    );
  }

  /// Lấy tất cả sự kiện SOS
  Future<List<SosEvent>> getAllEvents() async {
    final rows = await (db.select(db.sosEvents)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map((row) => _rowToEntity(row)).toList();
  }

  /// Lấy sự kiện chưa đồng bộ
  Future<List<SosEvent>> getUnsyncedEvents() async {
    final rows = await (db.select(db.sosEvents)
          ..where((t) => t.synced.equals(false)))
        .get();
    return rows.map((row) => _rowToEntity(row)).toList();
  }

  /// Đánh dấu đã đồng bộ
  Future<void> markSynced(String id) async {
    await (db.update(db.sosEvents)..where((t) => t.id.equals(id)))
        .write(const SosEventsCompanion(synced: Value(true)));
  }

  // ─── Private helpers ──────────────────────────────────────

  SosEvent _rowToEntity(dynamic dbRow) {
    return SosEvent(
      id: dbRow.id as String,
      latitude: dbRow.latitude as double?,
      longitude: dbRow.longitude as double?,
      locationTime: dbRow.locationTime as DateTime?,
      message: dbRow.message as String?,
      createdAt: dbRow.createdAt as DateTime,
      synced: dbRow.synced as bool? ?? false,
    );
  }
}
