import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/network_dns_viewmodel.dart';
import '../viewmodels/tools_viewmodel.dart';
import 'fluent_card.dart';
import 'status_badge.dart';

class AdapterSwitcherCard extends StatelessWidget {
  const AdapterSwitcherCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final netVm = context.watch<NetworkDnsViewModel>();
    final toolsVm = context.watch<ToolsViewModel>();
    final adapters = netVm.adapters;
    final selectedAdapter = netVm.selectedAdapter;

    return FluentCard(
      title: 'Network Adapters',
      subtitle: 'Manage host network interfaces and select active DNS targets',
      trailing: IconButton(
        icon: const Icon(Icons.refresh_rounded, size: 20),
        tooltip: 'Rescan Adapters',
        onPressed: () => netVm.refreshAdapters(),
      ),
      child: adapters.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('No network adapters detected.')),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: adapters.length,
              separatorBuilder: (_, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final adapter = adapters[index];
                final isSelected = selectedAdapter?.name == adapter.name;
                final isWireless = adapter.name.toLowerCase().contains('wi-fi') ||
                    adapter.name.toLowerCase().contains('wlan') ||
                    adapter.name.toLowerCase().contains('wireless');

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
                        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.5)
                          : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isWireless ? Icons.wifi_rounded : Icons.lan_rounded,
                        color: adapter.isUp ? theme.colorScheme.primary : theme.disabledColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  adapter.name,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                StatusBadge(
                                  label: adapter.isUp ? 'Connected' : 'Disconnected',
                                  customColor: adapter.isUp ? Colors.green : Colors.grey,
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: 6),
                                  const StatusBadge(
                                    label: 'Active DNS Target',
                                    customColor: Colors.blueAccent,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              adapter.interfaceDescription,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'DNS: ${adapter.formattedDns}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontFamily: 'monospace',
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!isSelected)
                        OutlinedButton(
                          onPressed: () => netVm.selectAdapter(adapter),
                          child: const Text('Set Target'),
                        )
                      else
                        FilledButton.tonal(
                          onPressed: null,
                          child: const Text('Targeted'),
                        ),
                      const SizedBox(width: 8),
                      Switch(
                        value: adapter.isUp,
                        onChanged: (val) async {
                          await toolsVm.toggleInterface(adapter.name, val);
                          await netVm.refreshAdapters();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
