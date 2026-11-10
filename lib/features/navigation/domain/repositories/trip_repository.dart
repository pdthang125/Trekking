import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/navigation_entities.dart';

/// Repository contract cho Trip management
/// Defined in Domain layer — implemented in Data layer
abstract class TripRepository {
  /// Tạo chuyến đi mới
  Future<Either<Failure, TripEntity>> createTrip({
    required String name,
    String? notes,
  });

  /// Lấy tất cả chuyến đi
  Future<Either<Failure, List<TripEntity>>> getAllTrips();

  /// Lấy chuyến đi theo ID
  Future<Either<Failure, TripEntity>> getTripById(String id);

  /// Lấy chuyến đi đang hoạt động
  Future<Either<Failure, TripEntity?>> getActiveTrip();

  /// Cập nhật chuyến đi
  Future<Either<Failure, void>> updateTrip({
    required String id,
    String? name,
    String? notes,
    double? totalDistanceKm,
    double? maxAltitude,
  });

  /// Kết thúc chuyến đi
  Future<Either<Failure, void>> endTrip(String id);

  /// Xoá chuyến đi
  Future<Either<Failure, void>> deleteTrip(String id);

  /// Đồng bộ chuyến đi lên cloud
  Future<Either<Failure, void>> syncTrips();

  /// Lấy thông tin tóm tắt chuyến đi
  Future<Either<Failure, TripSummary>> getTripSummary(String tripId);
}

