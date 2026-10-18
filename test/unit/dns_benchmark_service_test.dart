import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:butterfly/data/services/dns_benchmark_service_impl.dart';
import 'package:butterfly/domain/entities/benchmark_target.dart';
import 'package:butterfly/domain/entities/dns_benchmark_result.dart';
import 'package:butterfly/domain/entities/dns_provider.dart';

void main() {
  group('DnsBenchmarkServiceImpl', () {
    final service = DnsBenchmarkServiceImpl();

    test('provides comprehensive list of default benchmark targets', () {
      final targets = service.defaultTargets;
      expect(targets.length, greaterThanOrEqualTo(8));
      expect(targets.any((t) => t.key == 'chatgpt'), isTrue);
      expect(targets.any((t) => t.key == 'google'), isTrue);
      expect(targets.any((t) => t.key == 'youtube'), isTrue);
      expect(targets.any((t) => t.key == 'github'), isTrue);
      expect(targets.any((t) => t.key == 'twitter'), isTrue);
    });

    test('builds valid RFC 1035 DNS query packet for hostname', () {
      final packet = DnsBenchmarkServiceImpl.buildDnsQueryPacket('google.com', 0x1234);
      expect(packet.length, greaterThan(12));
      // Transaction ID
      expect(packet[0], equals(0x12));
      expect(packet[1], equals(0x34));
      // Flags (Standard query, Recursion Desired: 0x0100)
      expect(packet[2], equals(0x01));
      expect(packet[3], equals(0x00));
      // Questions count = 1
      expect(packet[4], equals(0x00));
      expect(packet[5], equals(0x01));
    });

    test('classifies HTTP status codes accurately', () {
      expect(
        DnsBenchmarkServiceImpl.classifyStatus(200),
        equals(BenchmarkStatus.reachable),
      );
      expect(
        DnsBenchmarkServiceImpl.classifyStatus(301),
        equals(BenchmarkStatus.reachable),
      );
      expect(
        DnsBenchmarkServiceImpl.classifyStatus(403),
        equals(BenchmarkStatus.blocked),
      );
      expect(
        DnsBenchmarkServiceImpl.classifyStatus(500),
        equals(BenchmarkStatus.error),
      );
      expect(
        DnsBenchmarkServiceImpl.classifyStatus(null),
        equals(BenchmarkStatus.failed),
      );
    });

    test('extracts IPv4 address from DNS answer payload', () {
      // Mock response for google.com resolving to 142.250.190.46
      final query = DnsBenchmarkServiceImpl.buildDnsQueryPacket('google.com', 0x1234);
      final response = Uint8List.fromList([
        ...query,
        // Answer header: Name pointer 0xc00c, Type A (0x0001), Class IN (0x0001), TTL 300, RdLength 4
        0xc0, 0x0c, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0x01, 0x2c, 0x00, 0x04,
        142, 250, 190, 46,
      ]);
      response[7] = 1; // ANCOUNT = 1 answer

      final parsedIp = DnsBenchmarkServiceImpl.parseIpFromDnsResponse(response);
      expect(parsedIp, equals('142.250.190.46'));
    });

    test('returns failed result when provider has no IPv4 addresses', () async {
      const emptyProvider = DnsProvider(
        id: 'empty',
        name: 'Empty DNS',
        description: 'No IPs',
        category: DnsCategory.custom,
        features: [],
        ipv4: [],
        ipv6: [],
      );
      final result = await service.benchmarkServer(
        emptyProvider,
        const BenchmarkTarget(key: 'test', label: 'Test', url: 'https://test.com'),
      );
      expect(result.status, equals(BenchmarkStatus.failed));
      expect(result.message, contains('No DNS address'));
    });
  });
}
