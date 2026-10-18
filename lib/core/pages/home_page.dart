import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';

/// Splash screen — shown on app start
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _animController.forward();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1320),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo Icon ──────────────────────────────────
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.safeColor,
                        AppTheme.safeColor.withAlpha(180),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.safeColor.withAlpha(100),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.terrain_rounded,
                    size: 52,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),

                // ── App Name ───────────────────────────────────
                const Text(
                  'TrekGuard AI',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Người đồng hành leo núi thông minh',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    color: Colors.white.withAlpha(180),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 48),

                // ── Loading indicator ───────────────────────────
                SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(
                    color: AppTheme.safeColor,
                    backgroundColor: Colors.white.withAlpha(30),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Đang tải dữ liệu offline...',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: Colors.white.withAlpha(120),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }
}

/// Home Dashboard — Quick access to all features
class HomeDashboardPage extends StatelessWidget {
  const HomeDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar ────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.download_for_offline_rounded, color: Colors.white70),
                tooltip: 'Bản đồ ngoại tuyến',
                onPressed: () => context.push(AppRoutes.offlineMaps),
              ),
              IconButton(
                icon: const Icon(Icons.emergency_rounded, color: AppTheme.dangerColor),
                tooltip: 'Cứu nạn SOS',
                onPressed: () => context.push(AppRoutes.sos),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'TrekGuard AI',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0F1320),
                      AppTheme.safeColor.withAlpha(80),
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.terrain_rounded,
                    size: 60,
                    color: Colors.white24,
                  ),
                ),
              ),
            ),
          ),

          // ── SOS Quick Emergency Banner ──────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.push(AppRoutes.sos),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.dangerColor.withAlpha(100)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.emergency_rounded, color: AppTheme.dangerColor, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TRUNG TÂM CỨU NẠN SOS',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Toạ độ GPS ngoại tuyến, chớp đèn Flash mã Morse, còi hú',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.dangerColor, size: 14),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Quick Action Grid ────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              delegate: SliverChildListDelegate([
                _QuickActionCard(
                  icon: Icons.medical_services_rounded,
                  label: 'Sơ Cứu AI',
                  subtitle: 'Hướng dẫn offline',
                  color: AppTheme.dangerColor,
                  route: AppRoutes.firstAid,
                ),
                _QuickActionCard(
                  icon: Icons.map_rounded,
                  label: 'Bản Đồ',
                  subtitle: 'Định vị GPS',
                  color: AppTheme.infoColor,
                  route: AppRoutes.navigation,
                ),
                _QuickActionCard(
                  icon: Icons.terrain_rounded,
                  label: 'Lộ Trình',
                  subtitle: 'Đồ thị độ cao',
                  color: AppTheme.accentColor,
                  route: AppRoutes.trail,
                ),
                _QuickActionCard(
                  icon: Icons.auto_awesome_rounded,
                  label: 'AI Chat',
                  subtitle: 'Gemini powered',
                  color: AppTheme.safeColor,
                  route: AppRoutes.aiAssistant,
                ),
              ]),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
            ),
          ),

          // ── Status Banner ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: const BoxDecoration(
                          color: AppTheme.safeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chế độ Offline sẵn sàng',
                              style: theme.textTheme.titleSmall,
                            ),
                            Text(
                              'AI sơ cứu + Bản đồ đã được tải về thiết bị',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withAlpha(150),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final String route;
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go(route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
