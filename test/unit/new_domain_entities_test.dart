import 'package:flutter_test/flutter_test.dart';
import 'package:butterfly/domain/entities/benchmark_target.dart';
import 'package:butterfly/domain/entities/dns_benchmark_result.dart';
import 'package:butterfly/domain/entities/public_ip_info.dart';
import 'package:butterfly/domain/entities/scheduled_shutdown_state.dart';

void main() {
  group('BenchmarkTarget', () {
    test('extracts hostname and normalizes URL', () {
      const target = BenchmarkTarget(
        key: 'chatgpt',
        label: 'ChatGPT',
        url: 'https://chatgpt.com/test?query=1',
      );
      expect(target.hostname, equals('chatgpt.com'));
      expect(target.key, equals('chatgpt'));
      expect(target.label, equals('ChatGPT'));
    });

    test('extracts hostname when url lacks scheme', () {
      const target = BenchmarkTarget(
        key: 'google',
        label: 'Google',
        url: 'google.com',
      );
      expect(target.hostname, equals('google.com'));
    });
  });

  group('DnsBenchmarkResult', () {
    test('instantiates with status classification and attributes', () {
      const result = DnsBenchmarkResult(
        providerKey: 'CF',
        providerName: 'Cloudflare',
        targetKey: 'chatgpt',
        status: BenchmarkStatus.reachable,
        latencyMs: 42,
        resolvedIp: '104.18.2.1',
        message: 'Reachable',
      );
      expect(result.status, equals(BenchmarkStatus.reachable));
      expect(result.isSuccessful, isTrue);
      expect(result.isBlocked, isFalse);
    });

    test('blocked classification recognizes censorship 403 response', () {
      const result = DnsBenchmarkResult(
        providerKey: 'SHECAN',
        providerName: 'Shecan',
        targetKey: 'youtube',
        status: BenchmarkStatus.blocked,
        latencyMs: 120,
        resolvedIp: '142.250.180.14',
        message: 'Blocked (403 Forbidden)',
      );
      expect(result.status, equals(BenchmarkStatus.blocked));
      expect(result.isSuccessful, isFalse);
      expect(result.isBlocked, isTrue);
    });
  });

  group('PublicIpInfo', () {
    test('parses from ip.wtf json payload correctly', () {
      final json = {
        'ip': '198.51.100.45',
        'location': {
          'country': 'US',
          'country_name': 'United States',
          'city': 'San Francisco',
          'latitude': 37.7749,
          'longitude': -122.4194,
          'timezone': {'name': 'America/Los_Angeles'},
        },
        'as': {
          'number': 13335,
          'name': 'Cloudflare, Inc.',
        },
      };

      final info = PublicIpInfo.fromJson(json);
      expect(info.ip, equals('198.51.100.45'));
      expect(info.country, equals('United States'));
      expect(info.city, equals('San Francisco'));
      expect(info.asn, equals('AS13335'));
      expect(info.isp, equals('Cloudflare, Inc.'));
      expect(info.latitude, equals(37.7749));
      expect(info.longitude, equals(-122.4194));
    });

    test('handles fallback flat json payload safely', () {
      final json = {'ip': '203.0.113.1'};
      final info = PublicIpInfo.fromJson(json);
      expect(info.ip, equals('203.0.113.1'));
      expect(info.country, isNull);
      expect(info.asn, isNull);
    });
  });

  group('ScheduledShutdownState', () {
    test('computes inactive state correctly', () {
      const state = ScheduledShutdownState.inactive();
      expect(state.isActive, isFalse);
      expect(state.targetTime, isNull);
      expect(state.remainingDuration, isNull);
    });

    test('computes active state and remaining duration', () {
      final target = DateTime.now().add(const Duration(minutes: 30));
      final state = ScheduledShutdownState.active(
        targetTime: target,
        reason: 'Maintenance',
      );
      expect(state.isActive, isTrue);
      expect(state.reason, equals('Maintenance'));
      expect(state.remainingDuration, isNotNull);
      expect(state.remainingDuration!.inMinutes, inInclusiveRange(28, 30));
    });
  });
}
