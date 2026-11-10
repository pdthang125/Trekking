import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/navigation_entities.dart';
import '../../domain/repositories/trip_repository.dart';
import '../datasources/trip_local_datasource.dart';
import '../datasources/trip_remote_datasource.dart';

/// Cài đặt TripRepository — Offline-First
@Injectable(as: TripRepository)
class TripRepositoryImpl implements TripRepository {
  final TripLocalDatasource localDatasource;
  final TripRemoteDatasource remoteDatasource;
  final NetworkInfo networkInfo;

  TripRepositoryImpl({
    required this.localDatasource,
    required this.remoteDatasource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, TripEntity>> createTrip({
    required String name,
    String? notes,
  }) async {
    try {
      final trip = await localDatasource.createTrip(name: name, notes: notes);
      return Right(trip);
    } catch (e) {
      return Left(CacheFailure(message: 'Không thể tạo chuyến đi: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TripEntity>>> getAllTrips() async {
    try {
      final trips = await localDatasource.getAllTrips();
      return Right(trips);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TripEntity>> getTripById(String id) async {
    try {
      final trip = await localDatasource.getTripById(id);
      if (trip == null) {
        return const Left(CacheFailure(message: 'Không tìm thấy chuyến đi'));
      }
      return Right(trip);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TripEntity?>> getActiveTrip() async {
    try {
      final trip = await localDatasource.getActiveTrip();
      return Right(trip);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateTrip({
    required String id,
    String? name,
    String? notes,
    double? totalDistanceKm,
    double? maxAltitude,
  }) async {
    try {
      await localDatasource.updateTrip(
        id: id,
        name: name,
        notes: notes,
        totalDistanceKm: totalDistanceKm,
        maxAltitude: maxAltitude,
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> endTrip(String id) async {
    try {
      await localDatasource.endTrip(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTrip(String id) async {
    try {
      await localDatasource.softDeleteTrip(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncTrips() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final unsynced = await localDatasource.getUnsyncedTrips();
      for (final trip in unsynced) {
        await remoteDatasource.uploadTrip(trip);
        await localDatasource.markTripSynced(trip.id);
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Đồng bộ chuyến đi thất bại: $e'));
    }
  }

  @override
  Future<Either<Failure, TripSummary>> getTripSummary(String tripId) async {
    try {
      final trackPointCount = await localDatasource.countTrackPoints(tripId);
      final waypointCount = await localDatasource.countWaypoints(tripId);
      final trip = await localDatasource.getTripById(tripId);

      if (trip == null) {
        return const Left(CacheFailure(message: 'Không tìm thấy chuyến đi'));
      }

      // Tính duration
      Duration? duration;
      if (trip.startedAt != null) {
        final end = trip.endedAt ?? DateTime.now();
        duration = end.difference(trip.startedAt!);
      }

      return Right(TripSummary(
        trip: trip,
        trackPointCount: trackPointCount,
        waypointCount: waypointCount,
        duration: duration,
      ));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}

