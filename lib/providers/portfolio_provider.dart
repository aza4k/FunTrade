import 'dart:math';
import 'package:flutter/foundation.dart';
import '../core/services/storage_service.dart';
import '../core/services/notification_service.dart';
import '../models/position.dart';
import '../models/trade_history.dart';

class PortfolioProvider extends ChangeNotifier {
  final StorageService _storageService;

  double _balance = 1000.00;
  List<Position> _openPositions = [];
  List<TradeHistory> _tradeHistory = [];
  String _username = 'gg';

  double get balance => _balance;
  List<Position> get openPositions => List.unmodifiable(_openPositions);
  List<TradeHistory> get tradeHistory => List.unmodifiable(_tradeHistory);
  String get username => _username;

  // Total Equity = Available Balance + Sum of all Unrealized PnLs
  double get totalEquity {
    double openPnL = 0.0;
    for (var pos in _openPositions) {
      openPnL += pos.unrealizedPnl;
    }
    return _balance + openPnL;
  }

  // Statistics calculations
  double get maxDeal {
    if (_tradeHistory.isEmpty) return 0.0;
    return _tradeHistory.map((t) => t.margin).reduce(max);
  }

  double get avgDeal {
    if (_tradeHistory.isEmpty) return 0.0;
    final totalMargin = _tradeHistory.fold(0.0, (sum, t) => sum + t.margin);
    return totalMargin / _tradeHistory.length;
  }

  double get maxProfit {
    if (_tradeHistory.isEmpty) return 0.0;
    final maxPnl = _tradeHistory.map((t) => t.finalPnl).reduce(max);
    return maxPnl > 0 ? maxPnl : 0.0;
  }

  double get maxLoss {
    if (_tradeHistory.isEmpty) return 0.0;
    final minPnl = _tradeHistory.map((t) => t.finalPnl).reduce(min);
    return minPnl < 0 ? minPnl.abs() : 0.0;
  }

  PortfolioProvider(this._storageService) {
    _loadData();
  }

  void _loadData() {
    _balance = _storageService.getBalance();
    _username = _storageService.prefs.getString('funtrade_username') ?? 'gg';
    
    final savedPositions = _storageService.getOpenPositions();
    _openPositions = savedPositions.map((json) => Position.fromJson(json)).toList();

    final savedHistory = _storageService.getTradeHistory();
    _tradeHistory = savedHistory.map((json) => TradeHistory.fromJson(json)).toList();
    
    notifyListeners();
  }

  Future<void> _saveState() async {
    await _storageService.saveBalance(_balance);
    await _storageService.saveOpenPositions(_openPositions.map((p) => p.toJson()).toList());
    await _storageService.saveTradeHistory(_tradeHistory.map((t) => t.toJson()).toList());
  }

  Future<void> updateUsername(String newName) async {
    _username = newName;
    await _storageService.prefs.setString('funtrade_username', newName);
    notifyListeners();
  }

  // Open a new futures position
  bool openPosition({
    required String symbol,
    required bool isLong,
    required double margin,
    required int leverage,
    required double currentPrice,
    double? takeProfit,
    double? stopLoss,
  }) {
    if (margin > _balance) {
      return false; // Insufficient balance
    }

    // Deduct margin immediately
    _balance -= margin;

    final newPosition = Position(
      id: '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
      symbol: symbol,
      isLong: isLong,
      margin: margin,
      leverage: leverage,
      entryPrice: currentPrice,
      currentPrice: currentPrice,
      takeProfit: takeProfit,
      stopLoss: stopLoss,
    );

    _openPositions.add(newPosition);
    _saveState();
    notifyListeners();
    return true;
  }

  // Close an active position manually
  void closePosition(String positionId, double currentPrice) {
    final index = _openPositions.indexWhere((p) => p.id == positionId);
    if (index == -1) return; // Not found

    final position = _openPositions[index];
    _openPositions.removeAt(index);

    // Calculate final PnL at close price
    final updatedPosition = position.copyWith(currentPrice: currentPrice);
    final finalPnl = updatedPosition.unrealizedPnl;

    // Refund margin + PnL to balance
    _balance += (position.margin + finalPnl);

    // Add to history
    final historyItem = TradeHistory(
      id: position.id,
      symbol: position.symbol,
      isLong: position.isLong,
      margin: position.margin,
      leverage: position.leverage,
      entryPrice: position.entryPrice,
      exitPrice: currentPrice,
      finalPnl: finalPnl,
      isLiquidated: false,
      timestamp: DateTime.now(),
    );

    _tradeHistory.insert(0, historyItem);
    _saveState();
    notifyListeners();
  }

