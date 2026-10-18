import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_theme.dart';
import '../../../domain/entities/dpi_bypass_mode.dart';
import '../../viewmodels/dpi_viewmodel.dart';
import '../../widgets/fluent_card.dart';
import '../../widgets/status_badge.dart';

/// Page for configuring and managing GoodbyeDPI Deep Packet Inspection bypass.
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
          _buildHeroControlCard(context, dpiVm),
          const SizedBox(height: 20),
          _buildExecutableStatusCard(context, dpiVm),
          const SizedBox(height: 24),
          const Text(
            'Bypass Presets & Modes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
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

  Widget _buildHeroControlCard(BuildContext context, DpiViewModel dpiVm) {
    return FluentCard(
      title: 'GoodbyeDPI Engine Controller',
      subtitle:
          'Bypass ISP censorship and deep packet inspection of TCP/UDP packets',
      trailing: StatusBadge(
        label: dpiVm.isRunning ? 'RUNNING' : 'STOPPED',
        isSuccess: dpiVm.isRunning,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Active Mode: ${dpiVm.selectedMode.name}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Arguments: ${dpiVm.selectedMode.args.join(" ")}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
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

  Widget _buildExecutableStatusCard(
    BuildContext context,
    DpiViewModel dpiVm,
  ) {
    if (dpiVm.isExecutableAvailable) {
      return FluentCard(
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppTheme.successGreen,
              size: 20,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'goodbyedpi.exe binary detected and ready.',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            OutlinedButton(
              onPressed: dpiVm.checkExecutable,
              child: const Text('Re-check'),
            ),
          ],
        ),
      );
    }

    return FluentCard(
      backgroundColor: AppTheme.warningAmber.withValues(alpha: 0.08),
      title: 'GoodbyeDPI Binary Required',
      trailing: OutlinedButton(
        onPressed: dpiVm.checkExecutable,
        child: const Text('Check Again'),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'goodbyedpi.exe was not detected in the application or assets folder.',
            style: TextStyle(fontSize: 13, color: AppTheme.warningAmber),
          ),
          SizedBox(height: 8),
          Text(
            '1. Download GoodbyeDPI release from ValdikSS/GoodbyeDPI on GitHub.\n'
            '2. Extract goodbyedpi.exe, WinDivert.dll, and WinDivert64.sys into the app root folder.\n'
            '3. Run this application as Administrator.',
            style: TextStyle(fontSize: 12, height: 1.5, color: Colors.grey),
          ),
        ],
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
        trailing: Radio<String>(
          value: mode.id,
          groupValue: dpiVm.selectedMode.id,
          onChanged: dpiVm.isRunning ? null : (_) => dpiVm.selectMode(mode),
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
