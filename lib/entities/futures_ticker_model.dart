class FuturesTicker {
  final int contractId;
  final String symbol;
  final double lastPrice;
  final double bid1;
  final double ask1;
  final double volume24;
  final double amount24;
  final double holdVol;
  final double lower24Price;
  final double high24Price;
  final double riseFallRate;
  final double riseFallValue;
  final double indexPrice;
  final double fairPrice;
  final double fundingRate;
  final double maxBidPrice;
  final double minAskPrice;
  final int timestamp;
  final bool success;
  final bool isTestnet;

  FuturesTicker({
    required this.contractId,
    required this.symbol,
    required this.lastPrice,
    required this.bid1,
    required this.ask1,
    required this.volume24,
    required this.amount24,
    required this.holdVol,
    required this.lower24Price,
    required this.high24Price,
    required this.riseFallRate,
    required this.riseFallValue,
    required this.indexPrice,
    required this.fairPrice,
    required this.fundingRate,
    required this.maxBidPrice,
    required this.minAskPrice,
    required this.timestamp,
    required this.success,
    required this.isTestnet,
  });

  factory FuturesTicker.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};

    return FuturesTicker(
      contractId: (data['contractId'] ?? 0).toInt(),
      symbol: data['symbol'] ?? '',
      lastPrice: double.parse((data['lastPrice'] ?? 0).toString()),
      bid1: double.parse((data['bid1'] ?? 0).toString()),
      ask1: double.parse((data['ask1'] ?? 0).toString()),
      volume24: double.parse((data['volume24'] ?? 0).toString()),
      amount24: double.parse((data['amount24'] ?? 0).toString()),
      holdVol: double.parse((data['holdVol'] ?? 0).toString()),
      lower24Price: double.parse((data['lower24Price'] ?? 0).toString()),
      high24Price: double.parse((data['high24Price'] ?? 0).toString()),
      riseFallRate: double.parse((data['riseFallRate'] ?? 0).toString()),
      riseFallValue: double.parse((data['riseFallValue'] ?? 0).toString()),
      indexPrice: double.parse((data['indexPrice'] ?? 0).toString()),
      fairPrice: double.parse((data['fairPrice'] ?? 0).toString()),
      fundingRate: double.parse((data['fundingRate'] ?? 0).toString()),
      maxBidPrice: double.parse((data['maxBidPrice'] ?? 0).toString()),
      minAskPrice: double.parse((data['minAskPrice'] ?? 0).toString()),
      timestamp: (data['timestamp'] ?? 0).toInt(),
      success: json['success'] ?? false,
      isTestnet: json['is_testnet'] ?? false,
    );
  }

  @override
  String toString() {
    return 'FuturesTicker{symbol: $symbol, lastPrice: $lastPrice, bid1: $bid1, ask1: $ask1, fairPrice: $fairPrice}';
  }
}
