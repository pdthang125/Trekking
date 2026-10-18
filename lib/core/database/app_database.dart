import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:injectable/injectable.dart';

part 'app_database.g.dart';

// ─── Table Definitions ────────────────────────────────────────────────────────

/// First Aid Guides — seeded from assets/data/first_aid_guides.json
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
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// GPS Track Points — recorded during active trip
class TrackPoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tripId => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get altitude => real().nullable()();
  RealColumn get accuracy => real().nullable()();
  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
}

/// Waypoints — user-defined points of interest on map
class Waypoints extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text()();
  TextColumn get name => text()();
  TextColumn get note => text().nullable()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get altitude => real().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Trips — each trekking journey
class Trips extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  RealColumn get totalDistanceKm => real().withDefault(const Constant(0.0))();
  RealColumn get maxAltitude => real().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Database Definition ──────────────────────────────────────────────────────

@DriftDatabase(tables: [FirstAidGuides, TrackPoints, Waypoints, Trips])
@singleton
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // Handle future migrations here
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'trekguard_database');
  }
}
