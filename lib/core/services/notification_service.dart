import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/crypto_api_service.dart';
import '../constants/config.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> requestPermissions() async {
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    final iosPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  static Future<void> checkMarketAndNotify() async {
    debugPrint('Notification Task: Starting checkMarketAndNotify');
    try {
      final prices = await CryptoApiService.fetchRealPrices();
      debugPrint('Notification Task: Prices fetched: ${prices.length}');
      if (prices.isEmpty) {
        debugPrint('Notification Task: Prices empty');
        return;
      }

      // Find the biggest absolute change
      String topSymbol = '';
      double maxChange = 0;
      double actualChange = 0;

      prices.forEach((symbol, data) {
        double change = (data['change24h'] as num).toDouble();
        if (change.abs() > maxChange) {
          maxChange = change.abs();
          topSymbol = symbol;
          actualChange = change;
        }
      });

      debugPrint('Notification Task: Top Symbol: $topSymbol, Change: $actualChange');

      if (topSymbol.isNotEmpty) {
        await _showClickbaitNotification(topSymbol, actualChange);
        debugPrint('Notification Task: Notification shown');
      }
    } catch (e) {
      debugPrint('Notification Task Error: $e');
    }
  }

  static Future<void> _showClickbaitNotification(String symbol, double change) async {
    final String name = AppConfig.cryptoNames[symbol] ?? symbol;
    final bool isUp = change >= 0;
    
    // English Clickbait Message Templates
    final List<String> pumpMessages = [
      "🚀 $name is Mooning! +${change.toStringAsFixed(2)}% gains!",
      "🔥 $name just exploded! Are you missing out on these profits?",
      "💰 $symbol holders are printing money right now! Join them!",
      "⚡ Breaking: $name price is sky-rocketing! Check your balance!",
      "💎 Diamond hands only! $name is reaching new heights!",
      "🌟 Unbelievable! $name has grown by ${change.toStringAsFixed(2)}% in 24h!",
      "📈 The bulls are back! $symbol is leading the market charge!",
      "🤑 Wallet check! $name is making people rich today!",
      "🚀 To the moon! $symbol is unstoppable right now!",
      "🔥 Massive breakout! $name just shattered resistance!",
    ];

    final List<String> dumpMessages = [
      "📉 $name is Crashing! -${change.abs().toStringAsFixed(2)}% drop!",
      "🚨 Market Bloodbath! $symbol is falling fast, act now!",
      "🧨 $name price collapsed! Is this a buy-the-dip opportunity?",
      "😱 $symbol is in a death spiral! Protect your portfolio!",
      "🐻 The bears are winning! $name is down ${change.abs().toStringAsFixed(2)}%!",
      "📉 Panic in the market! $symbol is sinking fast!",
      "💥 $name just hit a new low! Is it over for $symbol?",
      "🔻 Red alert! $name is losing value every second!",
      "🌧️ Stormy weather for $symbol! Price is plummeting!",
      "💔 Heartbreak for holders! $name is diving deep!",
    ];

    final List<String> pumpTitles = [
      "🔥 MARKET ON FIRE!",
      "🚀 TO THE MOON!",
      "💰 PROFIT ALERT!",
      "🌟 AMAZING GAINS!",
      "⚡ BREAKING NEWS!",
    ];

    final List<String> dumpTitles = [
      "🚨 URGENT UPDATE!",
      "📉 MARKET CRASH!",
      "⚠️ DANGER ALERT!",
      "😱 PRICE COLLAPSE!",
      "🔻 BIG DROP!",
    ];

    final random = Random();
    final title = isUp 
        ? pumpTitles[random.nextInt(pumpTitles.length)] 
        : dumpTitles[random.nextInt(dumpTitles.length)];
        
    final message = isUp 
        ? pumpMessages[random.nextInt(pumpMessages.length)]
        : dumpMessages[random.nextInt(dumpMessages.length)];

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'market_updates',
      'Market Updates',
      channelDescription: 'Notifications about big market moves',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF0E76FD),
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      0,
      title,
      message,
      platformDetails,
    );
  }

  static Future<void> showOrderTriggeredNotification({
    required String symbol,
    required bool isTakeProfit,
    required double pnl,
  }) async {
    final String type = isTakeProfit ? "Take Profit" : "Stop Loss";
    final String icon = isTakeProfit ? "💰" : "🛡️";
    final String title = isTakeProfit ? "Target Reached!" : "Position Protected";
    final String message = "$icon Your $type for $symbol was triggered! Net PnL: \$${pnl.toStringAsFixed(2)}";

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'order_triggers',
      'Order Triggers',
      channelDescription: 'Notifications when TP/SL are hit',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF00C853),
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      Random().nextInt(100000),
      title,
      message,
      platformDetails,
    );
  }
}
