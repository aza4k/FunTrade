import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/candlestick.dart';

class CryptoApiService {
  static const String _tickerUrl =
      'https://api.binance.com/api/v3/ticker/24hr?symbols=["BTCUSDT","ETHUSDT","TONUSDT","SOLUSDT","BNBUSDT","DOGEUSDT","ARBUSDT","AVAXUSDT","BCHUSDT","ETCUSDT","XMRUSDT","SHIBUSDT"]';

  // Fetches 24h ticker for registered symbols
  static Future<Map<String, Map<String, dynamic>>> fetchRealPrices() async {
    try {
      final response = await http.get(Uri.parse(_tickerUrl)).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        final Map<String, Map<String, dynamic>> results = {};

        for (var item in data) {
          final String binanceSymbol = item['symbol'] as String;
          // Strip "USDT" suffix to match our symbols
          final String symbol = binanceSymbol.replaceAll('USDT', '');
          
          results[symbol] = {
            'price': double.parse(item['lastPrice'].toString()),
            'change24h': double.parse(item['priceChangePercent'].toString()),
          };
        }
        return results;
      } else {
        throw Exception('Failed to load prices: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback handled by provider
      rethrow;
    }
  }

  // Fetches historical klines/candlesticks
  static Future<List<Candlestick>> fetchCandles(
      String symbol, String interval, {int limit = 50}) async {
    // Standardize symbol for Binance
    final String binanceSymbol = '${symbol.toUpperCase()}USDT';
    final String url =
        'https://api.binance.com/api/v3/klines?symbol=$binanceSymbol&interval=$interval&limit=$limit';

    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 6),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data.map((jsonList) => Candlestick.fromJson(jsonList as List<dynamic>)).toList();
      } else {
        throw Exception('Failed to load candles: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }
}
