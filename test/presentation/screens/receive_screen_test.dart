import 'package:bonsai_mobile/core/providers/wallet_provider.dart';
import 'package:bonsai_mobile/data/repositories/mock_wallet_repository.dart';
import 'package:bonsai_mobile/presentation/screens/receive_screen.dart';
import 'package:bonsai_mobile/presentation/widgets/copyable_address.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ReceiveScreen loads and displays address from repository', (
    WidgetTester tester,
  ) async {
    // Override the repository provider with the mock
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletRepositoryProvider.overrideWithValue(MockWalletRepository()),
        ],
        child: const MaterialApp(home: ReceiveScreen()),
      ),
    );

    // Initial state might be loading (multiple indicators possible)
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    // Pump to allow future to complete
    await tester.pumpAndSettle();

    // Verify loading is gone
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Verify address is displayed
    // The text might be truncated by CopyableAddress, so we check the widget property
    final copyableAddressFinder = find.byType(CopyableAddress);
    expect(copyableAddressFinder, findsOneWidget);

    final CopyableAddress widget = tester.widget(copyableAddressFinder);
    expect(widget.address, 'bc1qmockaddress123456789');

    // Also check that SOME text containing the start of the address is visible
    expect(find.textContaining('bc1qmock'), findsWidgets);
  });
}
