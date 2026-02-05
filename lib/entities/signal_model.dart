class SignalModel {
  final SignalEnum type;
  final double power;
  final double aPrice;
  final DateTime aTime;

  SignalModel({
    required this.type,
    required this.power,
    required this.aPrice,
    required this.aTime,
  });

  @override
  String toString() {
    return '${type.name.toUpperCase()}: $aPrice\nPower: $power';
  }
}

enum SignalEnum { short, long }
