import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/auth_entities.dart';

/// Repository contract cho Authentication
abstract class AuthRepository {
  /// Kiểm tra trạng thái đăng nhập hiện tại
  Future<Either<Failure, UserProfile?>> getCurrentUser();

  /// Đăng nhập bằng email/password
  Future<Either<Failure, UserProfile>> loginWithEmail({
    required String email,
    required String password,
  });

  /// Đăng ký tài khoản mới
  Future<Either<Failure, UserProfile>> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  });

  /// Đăng xuất
  Future<Either<Failure, void>> logout();

  /// Cập nhật profile
  Future<Either<Failure, void>> updateProfile({
    String? displayName,
    String? avatarUrl,
  });
}

