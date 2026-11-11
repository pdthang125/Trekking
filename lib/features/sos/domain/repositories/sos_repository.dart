import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/sos_entities.dart';

/// Repository contract cho SOS feature
abstract class SosRepository {
  /// Tạo sự kiện SOS mới
  Future<Either<Failure, SosEvent>> createSosEvent({
    double? latitude,
    double? longitude,
    String? message,
  });

  /// Lấy danh sách sự kiện SOS
  Future<Either<Failure, List<SosEvent>>> getSosEvents();

  /// Cập nhật trạng thái SOS
  Future<Either<Failure, void>> updateSosStatus({
    required String id,
    required SosStatus status,
  });

  /// Đồng bộ SOS events lên cloud
  Future<Either<Failure, void>> syncSosEvents();
}

