class Position {
  final String id;
  final String symbol;
  final bool isLong;
  final double margin;
  final int leverage;
  final double entryPrice;
  final double currentPrice;
  final double? takeProfit;
  final double? stopLoss;

  Position({
    required this.id,
    required this.symbol,
    required this.isLong,
    required this.margin,
    required this.leverage,
    required this.entryPrice,
    required this.currentPrice,
    this.takeProfit,
    this.stopLoss,
  });

  double get unrealizedPnl {
    if (isLong) {
      return ((currentPrice - entryPrice) / entryPrice) * margin * leverage;
    } else {
      return ((entryPrice - currentPrice) / entryPrice) * margin * leverage;
    }
  }

  double get liquidationPrice {
    if (isLong) {
      return entryPrice * (1.0 - 0.9 / leverage);
    } else {
      return entryPrice * (1.0 + 0.9 / leverage);
    }
  }

  Position copyWith({
    double? currentPrice,
    double? takeProfit,
    double? stopLoss,
  }) {
    return Position(
      id: id,
      symbol: symbol,
      isLong: isLong,
      margin: margin,
      leverage: leverage,
      entryPrice: entryPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      takeProfit: takeProfit ?? this.takeProfit,
      stopLoss: stopLoss ?? this.stopLoss,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'isLong': isLong,
      'margin': margin,
      'leverage': leverage,
      'entryPrice': entryPrice,
      'currentPrice': currentPrice,
      'takeProfit': takeProfit,
      'stopLoss': stopLoss,
    };
  }

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      isLong: json['isLong'] as bool,
      margin: (json['margin'] as num).toDouble(),
      leverage: (json['leverage'] as num).toInt(),
      entryPrice: (json['entryPrice'] as num).toDouble(),
      currentPrice: (json['currentPrice'] as num).toDouble(),
      takeProfit: json['takeProfit'] != null ? (json['takeProfit'] as num).toDouble() : null,
      stopLoss: json['stopLoss'] != null ? (json['stopLoss'] as num).toDouble() : null,
    );
  }
}
