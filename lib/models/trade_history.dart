class TradeHistory {
  final String id;
  final String symbol;
  final bool isLong;
  final double margin;
  final int leverage;
  final double entryPrice;
  final double exitPrice;
  final double finalPnl;
  final bool isLiquidated;
  final DateTime timestamp;

  TradeHistory({
    required this.id,
    required this.symbol,
    required this.isLong,
    required this.margin,
    required this.leverage,
    required this.entryPrice,
    required this.exitPrice,
    required this.finalPnl,
    required this.isLiquidated,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'isLong': isLong,
      'margin': margin,
      'leverage': leverage,
      'entryPrice': entryPrice,
      'exitPrice': exitPrice,
      'finalPnl': finalPnl,
      'isLiquidated': isLiquidated,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory TradeHistory.fromJson(Map<String, dynamic> json) {
    return TradeHistory(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      isLong: json['isLong'] as bool,
      margin: (json['margin'] as num).toDouble(),
      leverage: (json['leverage'] as num).toInt(),
      entryPrice: (json['entryPrice'] as num).toDouble(),
      exitPrice: (json['exitPrice'] as num).toDouble(),
      finalPnl: (json['finalPnl'] as num).toDouble(),
      isLiquidated: json['isLiquidated'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
