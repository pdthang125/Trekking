import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/navigation_entities.dart';
import '../repositories/trip_repository.dart';

// ─── UseCase 1: Tạo chuyến đi mới ──────────────────────────────────────────

@injectable
class CreateTripUseCase extends UseCase<TripEntity, CreateTripParams> {
  final TripRepository repository;
  CreateTripUseCase(this.repository);

  @override
  Future<Either<Failure, TripEntity>> call(CreateTripParams params) {
    return repository.createTrip(name: params.name, notes: params.notes);
  }
}

class CreateTripParams extends Equatable {
  final String name;
  final String? notes;
  const CreateTripParams({required this.name, this.notes});
  @override
  List<Object?> get props => [name];
}

// ─── UseCase 2: Lấy tất cả chuyến đi ───────────────────────────────────────

@injectable
class GetAllTripsUseCase extends UseCase<List<TripEntity>, NoParams> {
  final TripRepository repository;
  GetAllTripsUseCase(this.repository);

  @override
  Future<Either<Failure, List<TripEntity>>> call(NoParams params) {
    return repository.getAllTrips();
  }
}

// ─── UseCase 3: Lấy chuyến đi đang hoạt động ───────────────────────────────

@injectable
class GetActiveTripUseCase extends UseCase<TripEntity?, NoParams> {
  final TripRepository repository;
  GetActiveTripUseCase(this.repository);

  @override
  Future<Either<Failure, TripEntity?>> call(NoParams params) {
    return repository.getActiveTrip();
  }
}

// ─── UseCase 4: Kết thúc chuyến đi ─────────────────────────────────────────

@injectable
class EndTripUseCase extends UseCase<void, String> {
  final TripRepository repository;
  EndTripUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String tripId) {
    return repository.endTrip(tripId);
  }
}

// ─── UseCase 5: Xoá chuyến đi ──────────────────────────────────────────────

@injectable
class DeleteTripUseCase extends UseCase<void, String> {
  final TripRepository repository;
  DeleteTripUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String tripId) {
    return repository.deleteTrip(tripId);
  }
}

// ─── UseCase 6: Lấy thống kê chuyến đi ─────────────────────────────────────

@injectable
class GetTripSummaryUseCase extends UseCase<TripSummary, String> {
  final TripRepository repository;
  GetTripSummaryUseCase(this.repository);

  @override
  Future<Either<Failure, TripSummary>> call(String tripId) {
    return repository.getTripSummary(tripId);
  }
}

// ─── UseCase 7: Đồng bộ chuyến đi lên cloud ────────────────────────────────

@injectable
class SyncTripsUseCase extends UseCase<void, NoParams> {
  final TripRepository repository;
  SyncTripsUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.syncTrips();
  }
}

