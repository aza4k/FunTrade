class AssetPrice {
  final String symbol;
  final double currentPrice;
  final double change24h;
  final double previousPrice;
  final List<double> priceHistory;

  const AssetPrice({
    required this.symbol,
    required this.currentPrice,
    required this.change24h,
    required this.previousPrice,
    this.priceHistory = const [],
  });

  AssetPrice copyWith({
    double? currentPrice,
    double? change24h,
    double? previousPrice,
    List<double>? priceHistory,
  }) {
    return AssetPrice(
      symbol: symbol,
      currentPrice: currentPrice ?? this.currentPrice,
      change24h: change24h ?? this.change24h,
      previousPrice: previousPrice ?? this.currentPrice,
      priceHistory: priceHistory ?? this.priceHistory,
    );
  }
}
