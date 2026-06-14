import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/asset_price.dart';
import '../core/constants/config.dart';
import '../core/services/crypto_api_service.dart';

class MarketProvider extends ChangeNotifier {
  final Random _random = Random();
  Timer? _timer;
  int _tickCount = 0;
  bool _isLoading = false;

  final Map<String, AssetPrice> _prices = {
    'BTC': const AssetPrice(symbol: 'BTC', currentPrice: 68000.00, change24h: 1.45, previousPrice: 68000.00),
    'ETH': const AssetPrice(symbol: 'ETH', currentPrice: 3800.00, change24h: -0.85, previousPrice: 3800.00),
    'TON': const AssetPrice(symbol: 'TON', currentPrice: 7.20, change24h: 5.12, previousPrice: 7.20),
    'SOL': const AssetPrice(symbol: 'SOL', currentPrice: 165.00, change24h: -2.34, previousPrice: 165.00),
    'BNB': const AssetPrice(symbol: 'BNB', currentPrice: 580.00, change24h: 0.95, previousPrice: 580.00),
    'DOGE': const AssetPrice(symbol: 'DOGE', currentPrice: 0.14, change24h: -3.45, previousPrice: 0.14),
    'ARB': const AssetPrice(symbol: 'ARB', currentPrice: 0.95, change24h: -0.50, previousPrice: 0.95),
    'AVAX': const AssetPrice(symbol: 'AVAX', currentPrice: 36.00, change24h: 2.10, previousPrice: 36.00),
    'BCH': const AssetPrice(symbol: 'BCH', currentPrice: 480.00, change24h: -1.05, previousPrice: 480.00),
    'ETC': const AssetPrice(symbol: 'ETC', currentPrice: 28.00, change24h: 0.25, previousPrice: 28.00),
    'XMR': const AssetPrice(symbol: 'XMR', currentPrice: 170.00, change24h: 1.80, previousPrice: 170.00),
    'SHIB': const AssetPrice(symbol: 'SHIB', currentPrice: 0.00002200, change24h: -5.40, previousPrice: 0.00002200),
  };

  Map<String, AssetPrice> get prices => Map.unmodifiable(_prices);
  List<AssetPrice> get pricesList => _prices.values.toList();
  Map<String, double> get pricesMap => _prices.map((key, value) => MapEntry(key, value.currentPrice));
  bool get isLoading => _isLoading;

  MarketProvider() {
    _initPriceHistories();
    _syncWithBinance(); // Initial API sync
    _startTimer();
  }

  void _initPriceHistories() {
    _prices.forEach((symbol, asset) {
      final history = _generate1DayHistory(asset.currentPrice, asset.change24h);
      _prices[symbol] = asset.copyWith(priceHistory: history);
    });
  }

  List<double> _generate1DayHistory(double currentPrice, double change24h) {
    final history = <double>[];
    // Calculate price 24 hours ago
    final double startPrice = currentPrice / (1.0 + (change24h / 100.0));
    history.add(startPrice);

    double tempPrice = startPrice;
    final int steps = 29; // 30 points total
    final double targetTrend = (currentPrice - startPrice) / steps;

    for (int i = 1; i < steps; i++) {
      // Add trend component and random fluctuations to make the chart look like a financial chart
      final double fluctuation = (targetTrend.abs() * 1.5) * ((_random.nextDouble() * 2.0) - 1.0);
      tempPrice = tempPrice + targetTrend + fluctuation;
      
      // Prevent price from going to zero
      if (tempPrice <= 0) {
        tempPrice = startPrice * 0.1;
      }
      history.add(tempPrice);
    }

    history.add(currentPrice);
    return history;
  }

  Future<void> _syncWithBinance() async {
    _isLoading = true;
    notifyListeners();
    try {
      final apiPrices = await CryptoApiService.fetchRealPrices();
      apiPrices.forEach((symbol, data) {
        if (_prices.containsKey(symbol)) {
          final asset = _prices[symbol]!;
          final double newPrice = data['price'] as double;
          final double change24h = data['change24h'] as double;
          
          // Regenerate 1-day chart based on updated API price and 24h change
          final newHistory = _generate1DayHistory(newPrice, change24h);

          _prices[symbol] = AssetPrice(
            symbol: symbol,
            currentPrice: newPrice,
            change24h: change24h,
            previousPrice: asset.currentPrice,
            priceHistory: newHistory,
          );
        }
      });
    } catch (e) {
      debugPrint('Error syncing prices with Binance API: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(AppConfig.priceUpdateInterval, (timer) {
      _tickCount++;
      // Sync with Binance API every 30 seconds (6 ticks of 5s)
      if (_tickCount % 6 == 0) {
        _syncWithBinance();
      } else {
        _tickPrices();
      }
    });
  }

  void _tickPrices() {
    _prices.forEach((symbol, asset) {
      // Simulate minor fluctuation: ±0.03%
      final changePercent = (_random.nextDouble() * 0.06) - 0.03;
      final newPrice = asset.currentPrice * (1.0 + (changePercent / 100.0));
      
      // Update only the last point of the 1-day sparkline history
      final newHistory = List<double>.from(asset.priceHistory);
      if (newHistory.isNotEmpty) {
        newHistory[newHistory.length - 1] = newPrice;
      }

      _prices[symbol] = AssetPrice(
        symbol: symbol,
        currentPrice: newPrice,
        change24h: asset.change24h + changePercent,
        previousPrice: asset.currentPrice,
        priceHistory: newHistory,
      );
    });
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
