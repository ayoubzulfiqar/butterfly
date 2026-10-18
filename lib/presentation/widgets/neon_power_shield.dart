import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/cyber_theme.dart';

/// Interactive state of the Power Shield.
enum PowerShieldState {
  off,
  busy,
  on,
  err,
}

/// Luminous, cyber-minimal neon power button with rotating celestial ring.
class NeonPowerShield extends StatefulWidget {
  final PowerShieldState state;
  final VoidCallback onTap;
  final double size;
  final String? label;

  const NeonPowerShield({
    super.key,
    required this.state,
    required this.onTap,
    this.size = 150.0,
    this.label,
  });

  @override
  State<NeonPowerShield> createState() => _NeonPowerShieldState();
}

class _NeonPowerShieldState extends State<NeonPowerShield>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: _durationForState(widget.state),
    )..repeat();
  }

  @override
  void didUpdateWidget(NeonPowerShield oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _rotationController.duration = _durationForState(widget.state);
      if (!_rotationController.isAnimating) {
        _rotationController.repeat();
      }
    }
  }

  Duration _durationForState(PowerShieldState state) {
    switch (state) {
      case PowerShieldState.busy:
        return const Duration(seconds: 2);
      case PowerShieldState.on:
      case PowerShieldState.off:
      case PowerShieldState.err:
        return const Duration(seconds: 18);
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Color _accentColorForState(PowerShieldState state) {
    switch (state) {
      case PowerShieldState.off:
        return const Color(0x7300FFA3);
      case PowerShieldState.busy:
        return CyberTheme.cyberCyan;
      case PowerShieldState.on:
        return CyberTheme.neonEmerald;
      case PowerShieldState.err:
        return CyberTheme.neonCoral;
    }
  }

  List<BoxShadow> _shadowsForState(PowerShieldState state) {
    final color = _accentColorForState(state);
    final isHover = _isHovered;

    switch (state) {
      case PowerShieldState.off:
        return isHover
            ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2)]
            : const [];
      case PowerShieldState.busy:
        return [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 2),
          BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 1),
        ];
      case PowerShieldState.on:
        return [
          BoxShadow(color: color.withValues(alpha: isHover ? 0.6 : 0.45), blurRadius: 40, spreadRadius: 4),
          BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 15, spreadRadius: 2),
        ];
      case PowerShieldState.err:
        return [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 35, spreadRadius: 3),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColorForState(widget.state);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Semantics(
          button: true,
          label: widget.label ?? 'DPI Bypass Power Button',
          child: SizedBox(
            width: widget.size + 40,
            height: widget.size + 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer rotating dashed ring
                AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationController.value * 2 * math.pi,
                      child: CustomPaint(
                        size: Size(widget.size + 30, widget.size + 30),
                        painter: _CelestialRingPainter(
                          color: accent.withValues(alpha: widget.state == PowerShieldState.off ? 0.2 : 0.5),
                          isDotted: widget.state == PowerShieldState.busy,
                        ),
                      ),
                    );
                  },
                ),
                // Inner power button circle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CyberTheme.surface,
                    border: Border.all(
                      color: accent,
                      width: _isHovered ? 2.5 : 2.0,
                    ),
                    boxShadow: _shadowsForState(widget.state),
                  ),
                  child: Center(
                    child: AnimatedScale(
                      scale: _isHovered ? 1.08 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.power_settings_new,
                        size: widget.size * 0.42,
                        color: accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CelestialRingPainter extends CustomPainter {
  final Color color;
  final bool isDotted;

  _CelestialRingPainter({
    required this.color,
    required this.isDotted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDotted ? 2.0 : 1.2;

    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);

    final totalDashes = isDotted ? 28 : 16;
    final sweepAngle = (2 * math.pi) / totalDashes;
    final dashLength = sweepAngle * (isDotted ? 0.35 : 0.65);

    for (var i = 0; i < totalDashes; i++) {
      final startAngle = i * sweepAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashLength,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CelestialRingPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isDotted != isDotted;
  }
}
