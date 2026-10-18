import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../viewmodels/tools_viewmodel.dart';
import 'fluent_card.dart';
import 'status_badge.dart';

class MyIpCard extends StatelessWidget {
  const MyIpCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = context.watch<ToolsViewModel>();
    final ipInfo = vm.publicIpInfo;

    return FluentCard(
      title: 'Public IP & Telemetry',
      subtitle: 'Real-time outbound WAN address, ISP, ASN, and geo-location',
      trailing: IconButton(
        icon: vm.isLoadingIp
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh_rounded, size: 20),
        tooltip: 'Refresh IP',
        onPressed: vm.isLoadingIp ? null : () => vm.refreshPublicIp(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (vm.isLoadingIp && ipInfo == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Detecting public IP details...'),
                  ],
                ),
              ),
            )
          else if (ipInfo != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Public IP Address',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          ipInfo.ip,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    tooltip: 'Copy IP',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: ipInfo.ip));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('IP address copied to clipboard!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (ipInfo.country != null)
                  StatusBadge(
                    label: '${ipInfo.country}${ipInfo.city != null ? ' (${ipInfo.city})' : ''}',
                    customColor: Colors.blueAccent,
                    icon: Icons.location_on_outlined,
                  ),
                if (ipInfo.isp != null)
                  StatusBadge(
                    label: ipInfo.isp!,
                    customColor: Colors.green,
                    icon: Icons.business_outlined,
                  ),
                if (ipInfo.asn != null)
                  StatusBadge(
                    label: ipInfo.asn!,
                    customColor: Colors.deepPurpleAccent,
                    icon: Icons.tag_rounded,
                  ),
                if (ipInfo.timezone != null)
                  StatusBadge(
                    label: ipInfo.timezone!,
                    customColor: Colors.teal,
                    icon: Icons.schedule_rounded,
                  ),
              ],
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      vm.errorMessage ?? 'Click refresh to detect public IP address',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: vm.errorMessage != null
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () => vm.refreshPublicIp(),
                    child: const Text('Detect IP'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
