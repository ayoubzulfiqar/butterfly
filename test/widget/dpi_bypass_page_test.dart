import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:butterfly/data/services/mock_dpi_service.dart';
import 'package:butterfly/presentation/viewmodels/dpi_viewmodel.dart';
import 'package:butterfly/presentation/views/pages/dpi_bypass_page.dart';

void main() {
  group('DpiBypassPage Widget Tests', () {
    late MockDpiService dpiService;
    late DpiViewModel dpiVm;

    setUp(() {
      dpiService = MockDpiService();
      dpiVm = DpiViewModel(dpiService: dpiService);
    });

    Widget createWidgetUnderTest() {
      return ChangeNotifierProvider<DpiViewModel>.value(
        value: dpiVm,
        child: const MaterialApp(
          home: Scaffold(
            body: DpiBypassPage(),
          ),
        ),
      );
    }

    testWidgets('renders zapret2 engine by default with strategy presets and CLI preview', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('zapret2 (Next-Gen)'), findsOneWidget);
      expect(find.text('GoodbyeDPI (Legacy)'), findsOneWidget);

      // Verify zapret2 strategies are visible
      expect(find.text('Strong'), findsWidgets);
      expect(find.text('Extreme'), findsWidgets);

      // Verify live CLI preview is rendered
      expect(find.textContaining('zapret2:'), findsOneWidget);
    });

    testWidgets('switching engine to GoodbyeDPI updates available presets and preview', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final legacyChip = find.text('GoodbyeDPI (Legacy)');
      await tester.tap(legacyChip);
      await tester.pumpAndSettle();

      expect(dpiVm.selectedEngine, equals('goodbyedpi'));
      expect(find.text('Standard Bypass'), findsWidgets);
      expect(find.textContaining('goodbyedpi'), findsWidgets);
    });

    testWidgets('starting zapret2 bypass invokes service and shows running status', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('RUNNING'), findsNothing);
      expect(find.text('STOPPED'), findsOneWidget);

      final startButton = find.text('Start DPI Bypass');
      await tester.tap(startButton);
      await tester.pumpAndSettle();

      expect(dpiVm.isRunning, isTrue);
      expect(find.text('RUNNING'), findsOneWidget);
    });
  });
}
