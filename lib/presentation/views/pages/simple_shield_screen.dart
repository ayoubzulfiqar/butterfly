import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/cyber_theme.dart';
import '../../viewmodels/dpi_viewmodel.dart';
import '../../viewmodels/navigation_viewmodel.dart';
import '../../viewmodels/network_dns_viewmodel.dart';
import '../../widgets/neon_power_shield.dart';
import '../../widgets/protection_levels_bar.dart';

/// One-click Cyber-Minimal shield screen inspired by Ghostline.
class SimpleShieldScreen extends StatelessWidget {
  const SimpleShieldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final navVm = context.watch<NavigationViewModel>();
    final dpiVm = context.watch<DpiViewModel>();
    final dnsVm = context.watch<NetworkDnsViewModel>();

    final shieldState = dpiVm.isLoading
        ? PowerShieldState.busy
        : (dpiVm.isRunning ? PowerShieldState.on : PowerShieldState.off);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final isNarrow = constraints.maxWidth < 400;

        return Scaffold(
          backgroundColor: CyberTheme.background,
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(context, navVm, isCompact: isCompact),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isNarrow ? 16 : 24,
                        vertical: isNarrow ? 12 : 16,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          NeonPowerShield(
                            state: shieldState,
                            onTap: () => dpiVm.toggleBypass(),
                            size: isNarrow ? 140.0 : 170.0,
                            label: dpiVm.isRunning ? 'PROTECTED' : 'UNPROTECTED',
                          ),
                          const SizedBox(height: 24),
                          Text(
                            dpiVm.isRunning
                                ? 'Active Bypass Protection'
                                : 'Protection Disabled',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isNarrow ? 18 : 20,
                              fontWeight: FontWeight.w700,
                              color: dpiVm.isRunning
                                  ? CyberTheme.neonEmerald
                                  : CyberTheme.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            dpiVm.isRunning
                                ? 'Traffic desynchronized with ${dpiVm.selectedStrategy.name} profile'
                                : 'Tap shield to activate zapret2 desynchronization',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: CyberTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 28),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: ProtectionLevelsBar(
                              selectedProfile: dpiVm.selectedProfile,
                              onProfileSelected: (profile) => dpiVm.selectProfile(profile),
                            ),
                          ),
                          const SizedBox(height: 36),
                          _buildTelemetryHud(context, dnsVm, dpiVm, isNarrow: isNarrow),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    NavigationViewModel navVm, {
    bool isCompact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 24,
        vertical: isCompact ? 12 : 16,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CyberTheme.border, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: CyberTheme.neonEmerald.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: CyberTheme.neonEmerald.withAlpha(80),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: CyberTheme.neonEmerald,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'BUTTERFLY SHIELD',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: CyberTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Cyber Circumvention Engine',
                        style: TextStyle(
                          fontSize: 11,
                          color: CyberTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Open Studio',
            child: OutlinedButton.icon(
              onPressed: () => navVm.setViewMode(AppViewMode.studio),
              style: OutlinedButton.styleFrom(
                foregroundColor: CyberTheme.cyberCyan,
                side: const BorderSide(color: CyberTheme.borderHighlight),
                backgroundColor: CyberTheme.surfaceTranslucent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 10 : 14,
                  vertical: isCompact ? 8 : 10,
                ),
              ),
              icon: const Icon(Icons.dashboard_customize_rounded, size: 16),
              label: Text(
                isCompact ? 'Studio' : 'Open Studio',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryHud(
    BuildContext context,
    NetworkDnsViewModel dnsVm,
    DpiViewModel dpiVm, {
    bool isNarrow = false,
  }) {
    final adapterName = dnsVm.selectedAdapter?.name ?? 'Default Interface';
    final activeDns = dnsVm.currentDnsServers.isNotEmpty
        ? dnsVm.currentDnsServers.first
        : 'System Default';

    return Container(
      constraints: const BoxConstraints(maxWidth: 580),
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 12 : 20,
        vertical: isNarrow ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: CyberTheme.surfaceTranslucent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CyberTheme.border, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _HudItem(
              icon: Icons.wifi_rounded,
              label: 'INTERFACE',
              value: adapterName,
              color: CyberTheme.cyberCyan,
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: CyberTheme.border,
            margin: EdgeInsets.symmetric(horizontal: isNarrow ? 4 : 8),
          ),
          Expanded(
            child: _HudItem(
              icon: Icons.dns_rounded,
              label: 'RESOLVER',
              value: activeDns,
              color: CyberTheme.textPrimary,
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: CyberTheme.border,
            margin: EdgeInsets.symmetric(horizontal: isNarrow ? 4 : 8),
          ),
          Expanded(
            child: _HudItem(
              icon: Icons.verified_user_rounded,
              label: 'SAFETY NET',
              value: dnsVm.isSafetyNetArmed ? 'ARMED' : 'STANDBY',
              color: dnsVm.isSafetyNetArmed
                  ? CyberTheme.neonEmerald
                  : CyberTheme.cyberCyan,
            ),
          ),
        ],
      ),
    );
  }
}

class _HudItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _HudItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: CyberTheme.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
