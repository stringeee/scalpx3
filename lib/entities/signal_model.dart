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
    return '\n\n${'=' * 60}\n${type.name.toUpperCase()}: $aPrice\nPower: $power\n[$aTime]\n${'=' * 60}';
  }
}

enum SignalEnum { short, long }
