import 'package:flutter/material.dart';
import '../../core/theme/cyber_theme.dart';
import '../../domain/entities/zapret2_strategy.dart';

/// Horizontal segmented protection level selector with smooth gliding thumb.
class ProtectionLevelsBar extends StatelessWidget {
  final Zapret2Profile selectedProfile;
  final ValueChanged<Zapret2Profile> onProfileSelected;

  const ProtectionLevelsBar({
    super.key,
    required this.selectedProfile,
    required this.onProfileSelected,
  });

  static const List<_LevelItem> _items = [
    _LevelItem(profile: Zapret2Profile.light, label: 'Light', hint: 'Multi-split'),
    _LevelItem(profile: Zapret2Profile.medium, label: 'Medium', hint: 'Disorder'),
    _LevelItem(profile: Zapret2Profile.strong, label: 'Strong', hint: 'Fake TLS + QUIC'),
    _LevelItem(profile: Zapret2Profile.extreme, label: 'Extreme', hint: 'Auto-TTL Fake'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CyberTheme.surfaceTranslucent,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: CyberTheme.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _items.map((item) {
          final isSelected = item.profile == selectedProfile;
          return _LevelPill(
            item: item,
            isSelected: isSelected,
            onTap: () => onProfileSelected(item.profile),
          );
        }).toList(),
      ),
    );
  }
}

class _LevelItem {
  final Zapret2Profile profile;
  final String label;
  final String hint;

  const _LevelItem({
    required this.profile,
    required this.label,
    required this.hint,
  });
}

class _LevelPill extends StatefulWidget {
  final _LevelItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _LevelPill({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_LevelPill> createState() => _LevelPillState();
}

class _LevelPillState extends State<_LevelPill> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? CyberTheme.neonEmerald.withOpacity(0.18)
                : (_isHovered ? Colors.white.withOpacity(0.05) : Colors.transparent),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? CyberTheme.neonEmerald : Colors.transparent,
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: CyberTheme.neonEmerald.withOpacity(0.25),
                      blurRadius: 12,
                      spreadRadius: 1,
                    )
                  ]
                : const [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? CyberTheme.neonEmerald
                      : (_isHovered ? CyberTheme.textPrimary : CyberTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.item.hint,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? CyberTheme.cyberCyan : CyberTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
