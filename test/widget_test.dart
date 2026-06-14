import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_trade/core/constants/colors.dart';
import 'package:fun_trade/widgets/crypto_logo.dart';

void main() {
  testWidgets('Core App color scheme configuration compile check', (WidgetTester tester) async {
    // Basic test to verify classes compile and import structure works
    expect(AppColors.background, const Color(0xFF0A0C10));
    expect(AppColors.surface, const Color(0xFF161920));
    expect(AppColors.primary, const Color(0xFF0E76FD));
  });

  testWidgets('CryptoLogo renders successfully for all symbols', (WidgetTester tester) async {
    const symbols = [
      'BTC', 'ETH', 'TON', 'SOL', 'BNB', 'DOGE',
      'ARB', 'AVAX', 'BCH', 'ETC', 'XMR', 'SHIB'
    ];

    for (final symbol in symbols) {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: CryptoLogo(symbol: symbol, size: 40),
            ),
          ),
        ),
      );

      // Verify that the widget compiles and renders without throwing any exceptions
      expect(find.byType(CryptoLogo), findsOneWidget);
    }
  });
}
