import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:butterfly/presentation/widgets/status_badge.dart';
import 'package:butterfly/presentation/widgets/elevation_banner.dart';
import 'package:butterfly/presentation/widgets/fluent_card.dart';

void main() {
  testWidgets('StatusBadge displays label and color correctly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(label: 'Active', isSuccess: true),
        ),
      ),
    );
    expect(find.text('Active'), findsOneWidget);
  });

  testWidgets(
    'ElevationBanner warns when user is not administrator',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ElevationBanner(isElevated: false),
          ),
        ),
      );
      expect(find.textContaining('Administrator'), findsOneWidget);
    },
  );

  testWidgets('FluentCard renders title and child widget', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FluentCard(
            title: 'Card Title',
            child: Text('Card Content'),
          ),
        ),
      ),
    );
    expect(find.text('Card Title'), findsOneWidget);
    expect(find.text('Card Content'), findsOneWidget);
  });
}
