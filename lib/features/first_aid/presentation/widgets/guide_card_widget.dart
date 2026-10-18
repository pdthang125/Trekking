import 'package:flutter/material.dart';
import '../../domain/entities/first_aid_entities.dart';
import '../../../../core/theme/app_theme.dart';

/// Card widget showing a first-aid guide summary
class GuideCardWidget extends StatelessWidget {
  final FirstAidGuide guide;
  const GuideCardWidget({super.key, required this.guide});

  Color _severityColor(SeverityLevel level) => switch (level) {
    SeverityLevel.danger => AppTheme.dangerColor,
    SeverityLevel.warning => AppTheme.warningColor,
    SeverityLevel.safe => AppTheme.safeColor,
  };

  String _severityLabel(SeverityLevel level) => switch (level) {
    SeverityLevel.danger => '🔴 NGUY HIỂM',
    SeverityLevel.warning => '🟡 CẦN CHÚ Ý',
    SeverityLevel.safe => '🟢 TỰ XỬ LÝ',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _severityColor(guide.severity);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: Navigate to guide detail page
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      guide.conditionNameVi,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withAlpha(100)),
                    ),
                    child: Text(
                      _severityLabel(guide.severity),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: color, fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Description ─────────────────────────────────
              Text(
                guide.descriptionVi,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(180),
                ),
              ),
              const SizedBox(height: 12),

              // ── Footer ───────────────────────────────────────
              Row(
                children: [
                  Icon(Icons.format_list_numbered_rounded,
                      size: 14,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${guide.steps.length} bước',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (guide.confidenceScore > 0) ...[
                    Icon(Icons.psychology_rounded,
                        size: 14,
                        color: theme.colorScheme.secondary),
                    const SizedBox(width: 4),
                    Text(
                      'AI: ${(guide.confidenceScore * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded,
                      color: theme.colorScheme.onSurface.withAlpha(100)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
