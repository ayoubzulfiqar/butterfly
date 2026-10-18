import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_theme.dart';
import '../../../domain/entities/app_log_entry.dart';
import '../../viewmodels/diagnostics_viewmodel.dart';
import '../../widgets/fluent_card.dart';

/// Diagnostics and live logging console page.
class DiagnosticsPage extends StatelessWidget {
  const DiagnosticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final diagVm = context.watch<DiagnosticsViewModel>();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildControlsBar(context, diagVm),
          const SizedBox(height: 16),
          Expanded(child: _buildConsoleViewer(context, diagVm)),
        ],
      ),
    );
  }

  Widget _buildControlsBar(
    BuildContext context,
    DiagnosticsViewModel diagVm,
  ) {
    return FluentCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: diagVm.setSearchFilter,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded, size: 18),
                hintText: 'Filter log console by keyword or tag...',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 14),
          DropdownButton<LogSeverity?>(
            value: diagVm.filterSeverity,
            hint: const Text('All Levels'),
            items: const [
              DropdownMenuItem(value: null, child: Text('All Severities')),
              DropdownMenuItem(
                value: LogSeverity.info,
                child: Text('Info Only'),
              ),
              DropdownMenuItem(
                value: LogSeverity.warning,
                child: Text('Warnings Only'),
              ),
              DropdownMenuItem(
                value: LogSeverity.error,
                child: Text('Errors Only'),
              ),
            ],
            onChanged: diagVm.setFilterSeverity,
          ),
          const SizedBox(width: 14),
          OutlinedButton.icon(
            icon: const Icon(Icons.copy_all_rounded, size: 16),
            label: const Text('Copy All'),
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: diagVm.getFormattedLogsText()),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Console logs copied to clipboard'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.clear_all_rounded, size: 16),
            label: const Text('Clear Console'),
            onPressed: diagVm.clearLogs,
          ),
        ],
      ),
    );
  }

  Widget _buildConsoleViewer(
    BuildContext context,
    DiagnosticsViewModel diagVm,
  ) {
    final logs = diagVm.filteredLogs;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF101014),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: logs.isEmpty
          ? const Center(
              child: Text(
                'No diagnostic logs captured yet.',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '[${log.formattedTime}]',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '[${log.severity.name.toUpperCase()}]',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _getSeverityColor(log.severity),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '[${log.tag}]',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SelectableText(
                          log.message,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFFE2E2E2),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Color _getSeverityColor(LogSeverity severity) {
    switch (severity) {
      case LogSeverity.info:
        return AppTheme.successGreen;
      case LogSeverity.warning:
        return AppTheme.warningAmber;
      case LogSeverity.error:
        return AppTheme.dangerRed;
    }
  }
}
