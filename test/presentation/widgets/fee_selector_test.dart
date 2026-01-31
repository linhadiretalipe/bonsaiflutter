import 'package:bonsai_mobile/presentation/widgets/fee_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FeeSelector renders options', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeeSelector(currentFeeRate: 1.0, onFeeSelected: (_) {}),
        ),
      ),
    );

    expect(find.text('Slow'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Fast'), findsOneWidget);
  });

  testWidgets('FeeSelector triggers callback on selection', (
    WidgetTester tester,
  ) async {
    double? selectedFee;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeeSelector(
            currentFeeRate: 1.0,
            onFeeSelected: (rate) {
              selectedFee = rate;
            },
          ),
        ),
      ),
    );

    // Tap "Medium" (10.0)
    await tester.tap(find.text('Medium'));
    await tester.pump();

    expect(selectedFee, 10.0);
  });

  testWidgets('FeeSelector shows custom fee text if > 50', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeeSelector(currentFeeRate: 60.0, onFeeSelected: (_) {}),
        ),
      ),
    );

    expect(find.textContaining('Custom Fee: 60.0 sats/vB'), findsOneWidget);
  });
}
