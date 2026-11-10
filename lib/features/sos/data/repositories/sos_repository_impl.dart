import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/sos_entities.dart';
import '../../domain/repositories/sos_repository.dart';
import '../datasources/sos_local_datasource.dart';
import '../datasources/sos_remote_datasource.dart';

/// Cài đặt SosRepository — Offline-First
@Injectable(as: SosRepository)
class SosRepositoryImpl implements SosRepository {
  final SosLocalDatasource localDatasource;
  final SosRemoteDatasource remoteDatasource;
  final NetworkInfo networkInfo;

  SosRepositoryImpl({
    required this.localDatasource,
    required this.remoteDatasource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, SosEvent>> createSosEvent({
    double? latitude,
    double? longitude,
    String? message,
  }) async {
    try {
      final event = await localDatasource.createEvent(
        latitude: latitude,
        longitude: longitude,
        message: message,
      );

      // Cố gắng đẩy lên server ngay nếu có mạng (SOS rất quan trọng)
      if (await networkInfo.isConnected) {
        try {
          await remoteDatasource.uploadSosEvent(event);
          await localDatasource.markSynced(event.id);
        } catch (_) {
          // Đẩy lên thất bại — sẽ sync sau
        }
      }

      return Right(event);
    } catch (e) {
      return Left(CacheFailure(message: 'Không thể tạo SOS event: $e'));
    }
  }

  @override
  Future<Either<Failure, List<SosEvent>>> getSosEvents() async {
    try {
      final events = await localDatasource.getAllEvents();
      return Right(events);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateSosStatus({
    required String id,
    required SosStatus status,
  }) async {
    // Hiện tại chỉ cần đánh dấu resolved ở server
    try {
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncSosEvents() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final unsynced = await localDatasource.getUnsyncedEvents();
      for (final event in unsynced) {
        await remoteDatasource.uploadSosEvent(event);
        await localDatasource.markSynced(event.id);
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Đồng bộ SOS thất bại: $e'));
    }
  }
}

