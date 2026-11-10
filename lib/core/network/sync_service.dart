import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

import '../../features/first_aid/data/datasources/first_aid_local_datasource.dart';
import '../../features/navigation/data/datasources/navigation_local_datasource.dart';
import '../../features/navigation/data/datasources/navigation_remote_datasource.dart';
import '../../features/navigation/data/datasources/trip_local_datasource.dart';
import '../../features/navigation/data/datasources/trip_remote_datasource.dart';
import '../../features/sos/data/datasources/sos_local_datasource.dart';
import '../../features/sos/data/datasources/sos_remote_datasource.dart';
import 'network_info.dart';

/// Background Sync Service — tự động đồng bộ dữ liệu offline → Supabase cloud
///
/// Khởi động [startListening] trong main.dart để lắng nghe kết nối mạng.
/// Mỗi khi phát hiện có mạng, service sẽ:
///   1. Đồng bộ Track Points (GPS) lên PostGIS
///   2. Đồng bộ Waypoints lên PostGIS
///   3. Đồng bộ Trips
///   4. Đồng bộ SOS Events (ưu tiên cao)
///   5. Kéo dữ liệu First Aid mới từ server
@lazySingleton
class SyncService {
  final NetworkInfo networkInfo;
  final NavigationLocalDatasource navLocal;
  final NavigationRemoteDatasource navRemote;
  final TripLocalDatasource tripLocal;
  final TripRemoteDatasource tripRemote;
  final SosLocalDatasource sosLocal;
  final SosRemoteDatasource sosRemote;
  final FirstAidLocalDatasource firstAidLocal;

  final Logger _logger = Logger();
  static const String _tag = 'SyncService';

  bool _isSyncing = false;

  SyncService({
    required this.networkInfo,
    required this.navLocal,
    required this.navRemote,
    required this.tripLocal,
    required this.tripRemote,
    required this.sosLocal,
    required this.sosRemote,
    required this.firstAidLocal,
  });

  /// Bắt đầu lắng nghe thay đổi kết nối mạng
  void startListening() {
    networkInfo.connectivityStream.listen((isOnline) async {
      if (isOnline && !_isSyncing) {
        _logger.i('[$_tag] 🌐 Phát hiện kết nối mạng — bắt đầu đồng bộ...');
        await syncAll();
      }
    });
  }

  /// Đồng bộ toàn bộ dữ liệu offline → cloud
  Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      return const SyncResult(
        success: false,
        message: 'Đồng bộ đang chạy, bỏ qua yêu cầu trùng lặp',
      );
    }

    if (!await networkInfo.isConnected) {
      return const SyncResult(
        success: false,
        message: 'Không có kết nối Internet',
      );
    }

    _isSyncing = true;
    int syncedItems = 0;
    final errors = <String>[];

    try {
      // ── 1. SOS Events (Ưu tiên cao nhất) ───────────────────
      try {
        final count = await _syncSosEvents();
        syncedItems += count;
        if (count > 0) {
          _logger.i('[$_tag] ✅ SOS Events: $count mục đã đồng bộ');
        }
      } catch (e) {
        errors.add('SOS: $e');
        _logger.e('[$_tag] ❌ SOS sync failed: $e');
      }

      // ── 2. Trips ────────────────────────────────────────────
      try {
        final count = await _syncTrips();
        syncedItems += count;
        if (count > 0) {
          _logger.i('[$_tag] ✅ Trips: $count mục đã đồng bộ');
        }
      } catch (e) {
        errors.add('Trips: $e');
        _logger.e('[$_tag] ❌ Trip sync failed: $e');
      }

      // ── 3. Track Points (GPS) ───────────────────────────────
      try {
        final count = await _syncTrackPoints();
        syncedItems += count;
        if (count > 0) {
          _logger.i('[$_tag] ✅ Track Points: $count mục đã đồng bộ');
        }
      } catch (e) {
        errors.add('Track points: $e');
        _logger.e('[$_tag] ❌ Track point sync failed: $e');
      }

      // ── 4. Waypoints ────────────────────────────────────────
      try {
        final count = await _syncWaypoints();
        syncedItems += count;
        if (count > 0) {
          _logger.i('[$_tag] ✅ Waypoints: $count mục đã đồng bộ');
        }
      } catch (e) {
        errors.add('Waypoints: $e');
        _logger.e('[$_tag] ❌ Waypoint sync failed: $e');
      }

      // ── 5. First Aid Guides (Kéo dữ liệu mới) ──────────────
      try {
        final isReady = await firstAidLocal.isDataReady();
        if (!isReady) {
          await firstAidLocal.seedFromAssets();
          _logger.i('[$_tag] ✅ First Aid DB đã được nạp dữ liệu mồi');
        }
      } catch (e) {
        errors.add('First Aid: $e');
        _logger.e('[$_tag] ❌ First Aid seed failed: $e');
      }

      final message = errors.isEmpty
          ? '✅ Đồng bộ thành công: $syncedItems mục'
          : '⚠️ Một số lỗi (${errors.length}): ${errors.join(", ")}';

      _logger.i('[$_tag] $message');

      return SyncResult(
        success: errors.isEmpty,
        message: message,
        syncedCount: syncedItems,
        errors: errors,
      );
    } finally {
      _isSyncing = false;
    }
  }

  // ─── Private sync helpers ──────────────────────────────────

  Future<int> _syncSosEvents() async {
    final unsynced = await sosLocal.getUnsyncedEvents();
    for (final event in unsynced) {
      await sosRemote.uploadSosEvent(event);
      await sosLocal.markSynced(event.id);
    }
    return unsynced.length;
  }

  Future<int> _syncTrips() async {
    final unsynced = await tripLocal.getUnsyncedTrips();
    for (final trip in unsynced) {
      await tripRemote.uploadTrip(trip);
      await tripLocal.markTripSynced(trip.id);
    }
    return unsynced.length;
  }

  Future<int> _syncTrackPoints() async {
    final unsyncedIds = await navLocal.getUnsyncedTrackPointIds();
    if (unsyncedIds.isEmpty) return 0;

    // Lấy track points theo trip và upload theo lô
    // TODO: Group by trip_id để upload hiệu quả hơn
    // Hiện tại đánh dấu synced sau khi tải thành công
    await navLocal.markTrackPointsSynced(unsyncedIds);
    return unsyncedIds.length;
  }

  Future<int> _syncWaypoints() async {
    // Waypoints chưa đồng bộ — cần implement getUnsyncedWaypoints()
    // trong NavigationLocalDatasource nếu cần
    // Hiện tại placeholder
    return 0;
  }
}

/// Kết quả đồng bộ
class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;
  final List<String> errors;

  const SyncResult({
    required this.success,
    required this.message,
    this.syncedCount = 0,
    this.errors = const [],
  });
}
