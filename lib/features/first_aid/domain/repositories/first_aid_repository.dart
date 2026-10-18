import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/first_aid_entities.dart';

/// Repository contract for First Aid feature
/// Defined in Domain layer — implemented in Data layer
abstract class FirstAidRepository {
  /// Predict first aid guide from symptom text using on-device AI
  Future<Either<Failure, List<FirstAidGuide>>> predictFromSymptoms({
    required String symptomText,
    bool useOnDevice = true,
  });

  /// Get all available first aid guides (from local DB)
  Future<Either<Failure, List<FirstAidGuide>>> getAllGuides();

  /// Search guides by keyword
  Future<Either<Failure, List<FirstAidGuide>>> searchGuides(String query);

  /// Get a specific guide by ID
  Future<Either<Failure, FirstAidGuide>> getGuideById(String id);

  /// Get all symptom tags
  Future<Either<Failure, List<Symptom>>> getAllSymptoms();

  /// Check if local guide database is populated
  Future<bool> isLocalDataReady();

  /// Seed local database from bundled JSON assets
  Future<Either<Failure, void>> seedLocalDatabase();
}
