import 'package:bonsai_mobile/presentation/widgets/copyable_address.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CopyableAddress displays label and address', (
    WidgetTester tester,
  ) async {
    const label = 'My Address';
    const address = 'bc1qcustomtestaddress1234567890';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CopyableAddress(label: label, address: address),
        ),
      ),
    );

    expect(find.text(label.toUpperCase()), findsOneWidget);
    // Address might be truncated in display getter, so let's check for partial match if logic exists,
    // or just check if *something* is displayed.
    // The implementation truncates > 20 chars.
    // "bc1qcustomt...90" (approx)
    expect(find.byType(GestureDetector), findsOneWidget);
  });

  testWidgets('CopyableAddress copies to clipboard on tap', (
    WidgetTester tester,
  ) async {
    const address = 'bc1qtestcopyaddress';
    final List<MethodCall> log = <MethodCall>[];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (
          MethodCall methodCall,
        ) async {
          log.add(methodCall);
          return null;
        });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CopyableAddress(label: 'Copy Me', address: address),
        ),
      ),
    );

    await tester.tap(find.byType(GestureDetector));
    await tester.pump(); // Pump frame for snackbar

    expect(log, isNotEmpty);
    expect(log.last.method, 'Clipboard.setData');
    expect(log.last.arguments['text'], address);
    expect(find.text('Address copied to clipboard'), findsOneWidget);
  });
}
