import 'package:flutter_test/flutter_test.dart';
import 'package:butterfly/domain/services/cloudflare_scanner_service.dart';
import 'package:butterfly/data/services/cloudflare_scanner_service_impl.dart';

void main() {
  group('CloudflareScannerService Clean-IP Tests', () {
    test('CloudflareCleanIp model computes status and ranking properties', () {
      const cleanIp = CloudflareCleanIp(
        ip: '104.16.132.229',
        latencyMs: 24,
        packetLoss: 0.0,
        isClean: true,
      );

      expect(cleanIp.ip, equals('104.16.132.229'));
      expect(cleanIp.latencyMs, equals(24));
      expect(cleanIp.isClean, isTrue);
    });

    test('CloudflareScannerServiceImpl sorts clean IPs by lowest latency', () async {
      final scanner = CloudflareScannerServiceImpl(
        probeFn: (ip) async {
          if (ip == '104.16.1.1') return 85;
          if (ip == '172.67.1.1') return 18;
          if (ip == '162.159.1.1') return null; // failed probe / blocked
          return 42;
        },
      );

      final results = await scanner.scanCleanIps(
        targetIps: ['104.16.1.1', '172.67.1.1', '162.159.1.1', '104.21.1.1'],
        limit: 5,
      );

      expect(results.length, equals(3)); // 3 succeeded, 1 blocked
      expect(results[0].ip, equals('172.67.1.1'));
      expect(results[0].latencyMs, equals(18));
      expect(results[0].isClean, isTrue);

      expect(results[1].ip, equals('104.21.1.1'));
      expect(results[1].latencyMs, equals(42));

      expect(results[2].ip, equals('104.16.1.1'));
      expect(results[2].latencyMs, equals(85));
    });

    test('CloudflareScannerServiceImpl emits progress updates during scanning', () async {
      final progressValues = <double>[];
      final scanner = CloudflareScannerServiceImpl(
        probeFn: (_) async => 20,
      );

      scanner.progressStream.listen(progressValues.add);

      await scanner.scanCleanIps(
        targetIps: ['1.1.1.1', '2.2.2.2'],
      );
      await Future.delayed(Duration.zero);

      expect(progressValues, isNotEmpty);
      expect(progressValues.last, equals(1.0));
    });
  });
}
