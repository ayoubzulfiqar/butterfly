import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_theme.dart';
import '../../../domain/entities/network_adapter.dart';
import '../../viewmodels/dpi_viewmodel.dart';
import '../../viewmodels/network_dns_viewmodel.dart';
import '../../widgets/fluent_card.dart';
import '../../widgets/status_badge.dart';

/// Dashboard page displaying active adapter status, active DNS configuration,
/// quick DNS switches, and DPI bypass telemetry.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dnsVm = context.watch<NetworkDnsViewModel>();
    final dpiVm = context.watch<DpiViewModel>();
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdapterSelector(context, dnsVm),
          const SizedBox(height: 20),
          _buildMetricsOverview(context, dnsVm, dpiVm),
          const SizedBox(height: 24),
          _buildQuickActions(context, dnsVm),
          if (dnsVm.statusMessage.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildStatusNotification(dnsVm, theme),
          ],
        ],
      ),
    );
  }

  Widget _buildAdapterSelector(
    BuildContext context,
    NetworkDnsViewModel dnsVm,
  ) {
    return FluentCard(
      title: 'Active Network Interface',
      subtitle: 'Select the network adapter to configure and monitor',
      trailing: IconButton(
        icon: const Icon(Icons.refresh_rounded, size: 20),
        tooltip: 'Refresh Network Adapters',
        onPressed: dnsVm.isLoadingAdapters ? null : dnsVm.refreshAdapters,
      ),
      child: dnsVm.isLoadingAdapters
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : dnsVm.adapters.isEmpty
              ? const Text(
                  'No active network adapters detected.',
                  style: TextStyle(color: AppTheme.warningAmber),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<NetworkAdapter>(
                    value: dnsVm.selectedAdapter,
                    isExpanded: true,
                    items: dnsVm.adapters.map((adapter) {
                      return DropdownMenuItem(
                        value: adapter,
                        child: Row(
                          children: [
                            Icon(
                              adapter.name.toLowerCase().contains('wi-fi')
                                  ? Icons.wifi_rounded
                                  : Icons.settings_ethernet_rounded,
                              size: 18,
                              color: AppTheme.primaryBlue,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              adapter.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '(${adapter.interfaceDescription})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (adapter) {
                      if (adapter != null) {
                        dnsVm.selectAdapter(adapter);
                      }
                    },
                  ),
                ),
    );
  }

  Widget _buildMetricsOverview(
    BuildContext context,
    NetworkDnsViewModel dnsVm,
    DpiViewModel dpiVm,
  ) {
    final adapter = dnsVm.selectedAdapter;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;

        final dnsCard = FluentCard(
          title: 'Current DNS Resolver',
          subtitle: 'Active resolver configuration for ${adapter?.name ?? "N/A"}',
          trailing: StatusBadge(
            label: (adapter?.isDhcp ?? true) ? 'Automatic (DHCP)' : 'Custom DNS',
            isSuccess: !(adapter?.isDhcp ?? true),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (dnsVm.currentDnsServers.isEmpty)
                const Text(
                  'Obtaining DNS automatically from your ISP (DHCP).',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: dnsVm.currentDnsServers.map((ip) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        ip,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );

        final dpiCard = FluentCard(
          title: 'DPI Bypass Status',
          subtitle: 'GoodbyeDPI background driver',
          trailing: StatusBadge(
            label: dpiVm.isRunning ? 'Active' : 'Stopped',
            isSuccess: dpiVm.isRunning,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mode: ${dpiVm.selectedMode.name}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: dpiVm.isLoading
                      ? null
                      : dpiVm.isRunning
                          ? dpiVm.stopBypass
                          : dpiVm.startBypass,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dpiVm.isRunning
                        ? AppTheme.dangerRed
                        : AppTheme.primaryBlue,
                  ),
                  child: Text(
                    dpiVm.isRunning ? 'Stop Bypass' : 'Start Bypass',
                  ),
                ),
              ),
            ],
          ),
        );

        if (isNarrow) {
          return Column(
            children: [
              dnsCard,
              const SizedBox(height: 16),
              dpiCard,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: dnsCard),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: dpiCard),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    NetworkDnsViewModel dnsVm,
  ) {
    return FluentCard(
      title: 'Quick Operations',
      subtitle: 'Instantly apply top curated resolvers or manage cache',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.flash_on_rounded, size: 16),
            label: const Text('Cloudflare (1.1.1.1)'),
            onPressed: (dnsVm.isApplyingDns || dnsVm.providers.isEmpty)
                ? null
                : () {
                    final cloudflare = dnsVm.providers
                        .where((p) => p.name.contains('Cloudflare'))
                        .firstOrNull;
                    if (cloudflare != null) {
                      dnsVm.applyDns(cloudflare);
                    }
                  },
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.security_rounded, size: 16),
            label: const Text('Google (8.8.8.8)'),
            onPressed: (dnsVm.isApplyingDns || dnsVm.providers.isEmpty)
                ? null
                : () {
                    final google = dnsVm.providers
                        .where((p) => p.name.contains('Google'))
                        .firstOrNull;
                    if (google != null) {
                      dnsVm.applyDns(google);
                    }
                  },
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.shield_rounded, size: 16),
            label: const Text('Quad9 Malware Filter'),
            onPressed: (dnsVm.isApplyingDns || dnsVm.providers.isEmpty)
                ? null
                : () {
                    final quad9 = dnsVm.providers
                        .where((p) => p.name.contains('Quad9'))
                        .firstOrNull;
                    if (quad9 != null) {
                      dnsVm.applyDns(quad9);
                    }
                  },
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.restore_rounded, size: 16),
            label: const Text('Reset to DHCP (Default)'),
            onPressed: dnsVm.isApplyingDns ? null : dnsVm.restoreDhcp,
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.cleaning_services_rounded, size: 16),
            label: const Text('Flush DNS Cache'),
            onPressed: dnsVm.isFlushingCache ? null : dnsVm.flushDnsCache,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusNotification(NetworkDnsViewModel dnsVm, ThemeData theme) {
    final color = dnsVm.isErrorStatus
        ? AppTheme.dangerRed
        : AppTheme.successGreen;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            dnsVm.isErrorStatus
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              dnsVm.statusMessage,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
