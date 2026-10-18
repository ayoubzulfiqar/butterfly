import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';

/// Warning banner displayed when the application is run without
/// Windows Administrator privileges.
class ElevationBanner extends StatelessWidget {
  final bool isElevated;

  const ElevationBanner({super.key, required this.isElevated});

  @override
  Widget build(BuildContext context) {
    if (isElevated) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.warningAmber.withValues(alpha: 0.12),
        border: const Border(
          bottom: BorderSide(color: AppTheme.warningAmber, width: 1),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, color: AppTheme.warningAmber, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Running with standard privileges. Changing DNS settings or running '
              'DPI bypass requires Administrator privileges.',
              style: TextStyle(
                color: AppTheme.warningAmber,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
