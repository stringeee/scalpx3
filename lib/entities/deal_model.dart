class DealModel {
  final double price;
  final double quantity;
  final String tradeSide;
  final DateTime time;

  DealModel({
    required this.price,
    required this.quantity,
    required this.tradeSide,
    required this.time,
  });

  factory DealModel.fromJson(Map<String, dynamic> json) {
    return DealModel(
      price: double.parse(json['px']),
      quantity: double.parse(json['sz']),
      tradeSide: json['side'] as String,
      time: DateTime.fromMillisecondsSinceEpoch(json['time'] as int),
    );
  }

  // double get totalSum => type == 2 ? -(quantity * price) : (quantity * price);
  double get totalSum => (quantity * price);

  @override
  String toString() {
    return '${tradeSide == 'A' ? 'SELL' : 'BUY'}:$totalSum';
  }
}
