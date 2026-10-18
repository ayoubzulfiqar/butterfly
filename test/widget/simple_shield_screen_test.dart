import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:butterfly/data/services/mock_dpi_service.dart';
import 'package:butterfly/data/services/mock_network_service.dart';
import 'package:butterfly/data/repositories/dns_provider_repository_impl.dart';
import 'package:butterfly/presentation/viewmodels/dpi_viewmodel.dart';
import 'package:butterfly/presentation/viewmodels/navigation_viewmodel.dart';
import 'package:butterfly/presentation/viewmodels/network_dns_viewmodel.dart';
import 'package:butterfly/presentation/views/pages/simple_shield_screen.dart';
import 'package:butterfly/presentation/widgets/neon_power_shield.dart';
import 'package:butterfly/presentation/widgets/protection_levels_bar.dart';

void main() {
  group('SimpleShieldScreen Widget Tests', () {
    late NavigationViewModel navVm;
    late DpiViewModel dpiVm;
    late NetworkDnsViewModel dnsVm;

    setUp(() {
      navVm = NavigationViewModel();
      dpiVm = DpiViewModel(dpiService: MockDpiService());
      dnsVm = NetworkDnsViewModel(
        networkService: MockNetworkService(),
        repository: DnsProviderRepositoryImpl(),
      );
    });

    Widget createWidgetUnderTest() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: navVm),
          ChangeNotifierProvider.value(value: dpiVm),
          ChangeNotifierProvider.value(value: dnsVm),
        ],
        child: const MaterialApp(
          home: SimpleShieldScreen(),
        ),
      );
    }

    testWidgets('renders NeonPowerShield and ProtectionLevelsBar in Simple mode', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(NeonPowerShield), findsOneWidget);
      expect(find.byType(ProtectionLevelsBar), findsOneWidget);
      expect(find.textContaining('BUTTERFLY'), findsOneWidget);
    });

    testWidgets('tapping studio button switches view mode to studio', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final studioButton = find.byTooltip('Open Studio');
      expect(studioButton, findsOneWidget);

      await tester.tap(studioButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(navVm.viewMode, equals(AppViewMode.studio));
    });

    testWidgets('tapping power button toggles zapret2 bypass state', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(dpiVm.isRunning, isFalse);

      await tester.tap(find.byType(NeonPowerShield));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(dpiVm.isRunning, isTrue);
    });
  });
}
