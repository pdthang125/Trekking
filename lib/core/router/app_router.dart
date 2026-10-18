import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/first_aid/presentation/pages/first_aid_page.dart';
import '../../features/navigation/presentation/pages/navigation_page.dart';
import '../../features/trail/presentation/pages/trail_page.dart';
import '../../features/ai_assistant/presentation/pages/ai_assistant_page.dart';
import '../pages/home_page.dart';
import '../pages/splash_page.dart';

/// App-wide routing configuration using go_router
class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => const HomeDashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.firstAid,
            name: 'first_aid',
            builder: (context, state) => const FirstAidPage(),
          ),
          GoRoute(
            path: AppRoutes.navigation,
            name: 'navigation',
            builder: (context, state) => const NavigationPage(),
          ),
          GoRoute(
            path: AppRoutes.trail,
            name: 'trail',
            builder: (context, state) => const TrailPage(),
          ),
          GoRoute(
            path: AppRoutes.aiAssistant,
            name: 'ai_assistant',
            builder: (context, state) => const AiAssistantPage(),
          ),
        ],
      ),
    ],
  );
}

/// Route path constants
class AppRoutes {
  AppRoutes._();
  static const String splash = '/';
  static const String home = '/home';
  static const String firstAid = '/first-aid';
  static const String navigation = '/navigation';
  static const String trail = '/trail';
  static const String aiAssistant = '/ai-assistant';
}

/// Bottom navigation shell wrapper
class HomeScaffold extends StatefulWidget {
  final Widget child;
  const HomeScaffold({super.key, required this.child});

  @override
  State<HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends State<HomeScaffold> {
  int _selectedIndex = 0;

  final _tabs = const [
    (path: AppRoutes.home, icon: Icons.dashboard_rounded, label: 'Home'),
    (path: AppRoutes.firstAid, icon: Icons.medical_services_rounded, label: 'Sơ Cứu'),
    (path: AppRoutes.navigation, icon: Icons.map_rounded, label: 'Bản Đồ'),
    (path: AppRoutes.trail, icon: Icons.terrain_rounded, label: 'Lộ Trình'),
    (path: AppRoutes.aiAssistant, icon: Icons.auto_awesome_rounded, label: 'AI'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          context.go(_tabs[index].path);
        },
        destinations: _tabs.map((tab) => NavigationDestination(
          icon: Icon(tab.icon),
          label: tab.label,
        )).toList(),
      ),
    );
  }
}
