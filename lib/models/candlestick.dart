class Candlestick {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;

  const Candlestick({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  factory Candlestick.fromJson(List<dynamic> json) {
    // Binance kline array format:
    // [
    //   1499040000000,      // Open time
    //   "0.01634790",       // Open
    //   "0.80000000",       // High
    //   "0.01575800",       // Low
    //   "0.01577100",       // Close
    //   ...
    // ]
    return Candlestick(
      time: DateTime.fromMillisecondsSinceEpoch(json[0] as int),
      open: double.parse(json[1].toString()),
      high: double.parse(json[2].toString()),
      low: double.parse(json[3].toString()),
      close: double.parse(json[4].toString()),
    );
  }
}
