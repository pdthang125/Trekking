import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/di/injection_container.dart' as di;
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/env/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with offline fallback
  try {
    if (!Env.supabaseUrl.contains('YOUR_PROJECT')) {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        anonKey: Env.supabaseAnonKey,
      );
    } else {
      debugPrint('ℹ️ [Offline Mode] Supabase URL chưa thiết lập. Khởi động ở chế độ 100% Ngoại tuyến.');
    }
  } catch (e) {
    debugPrint('⚠️ Không thể kết nối Supabase, chuyển sang chế độ ngoại tuyến: $e');
  }

  // Initialize Dependency Injection
  try {
    await di.init();
  } catch (e) {
    debugPrint('ℹ️ DI Init status: $e');
  }

  runApp(const TrekGuardApp());
}

class TrekGuardApp extends StatelessWidget {
  const TrekGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TrekGuard AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    );
  }
}
