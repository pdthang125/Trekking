import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/first_aid_bloc.dart';
import '../widgets/symptom_input_widget.dart';
import '../widgets/guide_card_widget.dart';
import '../widgets/severity_badge_widget.dart';
import '../../../../core/theme/app_theme.dart';

/// Main First Aid screen — AI symptom prediction + guide listing
class FirstAidPage extends StatelessWidget {
  const FirstAidPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏥 Sơ Cứu Khẩn Cấp'),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded),
            tooltip: 'Đọc hướng dẫn',
            onPressed: () {},
          ),
        ],
      ),
      body: BlocBuilder<FirstAidBloc, FirstAidState>(
        builder: (context, state) {
          return Column(
            children: [
              // ── Connectivity Banner ──────────────────────────
              _ConnectivityBanner(),

              // ── Symptom Input Area ───────────────────────────
              const SymptomInputWidget(),

              // ── Content Area ─────────────────────────────────
              Expanded(
                child: switch (state) {
                  FirstAidInitial() => _EmptyStateWidget(),
                  FirstAidLoading() => _LoadingWidget(),
                  FirstAidLoaded s => _GuidesListWidget(guides: s.guides),
                  FirstAidError s => _ErrorWidget(message: s.message),
                  _ => const SizedBox.shrink(),
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ConnectivityBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: Connect to NetworkInfo stream
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.safeColor.withAlpha(30),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 14, color: AppTheme.safeColor),
          const SizedBox(width: 8),
          Text(
            '✅ Chế độ Offline — AI chạy hoàn toàn trên thiết bị',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.safeColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.health_and_safety_rounded,
                size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Nhập triệu chứng để AI phân tích',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Hoặc nói vào micro để nhận hướng dẫn sơ cứu ngay lập tức',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'AI đang phân tích triệu chứng...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _GuidesListWidget extends StatelessWidget {
  final dynamic guides;
  const _GuidesListWidget({required this.guides});

  @override
  Widget build(BuildContext context) {
    if (guides.isEmpty) {
      return Center(
        child: Text(
          'Không tìm thấy kết quả phù hợp',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: guides.length,
      itemBuilder: (_, i) => GuideCardWidget(guide: guides[i]),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  const _ErrorWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: AppTheme.dangerColor),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
