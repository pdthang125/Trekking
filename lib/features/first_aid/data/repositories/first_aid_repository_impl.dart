import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/first_aid_entities.dart';
import '../../domain/repositories/first_aid_repository.dart';
import '../datasources/first_aid_local_datasource.dart';
import '../datasources/first_aid_remote_datasource.dart';
import '../../../../core/network/network_info.dart';

@Injectable(as: FirstAidRepository)
class FirstAidRepositoryImpl implements FirstAidRepository {
  final FirstAidLocalDatasource localDatasource;
  final FirstAidRemoteDatasource remoteDatasource;
  final NetworkInfo networkInfo;

  FirstAidRepositoryImpl({
    required this.localDatasource,
    required this.remoteDatasource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<FirstAidGuide>>> predictFromSymptoms({
    required String symptomText,
    bool useOnDevice = true,
  }) async {
    try {
      // Always try local first (offline-first)
      final results = await localDatasource.searchBySymptoms(symptomText);
      if (results.isNotEmpty) return Right(results);

      // Fallback to remote if online and local has no match
      if (!useOnDevice && await networkInfo.isConnected) {
        final remote = await remoteDatasource.predictFromSymptoms(symptomText);
        return Right(remote);
      }

      return const Right([]);
    } catch (e) {
      return Left(AIInferenceFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FirstAidGuide>>> getAllGuides() async {
    try {
      final guides = await localDatasource.getAllGuides();
      return Right(guides);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FirstAidGuide>>> searchGuides(String query) async {
    try {
      final guides = await localDatasource.searchGuides(query);
      return Right(guides);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, FirstAidGuide>> getGuideById(String id) async {
    try {
      final guide = await localDatasource.getGuideById(id);
      if (guide == null) return const Left(CacheFailure(message: 'Không tìm thấy hướng dẫn'));
      return Right(guide);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Symptom>>> getAllSymptoms() async {
    try {
      final symptoms = await localDatasource.getAllSymptoms();
      return Right(symptoms);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<bool> isLocalDataReady() => localDatasource.isDataReady();

  @override
  Future<Either<Failure, void>> seedLocalDatabase() async {
    try {
      await localDatasource.seedFromAssets();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}
