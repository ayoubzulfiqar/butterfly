import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_theme.dart';
import '../../../domain/entities/dpi_bypass_mode.dart';
import '../../../domain/entities/zapret2_strategy.dart';
import '../../viewmodels/dpi_viewmodel.dart';
import '../../widgets/fluent_card.dart';
import '../../widgets/status_badge.dart';

/// Page for configuring and managing zapret2 and legacy GoodbyeDPI bypass engines.
class DpiBypassPage extends StatelessWidget {
  const DpiBypassPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dpiVm = context.watch<DpiViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEngineSelector(context, dpiVm),
          const SizedBox(height: 16),
          _buildHeroControlCard(context, dpiVm),
          if (dpiVm.statusMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: (dpiVm.statusMessage.toLowerCase().contains('failed') ||
                        dpiVm.statusMessage.toLowerCase().contains('error') ||
                        dpiVm.statusMessage.toLowerCase().contains('exception'))
                    ? AppTheme.dangerRed.withValues(alpha: 0.12)
                    : AppTheme.successGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                dpiVm.statusMessage,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: (dpiVm.statusMessage.toLowerCase().contains('failed') ||
                          dpiVm.statusMessage.toLowerCase().contains('error') ||
                          dpiVm.statusMessage.toLowerCase().contains('exception'))
                      ? AppTheme.dangerRed
                      : AppTheme.successGreen,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          _buildCliPreviewCard(context, dpiVm),
          const SizedBox(height: 24),
          Text(
            dpiVm.isZapret2
                ? 'zapret2 Protection Strategies'
                : 'GoodbyeDPI Bypass Presets & Modes',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (dpiVm.isZapret2)
            ...Zapret2Strategies.presets.map((strat) {
              final isSelected = dpiVm.selectedStrategy.id == strat.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildZapret2StrategyCard(context, dpiVm, strat, isSelected),
              );
            })
          else
            ...dpiVm.availableModes.map((mode) {
              final isSelected = dpiVm.selectedMode.id == mode.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildModeCard(context, dpiVm, mode, isSelected),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEngineSelector(BuildContext context, DpiViewModel dpiVm) {
    return Row(
      children: [
        ChoiceChip(
          label: const Text('zapret2 (Next-Gen)'),
          selected: dpiVm.isZapret2,
          onSelected: dpiVm.isRunning ? null : (_) => dpiVm.selectEngine('zapret2'),
        ),
        const SizedBox(width: 10),
        ChoiceChip(
          label: const Text('GoodbyeDPI (Legacy)'),
          selected: !dpiVm.isZapret2,
          onSelected: dpiVm.isRunning ? null : (_) => dpiVm.selectEngine('goodbyedpi'),
        ),
      ],
    );
  }

  Widget _buildHeroControlCard(BuildContext context, DpiViewModel dpiVm) {
    final activeTitle = dpiVm.isZapret2
        ? 'zapret2 Circumvention Engine'
        : 'GoodbyeDPI Engine Controller';
    final activeSubtitle = dpiVm.isZapret2
        ? 'Next-gen packet desynchronization via nfqws2 / winws2 with multi-split & fake TLS'
        : 'Bypass ISP censorship and deep packet inspection of TCP/UDP packets';

    return FluentCard(
      title: activeTitle,
      subtitle: activeSubtitle,
      trailing: StatusBadge(
        label: dpiVm.isRunning ? 'RUNNING' : 'STOPPED',
        isSuccess: dpiVm.isRunning,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dpiVm.isZapret2
                      ? 'Active Profile: ${dpiVm.selectedStrategy.name} (${dpiVm.selectedStrategy.profile.name})'
                      : 'Active Mode: ${dpiVm.selectedMode.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dpiVm.isZapret2
                      ? dpiVm.selectedStrategy.description
                      : 'Arguments: ${dpiVm.selectedMode.args.join(" ")}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                if (dpiVm.isZapret2) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Switch(
                        value: dpiVm.enableQuic,
                        onChanged: dpiVm.isRunning
                            ? null
                            : (val) => dpiVm.setEnableQuic(val),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'QUIC / UDP Interception',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            icon: dpiVm.isLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    dpiVm.isRunning
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded,
                    size: 18,
                  ),
            label: Text(
              dpiVm.isRunning ? 'Stop Bypass' : 'Start DPI Bypass',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  dpiVm.isRunning ? AppTheme.dangerRed : AppTheme.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            onPressed: dpiVm.isLoading
                ? null
                : dpiVm.isRunning
                    ? dpiVm.stopBypass
                    : dpiVm.startBypass,
          ),
        ],
      ),
    );
  }

  Widget _buildCliPreviewCard(BuildContext context, DpiViewModel dpiVm) {
    return FluentCard(
      title: 'Live CLI Argument Preview',
      subtitle: 'Exact process arguments executed by the background service daemon',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: SelectableText(
          dpiVm.cliPreview,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: Color(0xFF00D0FF),
          ),
        ),
      ),
    );
  }

  Widget _buildZapret2StrategyCard(
    BuildContext context,
    DpiViewModel dpiVm,
    Zapret2Strategy strat,
    bool isSelected,
  ) {
    return InkWell(
      onTap: dpiVm.isRunning ? null : () => dpiVm.selectStrategy(strat),
      borderRadius: BorderRadius.circular(8),
      child: FluentCard(
        backgroundColor: isSelected
            ? AppTheme.primaryBlue.withValues(alpha: 0.08)
            : null,
        title: strat.name,
        subtitle: strat.description,
        trailing: Icon(
          isSelected
              ? Icons.radio_button_checked_rounded
              : Icons.radio_button_off_rounded,
          color: isSelected ? AppTheme.primaryBlue : Colors.grey,
          size: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                strat.tcpArgs.join(' '),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ),
            if (strat.quicArgs.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'QUIC: ${strat.quicArgs.join(' ')}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Color(0xFF00FFA3),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context,
    DpiViewModel dpiVm,
    DpiBypassMode mode,
    bool isSelected,
  ) {
    return InkWell(
      onTap: dpiVm.isRunning ? null : () => dpiVm.selectMode(mode),
      borderRadius: BorderRadius.circular(8),
      child: FluentCard(
        backgroundColor: isSelected
            ? AppTheme.primaryBlue.withValues(alpha: 0.08)
            : null,
        title: mode.name,
        subtitle: mode.description,
        trailing: Icon(
          isSelected
              ? Icons.radio_button_checked_rounded
              : Icons.radio_button_off_rounded,
          color: isSelected ? AppTheme.primaryBlue : Colors.grey,
          size: 20,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            mode.args.join(' '),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
