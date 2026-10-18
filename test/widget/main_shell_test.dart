import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:butterfly/data/services/mock_network_service.dart';
import 'package:butterfly/data/services/mock_dpi_service.dart';
import 'package:butterfly/data/repositories/dns_provider_repository_impl.dart';
import 'package:butterfly/domain/entities/public_ip_info.dart';
import 'package:butterfly/domain/entities/scheduled_shutdown_state.dart';
import 'package:butterfly/domain/services/i_system_tools_service.dart';
import 'package:butterfly/presentation/viewmodels/diagnostics_viewmodel.dart';
import 'package:butterfly/presentation/viewmodels/dpi_viewmodel.dart';
import 'package:butterfly/presentation/viewmodels/navigation_viewmodel.dart';
import 'package:butterfly/presentation/viewmodels/network_dns_viewmodel.dart';
import 'package:butterfly/presentation/viewmodels/tools_viewmodel.dart';
import 'package:butterfly/presentation/views/main_shell_screen.dart';

class MockSystemTools implements ISystemToolsService {
  @override
  Future<PublicIpInfo> fetchPublicIpInfo({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    return const PublicIpInfo(
      ip: '198.51.100.99',
      city: 'Stockholm',
      country: 'Sweden',
      isp: 'Mullvad',
      asn: 'AS12345',
    );
  }

  @override
  Future<bool> setInterfaceStatus(String interfaceName, bool enable) async =>
      true;

  @override
  Future<bool> scheduleShutdown(Duration delay, {String? reason}) async => true;

  @override
  Future<bool> cancelShutdown() async => true;

  @override
  Future<ScheduledShutdownState> getShutdownStatus() async =>
      const ScheduledShutdownState.inactive();
}

void main() {
  testWidgets(
    'MainShellScreen renders 5-destination navigation rail and switches pages',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final netService = MockNetworkService();
      final dpiService = MockDpiService();
      final repo = DnsProviderRepositoryImpl();
      final toolsService = MockSystemTools();

      final dnsVm = NetworkDnsViewModel(
        networkService: netService,
        repository: repo,
      );
      final navVm = NavigationViewModel();
      final dpiVm = DpiViewModel(dpiService: dpiService);
      final diagVm = DiagnosticsViewModel();
      final toolsVm = ToolsViewModel(
        toolsService: toolsService,
      );

      await dnsVm.loadInitialData();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: navVm),
            ChangeNotifierProvider.value(value: dnsVm),
            ChangeNotifierProvider.value(value: dpiVm),
            ChangeNotifierProvider.value(value: diagVm),
            ChangeNotifierProvider.value(value: toolsVm),
          ],
          child: const MaterialApp(home: MainShellScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('DNS Resolvers'), findsWidgets);
      expect(find.text('DPI Bypass'), findsWidgets);
      expect(find.text('Tools'), findsWidgets);
      expect(find.text('Diagnostics'), findsWidgets);

      // Tap DNS Resolvers
      await tester.tap(find.text('DNS Resolvers').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Shecan'), findsWidgets);
      expect(find.text('Benchmark Target'), findsWidgets);

      // Tap DPI Bypass
      await tester.tap(find.text('DPI Bypass').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('GoodbyeDPI'), findsWidgets);

      // Tap Tools Studio
      await tester.tap(find.text('Tools').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Tools Studio'), findsWidgets);

      // Tap Diagnostics
      await tester.tap(find.text('Diagnostics').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Clear Console'), findsWidgets);
    },
  );
}
