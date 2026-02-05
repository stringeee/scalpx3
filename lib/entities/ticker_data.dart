class TickerData {
  final double price;
  final double volume;
  final bool isBuyerMaker;
  final DateTime timestamp;

  TickerData({
    required this.price,
    required this.volume,
    required this.isBuyerMaker,
    required this.timestamp,
  });
}
