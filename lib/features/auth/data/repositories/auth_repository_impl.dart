import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/auth_entities.dart';
import '../../domain/repositories/auth_repository.dart';

/// Cài đặt AuthRepository — Supabase Auth
@Injectable(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _client;

  AuthRepositoryImpl(this._client);

  @override
  Future<Either<Failure, UserProfile?>> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return const Right(null);
      return Right(_mapUser(user));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        return const Left(ServerFailure(message: 'Đăng nhập thất bại'));
      }
      return Right(_mapUser(response.user!));
    } on AuthException catch (e) {
      return Left(ServerFailure(message: _translateError(e.message)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName ?? email.split('@')[0]},
      );
      if (response.user == null) {
        return const Left(ServerFailure(message: 'Đăng ký thất bại'));
      }
      return Right(_mapUser(response.user!));
    } on AuthException catch (e) {
      return Left(ServerFailure(message: _translateError(e.message)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _client.auth.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Left(ServerFailure(message: 'Chưa đăng nhập'));
      }

      final updates = <String, dynamic>{};
      if (displayName != null) updates['display_name'] = displayName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      if (updates.isNotEmpty) {
        await _client.from('profiles').update(updates).eq('id', userId);
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ─── Private helpers ──────────────────────────────────────

  UserProfile _mapUser(User user) {
    return UserProfile(
      id: user.id,
      displayName: user.userMetadata?['display_name'] as String?,
      email: user.email,
      avatarUrl: user.userMetadata?['avatar_url'] as String?,
      createdAt: DateTime.tryParse(user.createdAt),
    );
  }

  String _translateError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Email hoặc mật khẩu không đúng';
    }
    if (message.contains('Email not confirmed')) {
      return 'Vui lòng xác nhận email trước khi đăng nhập';
    }
    if (message.contains('User already registered')) {
      return 'Email này đã được đăng ký';
    }
    if (message.contains('Password should be at least')) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return message;
  }
}

