import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/sos_entities.dart';
import '../repositories/sos_repository.dart';

// ─── UseCase 1: Tạo sự kiện SOS ────────────────────────────────────────────

@injectable
class CreateSosEventUseCase extends UseCase<SosEvent, SosEventParams> {
  final SosRepository repository;
  CreateSosEventUseCase(this.repository);

  @override
  Future<Either<Failure, SosEvent>> call(SosEventParams params) {
    return repository.createSosEvent(
      latitude: params.latitude,
      longitude: params.longitude,
      message: params.message,
    );
  }
}

class SosEventParams {
  final double? latitude;
  final double? longitude;
  final String? message;

  const SosEventParams({this.latitude, this.longitude, this.message});
}

// ─── UseCase 2: Lấy lịch sử SOS ────────────────────────────────────────────

@injectable
class GetSosEventsUseCase extends UseCase<List<SosEvent>, NoParams> {
  final SosRepository repository;
  GetSosEventsUseCase(this.repository);

  @override
  Future<Either<Failure, List<SosEvent>>> call(NoParams params) {
    return repository.getSosEvents();
  }
}

// ─── UseCase 3: Đồng bộ SOS ────────────────────────────────────────────────

@injectable
class SyncSosEventsUseCase extends UseCase<void, NoParams> {
  final SosRepository repository;
  SyncSosEventsUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.syncSosEvents();
  }
}

