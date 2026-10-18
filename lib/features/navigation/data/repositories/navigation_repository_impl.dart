import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/navigation_entities.dart';
import '../../domain/repositories/navigation_repository.dart';
import '../datasources/navigation_local_datasource.dart';
import '../datasources/navigation_remote_datasource.dart';

@Injectable(as: NavigationRepository)
class NavigationRepositoryImpl implements NavigationRepository {
  final NavigationLocalDatasource localDatasource;
  final NavigationRemoteDatasource remoteDatasource;
  final NetworkInfo networkInfo;

  NavigationRepositoryImpl({
    required this.localDatasource,
    required this.remoteDatasource,
    required this.networkInfo,
  });

  @override
  Stream<Either<Failure, GpsPoint>> startTracking({int intervalSeconds = 10}) {
    return localDatasource.startLocationStream(intervalSeconds: intervalSeconds).map(
      (point) => Right<Failure, GpsPoint>(point),
    ).handleError((e) => Left<Failure, GpsPoint>(LocationFailure(message: e.toString())));
  }

  @override
  Future<void> stopTracking() => localDatasource.stopLocationStream();

  @override
  Future<Either<Failure, GpsPoint>> getCurrentPosition() async {
    try {
      final point = await localDatasource.getCurrentPosition();
      return Right(point);
    } catch (e) {
      return Left(LocationFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveTrackPoint({required String tripId, required GpsPoint point}) async {
    try {
      await localDatasource.saveTrackPoint(tripId: tripId, point: point);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<GpsPoint>>> getTrackPoints(String tripId) async {
    try {
      final points = await localDatasource.getTrackPoints(tripId);
      return Right(points);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WaypointEntity>> addWaypoint({required String tripId, required String name, required GpsPoint position, String? note}) async {
    try {
      final wp = await localDatasource.addWaypoint(tripId: tripId, name: name, position: position, note: note);
      return Right(wp);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WaypointEntity>>> getWaypoints(String tripId) async {
    try {
      final wps = await localDatasource.getWaypoints(tripId);
      return Right(wps);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteWaypoint(String waypointId) async {
    try {
      await localDatasource.deleteWaypoint(waypointId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncPendingData() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      // Sync unsynced track points
      final unsyncedIds = await localDatasource.getUnsyncedTrackPointIds();
      if (unsyncedIds.isNotEmpty) {
        final points = await localDatasource.getTrackPoints(''); // TODO: get by IDs
        // await remoteDatasource.uploadTrackPoints(tripId: tripId, points: points);
        await localDatasource.markTrackPointsSynced(unsyncedIds);
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
