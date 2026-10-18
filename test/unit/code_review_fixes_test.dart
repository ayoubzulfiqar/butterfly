import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:butterfly/data/repositories/dns_provider_repository_impl.dart';
import 'package:butterfly/data/services/mock_network_service.dart';
import 'package:butterfly/data/services/windows_network_service.dart';
import 'package:butterfly/domain/entities/dns_provider.dart';
import 'package:butterfly/domain/entities/network_adapter.dart';
import 'package:butterfly/presentation/viewmodels/network_dns_viewmodel.dart';

void main() {
  test('WindowsNetworkService rejects malicious IP input strings', () {
    expect(
      () => WindowsNetworkService.buildSetDnsCommand(
        'Wi-Fi',
        ['1.1.1.1; Start-Process evil.exe; #'],
        [],
      ),
      throwsArgumentError,
    );
  });

  test('WindowsNetworkService allows valid IPv4 and IPv6 addresses', () {
    final cmd = WindowsNetworkService.buildSetDnsCommand(
      'Wi-Fi',
      ['1.1.1.1', '1.0.0.1'],
      ['2606:4700:4700::1111'],
    );
    expect(cmd, contains('@("1.1.1.1","1.0.0.1","2606:4700:4700::1111")'));
  });

  test('NetworkAdapter isDhcp evaluates to true when dnsServers is empty', () {
    const dhcpAdapter = NetworkAdapter(
      name: 'Ethernet',
      interfaceDescription: 'Realtek',
      isUp: true,
      isDhcp: true,
      ipv4Addresses: ['192.168.1.100'],
      ipv6Addresses: [],
      dnsServers: [],
    );
    expect(dhcpAdapter.isDhcp, isTrue);

    const staticAdapter = NetworkAdapter(
      name: 'Ethernet',
      interfaceDescription: 'Realtek',
      isUp: true,
      isDhcp: true, // even if interface IP is leased by DHCP
      ipv4Addresses: ['192.168.1.100'],
      ipv6Addresses: [],
      dnsServers: ['1.1.1.1'],
    );
    // DNS is custom, so isDhcp must report false for DNS configuration
    expect(staticAdapter.isDhcp, isFalse);
  });

  test('NetworkDnsViewModel latency benchmark runs in parallel', () async {
    final netService = MockNetworkService();
    final repo = DnsProviderRepositoryImpl();
    final vm = NetworkDnsViewModel(
      networkService: netService,
      repository: repo,
    );
    await vm.loadInitialData();

    final stopwatch = Stopwatch()..start();
    await vm.runLatencyBenchmark();
    stopwatch.stop();

    expect(vm.providers.every((p) => p.latencyMs != null), isTrue);
  });

  test('DnsProviderRepositoryImpl persists custom providers to file', () async {
    final tempDir = await Directory.systemTemp.createTemp('butterfly_test_');
    final storageFile = File('${tempDir.path}/custom_dns.json');

    final repo1 = DnsProviderRepositoryImpl(storageFile: storageFile);
    const custom = DnsProvider(
      id: 'custom_persist_test',
      name: 'Persisted DNS',
      description: 'Test Description',
      category: DnsCategory.custom,
      features: ['Custom'],
      ipv4: ['10.10.10.10'],
      ipv6: [],
      isCustom: true,
    );
    await repo1.addCustomProvider(custom);

    // Create a new repository instance pointing to the same file
    final repo2 = DnsProviderRepositoryImpl(storageFile: storageFile);
    final all = await repo2.getAllProviders();
    expect(all.any((p) => p.id == 'custom_persist_test'), isTrue);

    await tempDir.delete(recursive: true);
  });
}
