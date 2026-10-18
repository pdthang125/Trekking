import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/navigation_entities.dart';
import '../repositories/navigation_repository.dart';

// ─── UseCase 1: Start GPS Tracking ────────────────────────────────────────────

@injectable
class StartTrackingUseCase {
  final NavigationRepository repository;
  StartTrackingUseCase(this.repository);

  Stream<Either<Failure, GpsPoint>> call({int intervalSeconds = 10}) {
    return repository.startTracking(intervalSeconds: intervalSeconds);
  }
}

// ─── UseCase 2: Stop GPS Tracking ─────────────────────────────────────────────

@injectable
class StopTrackingUseCase {
  final NavigationRepository repository;
  StopTrackingUseCase(this.repository);
  Future<void> call() => repository.stopTracking();
}

// ─── UseCase 3: Get Current Position ──────────────────────────────────────────

@injectable
class GetCurrentPositionUseCase extends UseCase<GpsPoint, NoParams> {
  final NavigationRepository repository;
  GetCurrentPositionUseCase(this.repository);

  @override
  Future<Either<Failure, GpsPoint>> call(NoParams params) {
    return repository.getCurrentPosition();
  }
}

// ─── UseCase 4: Add Waypoint ───────────────────────────────────────────────────

@injectable
class AddWaypointUseCase extends UseCase<WaypointEntity, AddWaypointParams> {
  final NavigationRepository repository;
  AddWaypointUseCase(this.repository);

  @override
  Future<Either<Failure, WaypointEntity>> call(AddWaypointParams params) {
    return repository.addWaypoint(
      tripId: params.tripId,
      name: params.name,
      position: params.position,
      note: params.note,
    );
  }
}

class AddWaypointParams extends Equatable {
  final String tripId;
  final String name;
  final GpsPoint position;
  final String? note;
  const AddWaypointParams({
    required this.tripId,
    required this.name,
    required this.position,
    this.note,
  });
  @override
  List<Object?> get props => [tripId, name];
}

// ─── UseCase 5: Get Track Points ──────────────────────────────────────────────

@injectable
class GetTrackPointsUseCase extends UseCase<List<GpsPoint>, String> {
  final NavigationRepository repository;
  GetTrackPointsUseCase(this.repository);

  @override
  Future<Either<Failure, List<GpsPoint>>> call(String tripId) {
    return repository.getTrackPoints(tripId);
  }
}

// ─── UseCase 6: Sync to Cloud ─────────────────────────────────────────────────

@injectable
class SyncNavigationDataUseCase extends UseCase<void, NoParams> {
  final NavigationRepository repository;
  SyncNavigationDataUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.syncPendingData();
  }
}
