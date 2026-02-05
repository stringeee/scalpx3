// lib/models/order_book.dart
class OrderBook {
  final Map<double, double> bids = {}; // цена -> объем
  final Map<double, double> asks = {};
  double lastUpdateId = 0;
  DateTime lastUpdated = DateTime.now();

  void processSnapshot(Map<String, dynamic> snapshot) {
    bids.clear();
    asks.clear();

    final bidsList = snapshot['bids'] as List<dynamic>;
    final asksList = snapshot['asks'] as List<dynamic>;

    for (final bid in bidsList) {
      final price = double.parse(bid[0] as String);
      final volume = double.parse(bid[1] as String);
      bids[price] = volume;
    }

    for (final ask in asksList) {
      final price = double.parse(ask[0] as String);
      final volume = double.parse(ask[1] as String);
      asks[price] = volume;
    }

    lastUpdateId = (snapshot['lastUpdateId'] as num).toDouble();
    lastUpdated = DateTime.now();

    // print(
    //   '✅ OrderBook snapshot loaded: ${bids.length} bids, ${asks.length} asks',
    // );
  }

  void processUpdate(Map<String, dynamic> update) {
    final u = update['u'] as num;
    final U = update['U'] as num;

    // Проверяем последовательность обновлений (важно для HFT!)
    if (u <= lastUpdateId) {
      // Пропускаем устаревшее обновление
      return;
    }

    // Обновляем биды
    final bidsUpdate = update['b'] as List<dynamic>;
    for (final bid in bidsUpdate) {
      final price = double.parse(bid[0] as String);
      final volume = double.parse(bid[1] as String);

      if (volume == 0) {
        bids.remove(price);
      } else {
        bids[price] = volume;
      }
    }

    // Обновляем аски
    final asksUpdate = update['a'] as List<dynamic>;
    for (final ask in asksUpdate) {
      final price = double.parse(ask[0] as String);
      final volume = double.parse(ask[1] as String);

      if (volume == 0) {
        asks.remove(price);
      } else {
        asks[price] = volume;
      }
    }

    lastUpdateId = u.toDouble();
    lastUpdated = DateTime.now();
  }

  double getBestBid() {
    if (bids.isEmpty) return 0;
    return bids.keys.reduce((a, b) => a > b ? a : b);
  }

  double getBestAsk() {
    if (asks.isEmpty) return 0;
    return asks.keys.reduce((a, b) => a < b ? a : b);
  }

  double getMidPrice() {
    final bestBid = getBestBid();
    final bestAsk = getBestAsk();
    if (bestBid == 0 || bestAsk == 0) return 0;
    return (bestBid + bestAsk) / 2;
  }

  double calculateImbalance(int depthLevels) {
    final sortedBids = bids.keys.toList()..sort((a, b) => b.compareTo(a));
    final sortedAsks = asks.keys.toList()..sort();

    double bidVolume = 0;
    double askVolume = 0;

    for (int i = 0; i < depthLevels && i < sortedBids.length; i++) {
      bidVolume += bids[sortedBids[i]]!;
    }

    for (int i = 0; i < depthLevels && i < sortedAsks.length; i++) {
      askVolume += asks[sortedAsks[i]]!;
    }

    if (bidVolume + askVolume == 0) return 0;
    return (bidVolume - askVolume) / (bidVolume + askVolume);
  }

  @override
  String toString() {
    return 'OrderBook(bestBid: ${getBestBid()}, bestAsk: ${getBestAsk()}, spread: ${getBestAsk() - getBestBid()})';
  }
}
