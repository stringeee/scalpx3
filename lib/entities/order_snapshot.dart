// order_snapshot.dart - ИСПРАВЛЕННАЯ ВЕРСИЯ

class OrderSnapshot {
  final int ordered;
  final String symbol;
  final int positionId;
  final double price;
  final double vol;
  final int leverage;
  final int side;
  final int category;
  final int orderType;
  final double dealWgPrice;
  final double dealVol;
  final double orderMargin;
  final double usedMargin;
  final double takerFee;
  final double makerFee;
  final double profit;
  final String feeCurrency;
  final int openType;
  final int state;
  final int errorCode;
  final String externalDid; // externalOid в данных
  final DateTime createTime;
  final DateTime updateTime;

  OrderSnapshot({
    required this.ordered,
    required this.symbol,
    required this.positionId,
    required this.price,
    required this.vol,
    required this.leverage,
    required this.side,
    required this.category,
    required this.orderType,
    required this.dealWgPrice,
    required this.dealVol,
    required this.orderMargin,
    required this.usedMargin,
    required this.takerFee,
    required this.makerFee,
    required this.profit,
    required this.feeCurrency,
    required this.openType,
    required this.state,
    required this.errorCode,
    required this.externalDid,
    required this.createTime,
    required this.updateTime,
  });

  factory OrderSnapshot.fromJson(Map<String, dynamic> json) {
    print((json['symbol'] ?? ''));

    return OrderSnapshot(
      ordered: (json['ordered'] ?? 0) as int,
      symbol: (json['symbol'] ?? '') as String,
      positionId: (json['positionId'] ?? 0) as int,
      price: ((json['price'] ?? 0) as num).toDouble(),
      vol: ((json['vol'] ?? 0) as num).toDouble(),
      leverage: (json['leverage'] ?? 0) as int,
      side: (json['side'] ?? 0) as int,
      category: (json['category'] ?? 0) as int,
      orderType: (json['orderType'] ?? 0) as int,
      dealWgPrice: ((json['deal/wgPrice'] ?? 0) as num).toDouble(),
      dealVol: ((json['dealVol'] ?? 0) as num).toDouble(),
      orderMargin: ((json['orderMargin'] ?? 0) as num).toDouble(),
      usedMargin: ((json['usedMargin'] ?? 0) as num).toDouble(),
      takerFee: ((json['takerFee'] ?? 0) as num).toDouble(),
      makerFee: ((json['makerFee'] ?? 0) as num).toDouble(),
      profit: ((json['profit'] ?? 0) as num).toDouble(),
      feeCurrency: (json['feeCurrency'] ?? 'USDT') as String,
      openType: (json['openType'] ?? 0) as int,
      state: (json['state'] ?? 0) as int,
      errorCode: (json['errorCode'] ?? 0) as int,
      // ИСПРАВЛЕНИЕ: externalOid вместо externalDid
      externalDid: (json['externalOid'] ?? json['externalDid'] ?? '') as String,
      createTime: _parseDateTime(json['createTime']),
      updateTime: _parseDateTime(json['updateTime']),
    );
  }

  // ДОБАВЛЯЕМ метод парсинга DateTime
  static DateTime _parseDateTime(dynamic timeData) {
    if (timeData is int) {
      return DateTime.fromMillisecondsSinceEpoch(timeData);
    } else if (timeData is String) {
      return DateTime.parse(timeData);
    } else {
      return DateTime.now();
    }
  }

  @override
  String toString() {
    return 'OrderSnapshot{'
        'ordered: $ordered, '
        'symbol: $symbol, '
        'positionId: $positionId, '
        'price: $price, '
        'vol: $vol, '
        'leverage: $leverage, '
        'side: $side, '
        'category: $category, '
        'orderType: $orderType, '
        'dealWgPrice: $dealWgPrice, '
        'dealVol: $dealVol, '
        'orderMargin: $orderMargin, '
        'usedMargin: $usedMargin, '
        'takerFee: $takerFee, '
        'makerFee: $makerFee, '
        'profit: $profit, '
        'feeCurrency: $feeCurrency, '
        'openType: $openType, '
        'state: $state, '
        'errorCode: $errorCode, '
        'externalDid: $externalDid, '
        'createTime: $createTime, '
        'updateTime: $updateTime'
        '}';
  }
}
