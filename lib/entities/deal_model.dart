class DealModel {
  final double price;
  final double quantity;
  final int tradeSide;
  final int type;
  final int selfTrade;
  final DateTime time;

  DealModel({
    required this.price,
    required this.quantity,
    required this.tradeSide,
    required this.type,
    required this.selfTrade,
    required this.time,
  });

  factory DealModel.fromJson(Map<String, dynamic> json) {
    return DealModel(
      price: (json['p'] as num).toDouble(),
      quantity: (json['v'] as num).toDouble(),
      tradeSide: json['T'] as int,
      type: json['O'] as int,
      selfTrade: json['M'] as int,
      time: DateTime.fromMillisecondsSinceEpoch(json['t'] as int),
    );
  }

  // double get totalSum => type == 2 ? -(quantity * price) : (quantity * price);
  double get totalSum => (quantity * price);

  @override
  String toString() {
    return '${tradeSide == 1 ? 'BUY' : 'SELL'}:$totalSum';
  }
}
