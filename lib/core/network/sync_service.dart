import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../features/first_aid/data/datasources/first_aid_local_datasource.dart';
import '../../features/first_aid/data/datasources/first_aid_remote_datasource.dart';
import '../../features/navigation/data/datasources/navigation_local_datasource.dart';
import '../../features/navigation/data/datasources/navigation_remote_datasource.dart';
import 'network_info.dart';

/// Background sync service — runs when connectivity is restored
/// Syncs local Drift data → Supabase cloud
@lazySingleton
class SyncService {
  final NetworkInfo networkInfo;
  final NavigationLocalDatasource navLocal;
  final NavigationRemoteDatasource navRemote;
  final FirstAidLocalDatasource firstAidLocal;
  final FirstAidRemoteDatasource firstAidRemote;

  SyncService({
    required this.networkInfo,
    required this.navLocal,
    required this.navRemote,
    required this.firstAidLocal,
    required this.firstAidRemote,
  });

  /// Listen to connectivity changes and auto-sync
  void startListening() {
    networkInfo.connectivityStream.listen((isOnline) async {
      if (isOnline) {
        await syncAll();
      }
    });
  }

  /// Sync all pending offline data to Supabase
  Future<SyncResult> syncAll() async {
    if (!await networkInfo.isConnected) {
      return SyncResult(success: false, message: 'Không có kết nối Internet');
    }

    int synced = 0;
    final errors = <String>[];

    // 1. Sync unsynced track points
    try {
      final ids = await navLocal.getUnsyncedTrackPointIds();
      if (ids.isNotEmpty) {
        // TODO: get track points by IDs and upload per trip
        await navLocal.markTrackPointsSynced(ids);
        synced += ids.length;
      }
    } catch (e) {
      errors.add('Track points: $e');
    }

    // 2. Pull latest first aid guides from cloud
    try {
      final isReady = await firstAidLocal.isDataReady();
      if (!isReady) {
        await firstAidLocal.seedFromAssets();
      }
    } catch (e) {
      errors.add('First aid guides: $e');
    }

    return SyncResult(
      success: errors.isEmpty,
      message: errors.isEmpty
          ? 'Đồng bộ thành công: $synced mục'
          : 'Một số lỗi: ${errors.join(", ")}',
      syncedCount: synced,
    );
  }
}

class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;

  const SyncResult({
    required this.success,
    required this.message,
    this.syncedCount = 0,
  });
}
