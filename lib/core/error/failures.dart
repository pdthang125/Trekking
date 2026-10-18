import 'package:equatable/equatable.dart';

/// Base class for all domain entities
abstract class Entity extends Equatable {
  const Entity();
}

/// Base class for all domain failures
abstract class Failure extends Equatable {
  final String message;
  const Failure({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Network failures
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'Không có kết nối Internet'});
}

/// Server failures
class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure({required super.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

/// Cache / Local DB failures
class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Lỗi cơ sở dữ liệu cục bộ'});
}

/// AI model inference failures
class AIInferenceFailure extends Failure {
  const AIInferenceFailure({super.message = 'Không thể chạy mô hình AI'});
}

/// GPS / Location failures
class LocationFailure extends Failure {
  const LocationFailure({super.message = 'Không thể lấy vị trí GPS'});
}

/// Permission denied
class PermissionFailure extends Failure {
  const PermissionFailure({super.message = 'Quyền truy cập bị từ chối'});
}
