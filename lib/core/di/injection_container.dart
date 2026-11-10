import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'injection_container.config.dart';

final GetIt sl = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> init() async {
  // ─── External / Third-party dependencies ─────────────────────
  // Connectivity — phát hiện trạng thái mạng
  sl.registerLazySingleton<Connectivity>(() => Connectivity());

  // Supabase — chỉ đăng ký nếu đã được khởi tạo thành công
  sl.registerLazySingleton<SupabaseClient>(() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      // Supabase chưa khởi tạo (Offline mode) — trả về client dummy
      // Các remote datasource sẽ bắt exception và fallback về local
      rethrow;
    }
  });

  // ─── Run injectable generated code ───────────────────────────
  await sl.init();
}
