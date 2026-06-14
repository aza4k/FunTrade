import 'package:flutter_test/flutter_test.dart';
import 'package:fun_trade/models/position.dart';
import 'package:fun_trade/providers/portfolio_provider.dart';
import 'package:fun_trade/core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Trading Math & Calculations', () {
    test('Long Position PnL calculation', () {
      final pos = Position(
        id: '1',
        symbol: 'BTC',
        isLong: true,
        margin: 100.0,
        leverage: 10,
        entryPrice: 60000.0,
        currentPrice: 63000.0, // +5% price change
      );
      // PnL = ((63000 - 60000) / 60000) * 100 * 10 = 0.05 * 1000 = 50.0
      expect(pos.unrealizedPnl, closeTo(50.0, 0.0001));
    });

    test('Short Position PnL calculation', () {
      final pos = Position(
        id: '2',
        symbol: 'ETH',
        isLong: false,
        margin: 100.0,
        leverage: 10,
        entryPrice: 4000.0,
        currentPrice: 3800.0, // -5% price change
      );
      // PnL = ((4000 - 3800) / 4000) * 100 * 10 = 0.05 * 1000 = 50.0
      expect(pos.unrealizedPnl, closeTo(50.0, 0.0001));
    });

    test('Liquidation Price calculation for Long', () {
      final pos = Position(
        id: '3',
        symbol: 'BTC',
        isLong: true,
        margin: 100.0,
        leverage: 10,
        entryPrice: 60000.0,
        currentPrice: 60000.0,
      );
      // Liq price = 60000 * (1 - 0.9 / 10) = 60000 * 0.91 = 54600.0
      expect(pos.liquidationPrice, closeTo(54600.0, 0.0001));
    });

    test('Liquidation Price calculation for Short', () {
      final pos = Position(
        id: '4',
        symbol: 'BTC',
        isLong: false,
        margin: 100.0,
        leverage: 10,
        entryPrice: 60000.0,
        currentPrice: 60000.0,
      );
      // Liq price = 60000 * (1 + 0.9 / 10) = 60000 * 1.09 = 65400.0
      expect(pos.liquidationPrice, closeTo(65400.0, 0.0001));
    });
  });

  group('Portfolio Manager & Liquidation Engine', () {
    late StorageService storageService;
    late PortfolioProvider portfolioProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'funtrade_balance': 1000.00,
      });
      final prefs = await SharedPreferences.getInstance();
      storageService = StorageService(prefs);
      portfolioProvider = PortfolioProvider(storageService);
    });

    test('Opening position validates balance and deducts margin', () {
      // Starting balance is $1000.00
      expect(portfolioProvider.balance, 1000.00);

      // Attempt to open position with $1200 margin (exceeds balance)
      bool success = portfolioProvider.openPosition(
        symbol: 'BTC',
        isLong: true,
        margin: 1200.0,
        leverage: 10,
        currentPrice: 60000.0,
      );
      expect(success, false);
      expect(portfolioProvider.balance, 1000.00);
      expect(portfolioProvider.openPositions.isEmpty, true);

      // Open valid position with $200 margin
      success = portfolioProvider.openPosition(
        symbol: 'BTC',
        isLong: true,
        margin: 200.0,
        leverage: 10,
        currentPrice: 60000.0,
      );
      expect(success, true);
      expect(portfolioProvider.balance, 800.00);
      expect(portfolioProvider.openPositions.length, 1);
    });

    test('Liquidation Engine triggers at <= -90% PnL', () {
      // Open position with $100 margin, 10x leverage
      portfolioProvider.openPosition(
        symbol: 'BTC',
        isLong: true,
        margin: 100.0,
        leverage: 10,
        currentPrice: 60000.0,
      );

      // Update price to 55000 (loss is ((55000-60000)/60000)*100*10 = -8.33% * 1000 = -83.33) -> Loss is 83.33%, not yet liquidated
      portfolioProvider.updatePrices(const {'BTC': 55000.0});
      expect(portfolioProvider.openPositions.length, 1);
      expect(portfolioProvider.tradeHistory.isEmpty, true);

      // Update price to 54600 (loss is ((54600-60000)/60000)*1000 = -0.09 * 1000 = -90.0) -> Liquidation should trigger!
      portfolioProvider.updatePrices(const {'BTC': 54600.0});
      expect(portfolioProvider.openPositions.isEmpty, true);
      expect(portfolioProvider.tradeHistory.length, 1);
      expect(portfolioProvider.tradeHistory.first.isLiquidated, true);
      expect(portfolioProvider.tradeHistory.first.finalPnl, -100.0);
      expect(portfolioProvider.balance, 900.0); // balance remains 900 (margin was already deducted at open)
    });
  });
}
