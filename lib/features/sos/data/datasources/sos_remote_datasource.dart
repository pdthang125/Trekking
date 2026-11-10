import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/sos_entities.dart';

/// Remote datasource cho SOS Events — Supabase PostGIS
@injectable
class SosRemoteDatasource {
  final SupabaseClient _client;
  final Logger _logger = Logger();
  static const String _tag = 'SosRemoteDatasource';

  SosRemoteDatasource(this._client);

  /// Tải sự kiện SOS lên Supabase
  Future<void> uploadSosEvent(SosEvent event) async {
    try {
      final data = <String, dynamic>{
        'id': event.id,
        'user_id': _client.auth.currentUser?.id,
        'message': event.message,
        'status': event.status.name,
        'created_at': event.createdAt.toIso8601String(),
      };

      // Thêm PostGIS location nếu có
      if (event.latitude != null && event.longitude != null) {
        data['location'] = 'POINT(${event.longitude} ${event.latitude})';
        data['location_time'] = event.locationTime?.toIso8601String();
      }

      await _client.from('sos_events').upsert(data);
      _logger.i('[$_tag] ✅ SOS event uploaded: ${event.id}');
    } catch (e) {
      _logger.e('[$_tag] ❌ Upload SOS failed: $e');
      rethrow;
    }
  }

  /// Lấy lịch sử SOS từ server
  Future<List<SosEvent>> getSosEvents() async {
    final response = await _client
        .from('sos_events')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((row) {
      final map = row as Map<String, dynamic>;
      return SosEvent(
        id: map['id'] as String,
        message: map['message'] as String?,
        status: _parseStatus(map['status'] as String?),
        createdAt: DateTime.parse(map['created_at'] as String),
        synced: true,
      );
    }).toList();
  }

  SosStatus _parseStatus(String? s) => switch (s) {
        'resolved' => SosStatus.resolved,
        'false_alarm' => SosStatus.falseAlarm,
        _ => SosStatus.active,
      };
}

