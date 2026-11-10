import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:injectable/injectable.dart';

part 'app_database.g.dart';

// ─── Table Definitions ────────────────────────────────────────────────────────
//
// Quy ước đồng bộ với Supabase:
//  • Mọi khóa chính là UUID (text) do app tự sinh (package `uuid`), để đẩy lại
//    sau khi mất mạng dùng upsert mà không tạo bản ghi trùng.
//  • `synced = false` nghĩa là dòng đang chờ đẩy lên server.
//  • Mỗi lần SỬA: đặt `updatedAt = DateTime.now()` và `synced = false`.
//  • Mỗi lần XÓA: đặt `deletedAt = DateTime.now()` và `synced = false`
//    (xóa mềm), không dùng delete thật để lệnh xóa lan được lên server.
//  • Tọa độ lưu `latitude`/`longitude`; cột `location` (PostGIS) do server tự sinh.
//  • `user_id` do server tự gán bằng auth.uid(), app không cần lưu.

/// Hướng dẫn sơ cứu — nạp từ assets/data/first_aid_guides.json
@DataClassName('FirstAidGuideData')
class FirstAidGuides extends Table {
  TextColumn get id => text()();
  TextColumn get conditionName => text()();
  TextColumn get conditionNameVi => text()();
  TextColumn get severity => text()(); // 'safe' | 'warning' | 'danger'
  TextColumn get description => text()();
  TextColumn get descriptionVi => text()();
  TextColumn get stepsJson => text()(); // JSON array of FirstAidStep
  TextColumn get doNotsJson => text()(); // JSON array
  TextColumn get doNotsViJson => text()(); // JSON array
  TextColumn get tagsJson => text()(); // JSON array of tags
  TextColumn get whenToEvacuate => text().nullable()();
  TextColumn get whenToEvacuateVi => text().nullable()();

  /// Tăng khi nội dung được cập nhật; dùng để kéo bản mới từ server.
  IntColumn get version => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Điểm GPS — ghi trong lúc đang có chuyến đi (chỉ thêm, không sửa)
@TableIndex(name: 'idx_track_points_trip', columns: {#tripId, #recordedAt})
@TableIndex(name: 'idx_track_points_synced', columns: {#synced})
class TrackPoints extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get tripId => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get altitude => real().nullable()();
  RealColumn get accuracy => real().nullable()();
  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Điểm đánh dấu do người dùng tạo trên bản đồ
@TableIndex(name: 'idx_waypoints_trip', columns: {#tripId})
class Waypoints extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get tripId => text()();
  TextColumn get name => text()();
  TextColumn get note => text().nullable()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get altitude => real().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Chuyến đi — mỗi hành trình trekking
class Trips extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get name => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  RealColumn get totalDistanceKm => real().withDefault(const Constant(0.0))();
  RealColumn get maxAltitude => real().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Lịch sử sự kiện SOS — đẩy lên server khi có mạng (khớp bảng sos_events)
class SosEvents extends Table {
  TextColumn get id => text()(); // UUID
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();

  /// Thời điểm ghi nhận vị trí (có thể cũ hơn createdAt nếu chưa có GPS fix).
  DateTimeColumn get locationTime => dateTime().nullable()();
  TextColumn get message => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Database Definition ──────────────────────────────────────────────────────

@DriftDatabase(
  tables: [FirstAidGuides, TrackPoints, Waypoints, Trips, SosEvents],
)
@singleton
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // v1 -> v2: đổi khóa chính TrackPoints sang UUID, thêm updatedAt/deletedAt,
        // version và bảng SosEvents. SQLite không cho ADD COLUMN với giá trị mặc
        // định không hằng (currentDateAndTime) và không đổi được kiểu khóa chính,
        // nên xóa và tạo lại toàn bộ bảng. Chỉ an toàn khi chưa có dữ liệu thật.
        // Dữ liệu sơ cứu sẽ được nạp lại từ JSON ở lần mở app kế tiếp.
        for (final table in allTables) {
          await m.drop(table);
        }
        await m.createAll();
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'trekguard_database');
  }
}
