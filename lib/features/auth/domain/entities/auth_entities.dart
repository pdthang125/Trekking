import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

/// Entity người dùng
class UserProfile {
  final String id;
  final String? displayName;
  final String? email;
  final String? avatarUrl;
  final bool isAnonymous;
  final DateTime? createdAt;

  const UserProfile({
    required this.id,
    this.displayName,
    this.email,
    this.avatarUrl,
    this.isAnonymous = false,
    this.createdAt,
  });
}

