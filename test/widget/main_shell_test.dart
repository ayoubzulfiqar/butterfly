import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:butterfly/data/services/mock_network_service.dart';
import 'package:butterfly/data/services/mock_dpi_service.dart';
import 'package:butterfly/data/repositories/dns_provider_repository_impl.dart';
import 'package:butterfly/presentation/viewmodels/navigation_viewmodel.dart';
import 'package:butterfly/presentation/viewmodels/network_dns_viewmodel.dart';
import 'package:butterfly/presentation/viewmodels/dpi_viewmodel.dart';
import 'package:butterfly/presentation/viewmodels/diagnostics_viewmodel.dart';
import 'package:butterfly/presentation/views/main_shell_screen.dart';

void main() {
  testWidgets(
    'MainShellScreen renders navigation rail and switches pages',
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

      final dnsVm = NetworkDnsViewModel(
        networkService: netService,
        repository: repo,
      );
      final navVm = NavigationViewModel();
      final dpiVm = DpiViewModel(dpiService: dpiService);
      final diagVm = DiagnosticsViewModel();

      await dnsVm.loadInitialData();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: navVm),
            ChangeNotifierProvider.value(value: dnsVm),
            ChangeNotifierProvider.value(value: dpiVm),
            ChangeNotifierProvider.value(value: diagVm),
          ],
          child: const MaterialApp(home: MainShellScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('DNS Resolvers'), findsWidgets);

      // Tap DNS Resolvers
      await tester.tap(find.text('DNS Resolvers').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Cloudflare'), findsWidgets);

      // Tap DPI Bypass
      await tester.tap(find.text('DPI Bypass').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('GoodbyeDPI'), findsWidgets);

      // Tap Diagnostics
      await tester.tap(find.text('Diagnostics').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Clear Console'), findsWidgets);
    },
  );
}
