import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_theme.dart';
import '../../../domain/entities/dns_provider.dart';
import '../../viewmodels/network_dns_viewmodel.dart';
import '../../widgets/custom_dns_dialog.dart';
import '../../widgets/fluent_card.dart';
import '../../widgets/status_badge.dart';

/// DNS Resolvers catalog page with latency benchmarks, search, and custom DNS.
class DnsResolversPage extends StatelessWidget {
  const DnsResolversPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dnsVm = context.watch<NetworkDnsViewModel>();

    return Column(
      children: [
        _buildControlsHeader(context, dnsVm),
        const Divider(height: 1),
        if (dnsVm.statusMessage.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            color: (dnsVm.isErrorStatus ? AppTheme.dangerRed : AppTheme.successGreen)
                .withValues(alpha: 0.12),
            child: Row(
              children: [
                Icon(
                  dnsVm.isErrorStatus
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_outline_rounded,
                  color: dnsVm.isErrorStatus
                      ? AppTheme.dangerRed
                      : AppTheme.successGreen,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dnsVm.statusMessage,
                    style: TextStyle(
                      color: dnsVm.isErrorStatus
                          ? AppTheme.dangerRed
                          : AppTheme.successGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: dnsVm.filteredProviders.isEmpty
              ? const Center(
                  child: Text(
                    'No DNS resolvers match your search criteria.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(24.0),
                  itemCount: dnsVm.filteredProviders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final provider = dnsVm.filteredProviders[index];
                    return _buildProviderCard(context, dnsVm, provider);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildControlsHeader(
    BuildContext context,
    NetworkDnsViewModel dnsVm,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Theme.of(context).cardTheme.color,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: dnsVm.setSearchQuery,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded, size: 18),
                    hintText: 'Search resolvers by name or features...',
                  ),
                ),
              ),
              const SizedBox(width: 14),
              ElevatedButton.icon(
                icon: dnsVm.isPinging
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.speed_rounded, size: 16),
                label: const Text('Test Speeds'),
                onPressed: dnsVm.isPinging ? null : dnsVm.runLatencyBenchmark,
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Custom'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => CustomDnsDialog(
                      onAdd: (custom) => dnsVm.addCustomProvider(custom),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: DnsCategory.values.map((cat) {
                final isSelected = dnsVm.selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(_formatCategoryLabel(cat)),
                    selected: isSelected,
                    onSelected: (_) => dnsVm.setSelectedCategory(cat),
                    selectedColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primaryBlue,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.primaryBlue : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard(
    BuildContext context,
    NetworkDnsViewModel dnsVm,
    DnsProvider provider,
  ) {
    return FluentCard(
      title: provider.name,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (provider.latencyMs != null)
            StatusBadge(
              label: '${provider.latencyMs} ms',
              icon: Icons.timer_outlined,
              customColor: provider.latencyMs! < 30
                  ? AppTheme.successGreen
                  : provider.latencyMs! < 80
                      ? AppTheme.primaryBlue
                      : AppTheme.warningAmber,
            )
          else
            StatusBadge(
              label: _formatCategoryLabel(provider.category),
              customColor: AppTheme.primaryBlue,
            ),
          if (provider.isCustom) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              color: AppTheme.dangerRed,
              tooltip: 'Delete custom provider',
              onPressed: () => dnsVm.deleteCustomProvider(provider.id),
            ),
          ],
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            provider.description,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: provider.features.map((feat) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  feat,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (provider.ipv4.isNotEmpty) ...[
                      const Text(
                        'IPv4 Addresses:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: provider.ipv4.map((ip) {
                          return _buildIpChip(context, ip);
                        }).toList(),
                      ),
                    ],
                    if (provider.ipv6.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'IPv6 Addresses:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: provider.ipv6.map((ip) {
                          return _buildIpChip(context, ip);
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: dnsVm.isApplyingDns
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 16),
                label: const Text('Apply DNS'),
                onPressed: dnsVm.isApplyingDns
                    ? null
                    : () => dnsVm.applyDns(provider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIpChip(BuildContext context, String ip) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: ip));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied $ip to clipboard'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ip,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.copy_rounded, size: 11, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  String _formatCategoryLabel(DnsCategory cat) {
    switch (cat) {
      case DnsCategory.all:
        return 'All';
      case DnsCategory.privacy:
        return 'Privacy & No-Logs';
      case DnsCategory.security:
        return 'Security & Malware';
      case DnsCategory.gaming:
        return 'High Speed & Anycast';
      case DnsCategory.family:
        return 'Family & SafeSearch';
      case DnsCategory.custom:
        return 'Custom';
    }
  }
}
