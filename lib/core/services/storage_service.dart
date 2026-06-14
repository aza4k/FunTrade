import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/config.dart';

class StorageService {
  static const String _keyBalance = 'funtrade_balance';
  static const String _keyPositions = 'funtrade_positions';
  static const String _keyHistory = 'funtrade_history';

  final SharedPreferences _prefs;

  SharedPreferences get prefs => _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  double getBalance() {
    return _prefs.getDouble(_keyBalance) ?? AppConfig.initialBalance;
  }

  Future<void> saveBalance(double balance) async {
    await _prefs.setDouble(_keyBalance, balance);
  }

  List<Map<String, dynamic>> getOpenPositions() {
    final rawJson = _prefs.getString(_keyPositions);
    if (rawJson == null) return [];
    try {
      final decoded = jsonDecode(rawJson) as List<dynamic>;
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveOpenPositions(List<Map<String, dynamic>> positions) async {
    final rawJson = jsonEncode(positions);
    await _prefs.setString(_keyPositions, rawJson);
  }

  List<Map<String, dynamic>> getTradeHistory() {
    final rawJson = _prefs.getString(_keyHistory);
    if (rawJson == null) return [];
    try {
      final decoded = jsonDecode(rawJson) as List<dynamic>;
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTradeHistory(List<Map<String, dynamic>> trades) async {
    final rawJson = jsonEncode(trades);
    await _prefs.setString(_keyHistory, rawJson);
  }

  Future<void> clearAll() async {
    await _prefs.remove(_keyBalance);
    await _prefs.remove(_keyPositions);
    await _prefs.remove(_keyHistory);
  }
}
