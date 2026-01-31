import 'package:bonsai_mobile/presentation/widgets/info_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('InfoRow displays label and value correctly', (
    WidgetTester tester,
  ) async {
    const label = 'Test Label';
    const value = 'Test Value';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: InfoRow(label: label, value: value),
        ),
      ),
    );

    expect(find.text(label), findsOneWidget);
    expect(find.text(value), findsOneWidget);
  });

  testWidgets('InfoRow applies correct styles for isTotal=true', (
    WidgetTester tester,
  ) async {
    const label = 'Total';
    const value = '100 BTC';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: InfoRow(label: label, value: value, isTotal: true),
        ),
      ),
    );

    final valueText = tester.widget<Text>(find.text(value));
    expect(valueText.style?.fontSize, 18);
    expect(valueText.style?.fontWeight, FontWeight.bold);
  });

  testWidgets('InfoRow applies correct styles for isTotal=false', (
    WidgetTester tester,
  ) async {
    const label = 'Details';
    const value = 'Some details';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: InfoRow(label: label, value: value, isTotal: false),
        ),
      ),
    );

    final valueText = tester.widget<Text>(find.text(value));
    expect(valueText.style?.fontSize, 14);
    // When not total, typically font weight is normal or derived from theme
    // Specifically looking for the style defined in InfoRow
  });
}
