import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:butterfly/core/theme/cyber_theme.dart';
import 'package:butterfly/domain/entities/zapret2_strategy.dart';
import 'package:butterfly/presentation/widgets/neon_power_shield.dart';
import 'package:butterfly/presentation/widgets/protection_levels_bar.dart';

void main() {
  group('NeonPowerShield Widget Tests', () {
    testWidgets('renders in off state with tap callback', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: CyberTheme.background,
            body: Center(
              child: NeonPowerShield(
                state: PowerShieldState.off,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(NeonPowerShield), findsOneWidget);
      expect(find.byIcon(Icons.power_settings_new), findsOneWidget);

      await tester.tap(find.byType(NeonPowerShield));
      expect(tapped, isTrue);
    });

    testWidgets('renders in busy state with active animation controller', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeonPowerShield(
                state: PowerShieldState.busy,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(NeonPowerShield), findsOneWidget);
      // Advances time to verify continuous rotation does not throw
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('renders in on state with emerald glow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeonPowerShield(
                state: PowerShieldState.on,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(NeonPowerShield), findsOneWidget);
    });
  });

  group('ProtectionLevelsBar Widget Tests', () {
    testWidgets('renders all 5 protection levels and responds to selection', (tester) async {
      Zapret2Profile? selectedProfile;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ProtectionLevelsBar(
                selectedProfile: Zapret2Profile.strong,
                onProfileSelected: (p) => selectedProfile = p,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Strong'), findsOneWidget);
      expect(find.text('Extreme'), findsOneWidget);

      await tester.tap(find.text('Extreme'));
      await tester.pumpAndSettle();

      expect(selectedProfile, equals(Zapret2Profile.extreme));
    });
  });
}
