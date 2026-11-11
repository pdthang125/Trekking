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
  // External dependencies — đăng ký thủ công các type không có @injectable
  sl.registerLazySingleton<Connectivity>(() => Connectivity());

  // Chỉ đăng ký SupabaseClient nếu Supabase đã được khởi tạo
  try {
    sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  } catch (_) {
    // Supabase chưa init → bỏ qua, app chạy offline mode
  }

  // Run injectable generated code
  await sl.init();
}
