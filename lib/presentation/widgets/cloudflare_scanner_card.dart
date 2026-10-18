import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/themes/app_theme.dart';
import '../../domain/services/cloudflare_scanner_service.dart';
import '../viewmodels/tools_viewmodel.dart';
import 'fluent_card.dart';
import 'status_badge.dart';

/// Card providing diagnostic Cloudflare Anycast Clean-IP scanning.
class CloudflareScannerCard extends StatelessWidget {
  const CloudflareScannerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = context.watch<ToolsViewModel>();

    return FluentCard(
      title: 'Cloudflare Clean-IP Scanner',
      subtitle:
          'Probes Cloudflare Anycast edge ranges to locate unblocked edge nodes with lowest TTFB latency',
      trailing: ElevatedButton.icon(
        icon: vm.isScanningIps
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.radar_rounded, size: 16),
        label: Text(vm.isScanningIps ? 'Scanning...' : 'Scan Clean IPs'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onPressed: vm.isScanningIps ? null : () => vm.scanCloudflareIps(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (vm.isScanningIps) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: vm.scanProgress > 0 ? vm.scanProgress : null,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (vm.cleanIps.isEmpty && !vm.isScanningIps)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No clean IP scan results yet. Tap "Scan Clean IPs" to probe Anycast ranges.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (vm.cleanIps.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.15),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: vm.cleanIps.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
                itemBuilder: (context, index) {
                  final item = vm.cleanIps[index];
                  return _CleanIpTile(item: item);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CleanIpTile extends StatelessWidget {
  final CloudflareCleanIp item;

  const _CleanIpTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                item.isClean ? Icons.check_circle_rounded : Icons.block_rounded,
                color: item.isClean ? AppTheme.successGreen : AppTheme.dangerRed,
                size: 16,
              ),
              const SizedBox(width: 10),
              Text(
                item.ip,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                '${item.latencyMs} ms',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: item.latencyMs < 60
                      ? AppTheme.successGreen
                      : (item.latencyMs < 120
                          ? AppTheme.warningAmber
                          : AppTheme.dangerRed),
                ),
              ),
              const SizedBox(width: 12),
              StatusBadge(
                label: item.isClean ? 'CLEAN' : 'BLOCKED',
                isSuccess: item.isClean,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
