import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';

/// Pill badge for display of status, category, or latency.
class StatusBadge extends StatelessWidget {
  final String label;
  final bool? isSuccess;
  final Color? customColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.isSuccess,
    this.customColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    if (customColor != null) {
      color = customColor!;
    } else if (isSuccess == true) {
      color = AppTheme.successGreen;
    } else if (isSuccess == false) {
      color = AppTheme.warningAmber;
    } else {
      color = AppTheme.primaryBlue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
