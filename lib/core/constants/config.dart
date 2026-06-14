import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  static const double initialBalance = 0.00;
  static const Duration priceUpdateInterval = Duration(seconds: 5);
  
  static const List<String> cryptoSymbols = [
    'BTC', 'ETH', 'TON', 'SOL', 'BNB', 'DOGE',
    'ARB', 'AVAX', 'BCH', 'ETC', 'XMR', 'SHIB'
  ];

  static const Map<String, String> cryptoNames = {
    'BTC': 'Bitcoin',
    'ETH': 'Ethereum',
    'TON': 'Toncoin',
    'SOL': 'Solana',
    'BNB': 'Binance Coin',
    'DOGE': 'Dogecoin',
    'ARB': 'Arbitrum',
    'AVAX': 'Avalanche',
    'BCH': 'Bitcoin Cash',
    'ETC': 'Ethereum Classic',
    'XMR': 'Monero',
    'SHIB': 'Shiba Inu',
  };

  static const List<int> leverageLevels = [1, 10, 20, 50];

  // Toggle to switch between Test Ads and Production Ads
  static const bool useTestAds = true; // Set to false to use your production ads

  static String get bannerAdUnitId {
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return useTestAds 
          ? 'ca-app-pub-3940256099942544/6300978111' // Google Test Banner
          : 'ca-app-pub-2737004395065641/1872576751'; // Production Banner
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    return '';
  }

  static String get interstitialAdUnitId {
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return useTestAds 
          ? 'ca-app-pub-3940256099942544/1033173712' // Google Test Interstitial
          : 'ca-app-pub-2737004395065641/7906971830'; // Production Interstitial
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    }
    return '';
  }

  static String get rewardedAdUnitId {
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return useTestAds 
          ? 'ca-app-pub-3940256099942544/5224354917' // Google Test Rewarded
          : 'ca-app-pub-2737004395065641/6933331740'; // Production Rewarded
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    }
    return '';
  }
}
