import 'dart:async';
import 'dart:io';
import '../../core/utils/logger.dart';
import '../../domain/services/cloudflare_scanner_service.dart';

typedef ProbeIpFunction = Future<int?> Function(String ip);

/// Concrete implementation of the Cloudflare Clean IP Scanner.
class CloudflareScannerServiceImpl implements ICloudflareScannerService {
  final ProbeIpFunction _probeFn;
  final StreamController<double> _progressController =
      StreamController<double>.broadcast();

  CloudflareScannerServiceImpl({ProbeIpFunction? probeFn})
      : _probeFn = probeFn ?? _defaultProbe;

  static const List<String> defaultSeedIps = [
    '104.16.132.229',
    '172.67.182.110',
    '104.21.48.1',
    '104.17.65.1',
    '162.159.153.4',
    '172.64.155.109',
    '104.18.25.1',
    '104.26.10.1',
    '172.67.220.1',
    '104.24.10.1',
    '162.159.138.6',
    '172.64.148.1',
  ];

  static Future<int?> _defaultProbe(String ip) async {
    final sw = Stopwatch()..start();
    try {
      final socket = await Socket.connect(
        ip,
        443,
        timeout: const Duration(seconds: 2),
      );
      sw.stop();
      await socket.close();
      return sw.elapsedMilliseconds;
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<double> get progressStream => _progressController.stream;

  @override
  Future<List<CloudflareCleanIp>> scanCleanIps({
    List<String>? targetIps,
    int limit = 10,
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final ips = targetIps ?? defaultSeedIps;
    final results = <CloudflareCleanIp>[];
    var scanned = 0;

    _progressController.add(0.0);

    for (final ip in ips) {
      try {
        final latency = await _probeFn(ip);
        scanned++;
        _progressController.add(scanned / ips.length);

        if (latency != null) {
          results.add(CloudflareCleanIp(
            ip: ip,
            latencyMs: latency,
            packetLoss: 0.0,
            isClean: true,
          ));
        }
      } catch (e) {
        scanned++;
        _progressController.add(scanned / ips.length);
        appLogger.warning('CfScan', 'Probe failed for $ip: $e');
      }
    }

    // Sort by lowest latency
    results.sort((a, b) => a.latencyMs.compareTo(b.latencyMs));

    if (results.length > limit) {
      return results.sublist(0, limit);
    }
    return results;
  }

  void dispose() {
    _progressController.close();
  }
}
