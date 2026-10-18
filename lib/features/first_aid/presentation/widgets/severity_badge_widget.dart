import 'package:flutter/material.dart';
import '../../domain/entities/first_aid_entities.dart';
import '../../../../core/theme/app_theme.dart';

/// Severity badge widget — Đỏ / Vàng / Xanh
class SeverityBadgeWidget extends StatelessWidget {
  final SeverityLevel level;
  final bool large;
  const SeverityBadgeWidget({super.key, required this.level, this.large = false});

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = switch (level) {
      SeverityLevel.danger => (AppTheme.dangerColor, 'NGUY HIỂM', Icons.warning_rounded),
      SeverityLevel.warning => (AppTheme.warningColor, 'CẦN CHÚ Ý', Icons.info_rounded),
      SeverityLevel.safe => (AppTheme.safeColor, 'TỰ XỬ LÝ', Icons.check_circle_rounded),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 10,
        vertical: large ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(large ? 12 : 20),
        border: Border.all(color: color.withAlpha(150), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: large ? 20 : 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: large ? 14 : 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
