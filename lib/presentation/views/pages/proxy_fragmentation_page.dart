import 'package:flutter/material.dart';
import '../../../core/themes/app_theme.dart';
import '../../../domain/services/tls_fragmenter.dart';
import '../../widgets/fluent_card.dart';
import '../../widgets/status_badge.dart';

/// Workspace page for configuring driverless TLS ClientHello fragmentation proxy.
class ProxyFragmentationPage extends StatefulWidget {
  const ProxyFragmentationPage({super.key});

  @override
  State<ProxyFragmentationPage> createState() => _ProxyFragmentationPageState();
}

class _ProxyFragmentationPageState extends State<ProxyFragmentationPage> {
  TlsFragMethod _selectedMethod = TlsFragMethod.both;
  bool _isProxyRunning = false;
  final int _proxyPort = 8085;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.alt_route_rounded,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Driverless TLS Proxy & Fragmentation',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Pure Dart userspace proxy splitting TLS ClientHello SNI without kernel drivers or elevation',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FluentCard(
              title: 'Driverless Proxy Engine',
              subtitle: 'Local HTTP CONNECT proxy on 127.0.0.1:$_proxyPort',
              trailing: StatusBadge(
                label: _isProxyRunning ? 'PROXY RUNNING' : 'STANDBY',
                isSuccess: _isProxyRunning,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Fragmentation: ${_methodName(_selectedMethod)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Listens on 127.0.0.1:$_proxyPort for browser/app HTTP CONNECT requests',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    icon: Icon(
                      _isProxyRunning
                          ? Icons.stop_rounded
                          : Icons.play_arrow_rounded,
                      size: 18,
                    ),
                    label: Text(_isProxyRunning ? 'Stop Proxy' : 'Start Proxy'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isProxyRunning
                          ? AppTheme.dangerRed
                          : AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _isProxyRunning = !_isProxyRunning;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Fragmentation Strategy',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildMethodCard(
              title: 'Combined TCP & TLS Record Fragmentation (Recommended)',
              subtitle:
                  'Splits ClientHello at record layer and segments payload at TCP byte level for highest circumvention efficacy.',
              method: TlsFragMethod.both,
            ),
            const SizedBox(height: 12),
            _buildMethodCard(
              title: 'TCP Level Segmentation',
              subtitle:
                  'Segments the TCP window mid-SNI hostname to prevent DPI firewalls from reassembling hostname string.',
              method: TlsFragMethod.tcp,
            ),
            const SizedBox(height: 12),
            _buildMethodCard(
              title: 'TLS Record Layer Fragmentation',
              subtitle:
                  'Sends two separate TLS 0x16 Handshake records within a single TCP packet to confuse naive SNI parsers.',
              method: TlsFragMethod.record,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard({
    required String title,
    required String subtitle,
    required TlsFragMethod method,
  }) {
    final isSelected = _selectedMethod == method;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = method),
      borderRadius: BorderRadius.circular(8),
      child: FluentCard(
        backgroundColor: isSelected
            ? AppTheme.primaryBlue.withValues(alpha: 0.08)
            : null,
        title: title,
        subtitle: subtitle,
        trailing: Icon(
          isSelected
              ? Icons.radio_button_checked_rounded
              : Icons.radio_button_off_rounded,
          color: isSelected ? AppTheme.primaryBlue : Colors.grey,
          size: 20,
        ),
        child: const SizedBox.shrink(),
      ),
    );
  }

  String _methodName(TlsFragMethod method) {
    switch (method) {
      case TlsFragMethod.tcp:
        return 'TCP Byte Segmentation';
      case TlsFragMethod.record:
        return 'TLS Record Layer Splitting';
      case TlsFragMethod.both:
        return 'Combined TCP & Record Splitting';
    }
  }
}
