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

    return Scaffold(
      backgroundColor: CyberTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, navVm),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      NeonPowerShield(
                        state: shieldState,
                        onTap: () => dpiVm.toggleBypass(),
                        size: 170.0,
                        label: dpiVm.isRunning ? 'PROTECTED' : 'UNPROTECTED',
                      ),
                      const SizedBox(height: 24),
                      Text(
                        dpiVm.isRunning
                            ? 'Active Bypass Protection'
                            : 'Protection Disabled',
                        style: TextStyle(
                          fontSize: 20,
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
                        style: const TextStyle(
                          fontSize: 13,
                          color: CyberTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 28),
                      ProtectionLevelsBar(
                        selectedProfile: dpiVm.selectedProfile,
                        onProfileSelected: (profile) => dpiVm.selectProfile(profile),
                      ),
                      const SizedBox(height: 36),
                      _buildTelemetryHud(context, dnsVm, dpiVm),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, NavigationViewModel navVm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CyberTheme.border, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
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
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'BUTTERFLY SHIELD',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: CyberTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Cyber Circumvention Engine',
                    style: TextStyle(
                      fontSize: 11,
                      color: CyberTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              icon: const Icon(Icons.dashboard_customize_rounded, size: 16),
              label: const Text(
                'Open Studio',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
    DpiViewModel dpiVm,
  ) {
    final adapterName = dnsVm.selectedAdapter?.name ?? 'Default Interface';
    final activeDns = dnsVm.currentDnsServers.isNotEmpty
        ? dnsVm.currentDnsServers.first
        : 'System Default';

    return Container(
      constraints: const BoxConstraints(maxWidth: 580),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
            margin: const EdgeInsets.symmetric(horizontal: 8),
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
            margin: const EdgeInsets.symmetric(horizontal: 8),
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
