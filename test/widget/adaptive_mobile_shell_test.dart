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
import 'package:butterfly/presentation/views/pages/simple_shield_screen.dart';
import 'package:butterfly/presentation/widgets/neon_power_shield.dart';

class _MockSystemTools implements ISystemToolsService {
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

Widget _buildTestApp({
  required NavigationViewModel navVm,
  required NetworkDnsViewModel dnsVm,
  required DpiViewModel dpiVm,
  required DiagnosticsViewModel diagVm,
  required ToolsViewModel toolsVm,
  required Widget child,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: navVm),
      ChangeNotifierProvider.value(value: dnsVm),
      ChangeNotifierProvider.value(value: dpiVm),
      ChangeNotifierProvider.value(value: diagVm),
      ChangeNotifierProvider.value(value: toolsVm),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  group('Adaptive Responsive Navigation & Mobile UI Tests', () {
    late NavigationViewModel navVm;
    late NetworkDnsViewModel dnsVm;
    late DpiViewModel dpiVm;
    late DiagnosticsViewModel diagVm;
    late ToolsViewModel toolsVm;

    setUp(() async {
      final netService = MockNetworkService();
      final dpiService = MockDpiService();
      final repo = DnsProviderRepositoryImpl();
      final toolsService = _MockSystemTools();

      dnsVm = NetworkDnsViewModel(
        networkService: netService,
        repository: repo,
      );
      navVm = NavigationViewModel(initialMode: AppViewMode.studio);
      dpiVm = DpiViewModel(dpiService: dpiService);
      diagVm = DiagnosticsViewModel();
      toolsVm = ToolsViewModel(toolsService: toolsService);

      await dnsVm.loadInitialData();
    });

    testWidgets(
      'MainShellScreen renders bottom NavigationBar on compact mobile viewport (< 600dp)',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          _buildTestApp(
            navVm: navVm,
            dnsVm: dnsVm,
            dpiVm: dpiVm,
            diagVm: diagVm,
            toolsVm: toolsVm,
            child: const MainShellScreen(),
          ),
        );
        await tester.pumpAndSettle();

        // Assert NavigationBar is present and NavigationRail is absent
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.byType(NavigationRail), findsNothing);

        // Tap a navigation destination (DNS Resolvers) and verify tab index changes cleanly
        await tester.tap(find.text('DNS Resolvers').first);
        await tester.pumpAndSettle();

        expect(navVm.currentIndex, equals(1));
        expect(navVm.currentTab, equals(NavigationTab.dnsResolvers));

        // Tap another destination (Tools)
        await tester.tap(find.text('Tools').first);
        await tester.pumpAndSettle();

        expect(navVm.currentIndex, equals(4));
        expect(navVm.currentTab, equals(NavigationTab.tools));
      },
    );

    testWidgets(
      'MainShellScreen renders NavigationRail on desktop/tablet viewport (>= 600dp)',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          _buildTestApp(
            navVm: navVm,
            dnsVm: dnsVm,
            dpiVm: dpiVm,
            diagVm: diagVm,
            toolsVm: toolsVm,
            child: const MainShellScreen(),
          ),
        );
        await tester.pumpAndSettle();

        // Assert NavigationRail is present and NavigationBar is absent
        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
      },
    );

    testWidgets(
      'SimpleShieldScreen renders cleanly without RenderFlex overflow on 360dp phone screen',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        navVm.setViewMode(AppViewMode.simple);

        await tester.pumpWidget(
          _buildTestApp(
            navVm: navVm,
            dnsVm: dnsVm,
            dpiVm: dpiVm,
            diagVm: diagVm,
            toolsVm: toolsVm,
            child: const SimpleShieldScreen(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(NeonPowerShield), findsOneWidget);
        // Expect zero flutter errors or layout overflows
        expect(tester.takeException(), isNull);
      },
    );
  });
}
