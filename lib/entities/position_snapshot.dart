// position_snapshot.dart - ИСПРАВЛЕННАЯ ВЕРСИЯ

class PositionSnapshot {
  final int positionId;
  final String symbol;
  final double holdVol;
  final int positionType;
  final int openType;
  final int state;
  final double frozenVol;
  final double closeVol;
  final double holdAvgPrice;
  final double closeAvgPrice;
  final double openAvgPrice;
  final double liquidatePrice;
  final double oim;
  final int? adlLevel; // исправлено с adLevel на adlLevel
  final double im;
  final double holdFee;
  final double realised;
  final DateTime createTime;
  final DateTime updateTime;

  PositionSnapshot({
    required this.positionId,
    required this.symbol,
    required this.holdVol,
    required this.positionType,
    required this.openType,
    required this.state,
    required this.frozenVol,
    required this.closeVol,
    required this.holdAvgPrice,
    required this.closeAvgPrice,
    required this.openAvgPrice,
    required this.liquidatePrice,
    required this.oim,
    this.adlLevel,
    required this.im,
    required this.holdFee,
    required this.realised,
    required this.createTime,
    required this.updateTime,
  });

  factory PositionSnapshot.fromJson(Map<String, dynamic> json) {
    return PositionSnapshot(
      positionId: json['positionId'] as int,
      symbol: json['symbol'] as String,
      holdVol: (json['holdVol'] as num).toDouble(),
      positionType: json['positionType'] as int,
      openType: json['openType'] as int,
      state: json['state'] as int,
      frozenVol: (json['frozenVol'] as num).toDouble(),
      closeVol: (json['closeVol'] as num).toDouble(),
      holdAvgPrice: (json['holdAvgPrice'] as num).toDouble(),
      closeAvgPrice: (json['closeAvgPrice'] as num).toDouble(),
      openAvgPrice: (json['openAvgPrice'] as num).toDouble(),
      liquidatePrice: (json['liquidatePrice'] as num).toDouble(),
      oim: (json['oim'] as num).toDouble(),
      adlLevel: json['adlLevel'] as int?, // исправлено имя поля
      im: (json['im'] as num).toDouble(),
      holdFee: (json['holdFee'] as num).toDouble(),
      realised: (json['realised'] as num).toDouble(),
      // ИСПРАВЛЕНИЕ: обрабатываем int timestamp
      createTime: _parseDateTime(json['createTime']),
      updateTime: _parseDateTime(json['updateTime']),
    );
  }

  // НОВЫЙ МЕТОД: парсинг DateTime из int или string
  static DateTime _parseDateTime(dynamic timeData) {
    if (timeData is int) {
      // timestamp в миллисекундах
      return DateTime.fromMillisecondsSinceEpoch(timeData);
    } else if (timeData is String) {
      // строковый формат
      return DateTime.parse(timeData);
    } else {
      // fallback
      return DateTime.now();
    }
  }

  @override
  String toString() {
    return 'PositionSnapshot{'
        'positionId: $positionId, '
        'symbol: $symbol, '
        'holdVol: $holdVol, '
        'positionType: $positionType, '
        'openType: $openType, '
        'state: $state, '
        'frozenVol: $frozenVol, '
        'closeVol: $closeVol, '
        'holdAvgPrice: $holdAvgPrice, '
        'closeAvgPrice: $closeAvgPrice, '
        'openAvgPrice: $openAvgPrice, '
        'liquidatePrice: $liquidatePrice, '
        'oim: $oim, '
        'adlLevel: $adlLevel, '
        'im: $im, '
        'holdFee: $holdFee, '
        'realised: $realised, '
        'createTime: $createTime, '
        'updateTime: $updateTime'
        '}';
  }
}
