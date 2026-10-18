import 'package:flutter_test/flutter_test.dart';
import 'package:butterfly/data/services/mock_network_service.dart';
import 'package:butterfly/data/services/windows_network_service.dart';

void main() {
  test('MockNetworkService simulates adapter discovery and DNS setting', () async {
    final service = MockNetworkService();
    final adapters = await service.getAdapters();
    expect(adapters.isNotEmpty, isTrue);

    final adapterName = adapters.first.name;
    await service.setDns(
      adapterName,
      ['1.1.1.1', '1.0.0.1'],
      ['2606:4700:4700::1111'],
    );
    final currentDns = await service.getCurrentDns(adapterName);
    expect(currentDns, contains('1.1.1.1'));
    expect(currentDns, contains('2606:4700:4700::1111'));

    await service.restoreDns(adapterName);
    final restoredDns = await service.getCurrentDns(adapterName);
    expect(restoredDns.isEmpty, isTrue);
  });

  test('MockNetworkService simulates DNS ping latency', () async {
    final service = MockNetworkService();
    final latency = await service.pingHost('1.1.1.1');
    expect(latency, isNotNull);
    expect(latency! >= 0, isTrue);
  });

  test(
    'WindowsNetworkService formats combined IPv4 and IPv6 command safely',
    () {
      final command = WindowsNetworkService.buildSetDnsCommand(
        'Wi-Fi "Guest"',
        ['1.1.1.1', '1.0.0.1'],
        ['2606:4700:4700::1111'],
      );
      expect(command, contains(r'Wi-Fi `"Guest`"'));
      expect(
        command,
        contains(r'@("1.1.1.1","1.0.0.1","2606:4700:4700::1111")'),
      );
    },
  );

  test('WindowsNetworkService formats reset command safely', () {
    final command = WindowsNetworkService.buildResetDnsCommand('Ethernet 2');
    expect(command, contains('Set-DnsClientServerAddress -InterfaceAlias "Ethernet 2" -ResetServerAddresses'));
  });
}
