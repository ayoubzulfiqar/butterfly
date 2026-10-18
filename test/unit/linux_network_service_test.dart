import 'package:flutter_test/flutter_test.dart';
import 'package:butterfly/data/services/linux_network_service.dart';
import 'package:butterfly/data/services/platform_service_factory.dart';
import 'package:butterfly/domain/services/i_network_service.dart';
import 'package:butterfly/domain/services/i_dpi_service.dart';

void main() {
  group('LinuxNetworkService Commands', () {
    test('builds safe resolvectl set DNS command', () {
      final cmd = LinuxNetworkService.buildSetDnsCommand(
        'wlp1s0',
        ['1.1.1.1', '1.0.0.1'],
      );
      expect(cmd, equals('resolvectl dns wlp1s0 1.1.1.1 1.0.0.1'));
    });

    test('builds safe resolvectl revert command to restore DHCP', () {
      final cmd = LinuxNetworkService.buildResetDnsCommand('eth0');
      expect(cmd, equals('resolvectl revert eth0'));
    });

    test('builds flush cache command', () {
      final cmd = LinuxNetworkService.buildFlushCacheCommand();
      expect(cmd, equals('resolvectl flush-caches'));
    });

    test('rejects interface names with dangerous shell injection characters', () {
      expect(
        () => LinuxNetworkService.buildSetDnsCommand(
          'wlp1s0; rm -rf /',
          ['1.1.1.1'],
        ),
        throwsArgumentError,
      );

      expect(
        () => LinuxNetworkService.buildSetDnsCommand(
          'wlp1s0`reboot`',
          ['1.1.1.1'],
        ),
        throwsArgumentError,
      );

      expect(
        () => LinuxNetworkService.buildResetDnsCommand('eth0 && whoami'),
        throwsArgumentError,
      );
    });

    test('rejects invalid DNS IP addresses', () {
      expect(
        () => LinuxNetworkService.buildSetDnsCommand(
          'wlp1s0',
          ['1.1.1.1; echo pwned'],
        ),
        throwsArgumentError,
      );
    });

    test('parses ip -j link and resolvectl output into NetworkAdapter list', () {
      const ipLinkJson = '''
      [
        {
          "ifname": "wlp1s0",
          "operstate": "UP",
          "address": "00:11:22:33:44:55",
          "link_type": "ether"
        },
        {
          "ifname": "lo",
          "operstate": "UNKNOWN",
          "address": "00:00:00:00:00:00",
          "link_type": "loopback"
        }
      ]
      ''';

      const resolvectlDnsOutput = '''
      Global:
      Link 2 (wlp1s0): 1.1.1.1 1.0.0.1
      Link 1 (lo):
      ''';

      final adapters = LinuxNetworkService.parseAdaptersFromOutput(
        ipLinkJson: ipLinkJson,
        resolvectlDnsOutput: resolvectlDnsOutput,
      );

      expect(adapters.length, equals(1)); // loopback filtered out
      final wifi = adapters.first;
      expect(wifi.name, equals('wlp1s0'));
      expect(wifi.isUp, isTrue);
      expect(wifi.dnsServers, equals(['1.1.1.1', '1.0.0.1']));
      expect(wifi.isDhcp, isFalse);
    });
  });

  group('PlatformServiceFactory', () {
    test('returns platform-appropriate network and dpi services', () {
      final netService = PlatformServiceFactory.createNetworkService();
      final dpiService = PlatformServiceFactory.createDpiService();

      expect(netService, isA<INetworkService>());
      expect(dpiService, isA<IDpiService>());
    });
  });
}
