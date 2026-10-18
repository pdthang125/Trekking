import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/first_aid_entities.dart';
import '../repositories/first_aid_repository.dart';

// ─── UseCase 1: Predict First Aid from symptoms ─────────────────────────────

@injectable
class PredictFirstAidUseCase extends UseCase<List<FirstAidGuide>, PredictParams> {
  final FirstAidRepository repository;

  PredictFirstAidUseCase(this.repository);

  @override
  Future<Either<Failure, List<FirstAidGuide>>> call(PredictParams params) {
    return repository.predictFromSymptoms(
      symptomText: params.symptomText,
      useOnDevice: params.useOnDevice,
    );
  }
}

class PredictParams extends Equatable {
  final String symptomText;
  final bool useOnDevice;

  const PredictParams({
    required this.symptomText,
    this.useOnDevice = true,
  });

  @override
  List<Object?> get props => [symptomText, useOnDevice];
}

// ─── UseCase 2: Get All First Aid Guides ─────────────────────────────────────

@injectable
class GetAllFirstAidGuidesUseCase extends UseCase<List<FirstAidGuide>, NoParams> {
  final FirstAidRepository repository;

  GetAllFirstAidGuidesUseCase(this.repository);

  @override
  Future<Either<Failure, List<FirstAidGuide>>> call(NoParams params) {
    return repository.getAllGuides();
  }
}

// ─── UseCase 3: Search First Aid Guides ─────────────────────────────────────

@injectable
class SearchFirstAidGuidesUseCase extends UseCase<List<FirstAidGuide>, String> {
  final FirstAidRepository repository;

  SearchFirstAidGuidesUseCase(this.repository);

  @override
  Future<Either<Failure, List<FirstAidGuide>>> call(String query) {
    return repository.searchGuides(query);
  }
}

// ─── UseCase 4: Get Guide by ID ───────────────────────────────────────────

@injectable
class GetFirstAidGuideByIdUseCase extends UseCase<FirstAidGuide, String> {
  final FirstAidRepository repository;

  GetFirstAidGuideByIdUseCase(this.repository);

  @override
  Future<Either<Failure, FirstAidGuide>> call(String id) {
    return repository.getGuideById(id);
  }
}

// ─── UseCase 5: Seed Local DB ────────────────────────────────────────────

@injectable
class SeedFirstAidDatabaseUseCase extends UseCase<void, NoParams> {
  final FirstAidRepository repository;

  SeedFirstAidDatabaseUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.seedLocalDatabase();
  }
}
