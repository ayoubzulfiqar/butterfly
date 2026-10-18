import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/tools_viewmodel.dart';
import 'fluent_card.dart';
import 'status_badge.dart';

class ScheduledShutdownCard extends StatefulWidget {
  const ScheduledShutdownCard({super.key});

  @override
  State<ScheduledShutdownCard> createState() => _ScheduledShutdownCardState();
}

class _ScheduledShutdownCardState extends State<ScheduledShutdownCard> {
  int _selectedMinutes = 30;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = context.watch<ToolsViewModel>();
    final shutdown = vm.shutdownState;

    return FluentCard(
      title: 'Scheduled System Shutdown',
      subtitle: 'Schedule an automatic operating system shutdown or sleep sequence',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (shutdown.isActive) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.alarm_rounded, color: theme.colorScheme.error, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Shutdown Armed',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge(
                              label: shutdown.targetTime != null
                                  ? 'Target: ${shutdown.targetTime!.hour.toString().padLeft(2, '0')}:${shutdown.targetTime!.minute.toString().padLeft(2, '0')}'
                                  : 'Armed',
                              customColor: Colors.redAccent,
                            ),
                            const SizedBox(width: 6),
                            Builder(
                              builder: (_) {
                                final rem = shutdown.remainingDuration;
                                final remText = (rem != null && rem.inSeconds > 0)
                                    ? '${rem.inHours.toString().padLeft(2, '0')}:${(rem.inMinutes % 60).toString().padLeft(2, '0')}:${(rem.inSeconds % 60).toString().padLeft(2, '0')}'
                                    : '00:00:00';
                                return StatusBadge(
                                  label: 'Remaining: $remText',
                                  icon: Icons.timer_outlined,
                                  customColor: Colors.orangeAccent,
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ensure all unsaved documents and files are saved before target time.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                    ),
                    onPressed: () => vm.cancelShutdown(),
                    child: const Text('Cancel Shutdown'),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              'Quick Presets',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetButton(15, '+15m'),
                _buildPresetButton(30, '+30m'),
                _buildPresetButton(60, '+1h'),
                _buildPresetButton(120, '+2h'),
                _buildPresetButton(180, '+3h'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Target delay: $_selectedMinutes minutes',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.timer_outlined, size: 18),
                  label: const Text('Schedule Shutdown'),
                  onPressed: () {
                    vm.scheduleShutdown(
                      Duration(minutes: _selectedMinutes),
                      reason: 'Scheduled by Butterfly DNS suite',
                    );
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPresetButton(int minutes, String label) {
    final isSelected = _selectedMinutes == minutes;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedMinutes = minutes;
          });
        }
      },
    );
  }
}
