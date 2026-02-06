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
    String colorLine = type == SignalEnum.long ? '\x1B[32m' : '\x1B[31m';

    return '$colorLine${'=' * 60}\n$colorLine${type.name.toUpperCase()}: $aPrice\n${colorLine}Power: $power\n$colorLine[$aTime]\n$colorLine${'=' * 60}\x1B[0m';
    // return '\x1B[31mHello\x1B[0m';
  }
}

enum SignalEnum { short, long }
