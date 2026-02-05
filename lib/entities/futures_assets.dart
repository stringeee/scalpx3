class FuturesAssets {
  final String currency;
  final double availableBalance;
  final double cashBalance;
  final double equity;
  final bool success;
  final bool isTestnet;

  FuturesAssets({
    required this.currency,
    required this.availableBalance,
    required this.cashBalance,
    required this.equity,
    required this.success,
    required this.isTestnet,
  });
}
