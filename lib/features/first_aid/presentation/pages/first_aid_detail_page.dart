import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../first_aid/domain/entities/first_aid_entities.dart';
import '../pages/first_aid_detail_page.dart';
import '../bloc/first_aid_bloc.dart';
import '../widgets/severity_badge_widget.dart';

/// Detailed guide page — step by step with TTS
class FirstAidDetailPage extends StatelessWidget {
  final FirstAidGuide guide;
  const FirstAidDetailPage({super.key, required this.guide});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(guide.conditionNameVi),
        actions: [
          BlocBuilder<FirstAidBlocHandler, FirstAidState>(
            builder: (context, state) {
              final isSpeaking = state is FirstAidSpeaking;
              return IconButton(
                icon: Icon(isSpeaking
                    ? Icons.stop_circle_rounded
                    : Icons.volume_up_rounded),
                tooltip: isSpeaking ? 'Dừng đọc' : 'Đọc hướng dẫn',
                onPressed: () {
                  if (isSpeaking) {
                    context.read<FirstAidBlocHandler>().add(const StopSpeakingEvent());
                  } else {
                    context.read<FirstAidBlocHandler>().add(SpeakGuideEvent(guide: guide));
                  }
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Severity Badge ─────────────────────────────────
            SeverityBadgeWidget(level: guide.severity, large: true),
            const SizedBox(height: 16),

            // ── Description ────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mô tả', style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    )),
                    const SizedBox(height: 8),
                    Text(guide.descriptionVi, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Steps ──────────────────────────────────────────
            Text('Các bước sơ cứu', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            BlocBuilder<FirstAidBlocHandler, FirstAidState>(
              builder: (context, state) {
                final currentStep = state is FirstAidSpeaking ? state.currentStep : -1;
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: guide.steps.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _StepCard(
                    step: guide.steps[i],
                    isActive: i == currentStep,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // ── Do NOT list ────────────────────────────────────
            if (guide.doNotsVi.isNotEmpty) ...[
              Text('⛔ Không được làm', style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.dangerColor,
              )),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: guide.doNotsVi.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.cancel_rounded,
                              color: AppTheme.dangerColor, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(d)),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Evacuation indicator ───────────────────────────
            if (guide.whenToEvacuateVi != null) ...[
              Card(
                color: AppTheme.dangerColor.withAlpha(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.emergency_rounded,
                          color: AppTheme.dangerColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Khi nào cần di tản?',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: AppTheme.dangerColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(guide.whenToEvacuateVi!),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final FirstAidStep step;
  final bool isActive;
  const _StepCard({required this.step, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isActive
        ? theme.colorScheme.primary
        : step.isWarning
            ? AppTheme.warningColor
            : theme.colorScheme.outline;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: isActive ? 2 : 1),
        color: isActive
            ? theme.colorScheme.primary.withAlpha(15)
            : theme.colorScheme.surfaceContainerHighest,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: isActive
                  ? theme.colorScheme.primary
                  : step.isWarning
                      ? AppTheme.warningColor
                      : theme.colorScheme.outline.withAlpha(100),
              child: Text(
                '${step.stepNumber}',
                style: TextStyle(
                  color: isActive || step.isWarning ? Colors.black : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                step.instructionVi,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