  // Real-time price updates & Liquidation Engine
  void updatePrices(Map<String, double> currentPrices) {
    if (_openPositions.isEmpty) return;

    bool stateChanged = false;
    List<Position> remainingPositions = [];

    for (var position in _openPositions) {
      final newPrice = currentPrices[position.symbol];
      if (newPrice == null) {
        remainingPositions.add(position);
        continue;
      }

      // Update position with new current price
      final updatedPosition = position.copyWith(currentPrice: newPrice);

      // Check for Take Profit
      bool tpTriggered = false;
      if (position.takeProfit != null) {
        if (position.isLong) {
          if (newPrice >= position.takeProfit!) tpTriggered = true;
        } else {
          if (newPrice <= position.takeProfit!) tpTriggered = true;
        }
      }

      // Check for Stop Loss
      bool slTriggered = false;
      if (position.stopLoss != null) {
        if (position.isLong) {
          if (newPrice <= position.stopLoss!) slTriggered = true;
        } else {
          if (newPrice >= position.stopLoss!) slTriggered = true;
        }
      }

      // Check for Liquidation: loss reaches or exceeds 90% of margin
      bool liqTriggered = updatedPosition.unrealizedPnl <= -0.9 * position.margin;

      if (tpTriggered || slTriggered || liqTriggered) {
        double exitPrice = newPrice;
        double finalPnl = updatedPosition.unrealizedPnl;
        bool isLiquidated = liqTriggered;

        if (liqTriggered) {
          exitPrice = updatedPosition.liquidationPrice;
          finalPnl = -position.margin;
        } else if (tpTriggered) {
          exitPrice = position.takeProfit!;
          // Re-calculate PnL at exact TP price for accuracy
          finalPnl = position.isLong 
            ? ((exitPrice - position.entryPrice) / position.entryPrice) * position.margin * position.leverage
            : ((position.entryPrice - exitPrice) / position.entryPrice) * position.margin * position.leverage;
          
          NotificationService.showOrderTriggeredNotification(
            symbol: position.symbol,
            isTakeProfit: true,
            pnl: finalPnl,
          );
        } else if (slTriggered) {
          exitPrice = position.stopLoss!;
          // Re-calculate PnL at exact SL price for accuracy
          finalPnl = position.isLong 
            ? ((exitPrice - position.entryPrice) / position.entryPrice) * position.margin * position.leverage
            : ((position.entryPrice - exitPrice) / position.entryPrice) * position.margin * position.leverage;

          NotificationService.showOrderTriggeredNotification(
            symbol: position.symbol,
            isTakeProfit: false,
            pnl: finalPnl,
          );
        }

        // Refund margin + PnL to balance
        _balance += (position.margin + finalPnl);

        // Append to history
        final historyItem = TradeHistory(
          id: position.id,
          symbol: position.symbol,
          isLong: position.isLong,
          margin: position.margin,
          leverage: position.leverage,
          entryPrice: position.entryPrice,
          exitPrice: exitPrice,
          finalPnl: finalPnl,
          isLiquidated: isLiquidated,
          timestamp: DateTime.now(),
        );

        _tradeHistory.insert(0, historyItem);
        stateChanged = true;
      } else {
        remainingPositions.add(updatedPosition);
      }
    }

    if (stateChanged || _openPositions.length != remainingPositions.length) {
      _openPositions = remainingPositions;
      _saveState();
      stateChanged = true;
    } else {
      _openPositions = remainingPositions;
    }

    notifyListeners();
  }

  // Award Earn bonus
  void claimAdReward(double rewardAmount) {
    _balance += rewardAmount;
    _saveState();
    notifyListeners();
  }

  // Reset simulator
  Future<void> resetSimulator() async {
    await _storageService.clearAll();
    await _storageService.prefs.remove('funtrade_username');
    _balance = 1000.00;
    _username = 'gg';
    _openPositions = [];
    _tradeHistory = [];
    await _saveState();
    notifyListeners();
  }
}
