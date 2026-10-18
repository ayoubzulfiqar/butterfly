import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:butterfly/domain/entities/network_adapter.dart';
import 'package:butterfly/domain/entities/dns_provider.dart';
import 'package:butterfly/domain/entities/public_ip_info.dart';
import 'package:butterfly/domain/entities/scheduled_shutdown_state.dart';
import 'package:butterfly/domain/repositories/i_dns_provider_repository.dart';
import 'package:butterfly/domain/services/i_network_service.dart';
import 'package:butterfly/domain/services/i_system_tools_service.dart';
import 'package:butterfly/presentation/viewmodels/network_dns_viewmodel.dart';
import 'package:butterfly/presentation/viewmodels/tools_viewmodel.dart';
import 'package:butterfly/presentation/views/pages/tools_page.dart';

class MockSystemTools implements ISystemToolsService {
  @override
  Future<PublicIpInfo> fetchPublicIpInfo({Duration timeout = const Duration(seconds: 8)}) async {
    return const PublicIpInfo(
      ip: '198.51.100.99',
      city: 'Stockholm',
      country: 'Sweden',
      isp: 'Mullvad',
      asn: 'AS12345',
    );
  }

  @override
  Future<bool> setInterfaceStatus(String interfaceName, bool enable) async => true;

  @override
  Future<bool> scheduleShutdown(Duration delay, {String? reason}) async => true;

  @override
  Future<bool> cancelShutdown() async => true;

  @override
  Future<ScheduledShutdownState> getShutdownStatus() async =>
      const ScheduledShutdownState.inactive();
}

class MockNetService implements INetworkService {
  @override
  Future<bool> isAdministrator() async => true;

  @override
  Future<List<NetworkAdapter>> getAdapters() async => [
        const NetworkAdapter(
          name: 'Wi-Fi',
          interfaceDescription: 'Intel Wi-Fi 6',
          isUp: true,
          ipv4Addresses: ['192.168.1.10'],
          ipv6Addresses: [],
          dnsServers: ['1.1.1.1'],
        ),
      ];

  @override
  Future<List<String>> getCurrentDns(String adapterName) async => ['1.1.1.1'];

  @override
  Future<void> setDns(String adapterName, List<String> ipv4, List<String> ipv6) async {}

  @override
  Future<void> restoreDns(String adapterName) async {}

  @override
  Future<void> flushDnsCache() async {}

  @override
  Future<int?> pingHost(String host, {Duration timeout = const Duration(seconds: 2)}) async => 20;
}

class MockRepo implements IDnsProviderRepository {
  @override
  List<DnsProvider> getBuiltInProviders() => [];

  @override
  Future<List<DnsProvider>> getAllProviders() async => [];

  @override
  Future<void> addCustomProvider(DnsProvider provider) async {}

  @override
  Future<void> deleteCustomProvider(String id) async {}
}

void main() {
  testWidgets('ToolsPage renders IP Telemetry, Adapter Switcher, and Shutdown cards', (tester) async {
    final toolsService = MockSystemTools();
    final toolsVm = ToolsViewModel(toolsService: toolsService);
    final netVm = NetworkDnsViewModel(
      networkService: MockNetService(),
      repository: MockRepo(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: toolsVm),
            ChangeNotifierProvider.value(value: netVm),
          ],
          child: const Scaffold(body: ToolsPage()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Public IP & Telemetry'), findsOneWidget);
    expect(find.text('Network Adapters'), findsOneWidget);
    expect(find.text('Scheduled System Shutdown'), findsOneWidget);
    expect(find.text('+15m'), findsOneWidget);
    expect(find.text('+30m'), findsOneWidget);
    expect(find.text('+1h'), findsOneWidget);
  });
}
