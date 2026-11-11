import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

/// Entity sự kiện SOS khẩn cấp
class SosEvent {
  final String id;
  final double? latitude;
  final double? longitude;
  final DateTime? locationTime;
  final String? message;
  final SosStatus status;
  final DateTime createdAt;
  final bool synced;

  const SosEvent({
    required this.id,
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.locationTime,
    this.message,
    this.status = SosStatus.active,
    this.synced = false,
  });
}

enum SosStatus { active, resolved, falseAlarm }

