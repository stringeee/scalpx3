// config_model.dart

class BinanceConfig {
  final bool useBinance;
  final double binanceTakeProfit;
  final double binanceBalanceUsage;

  BinanceConfig({
    required this.useBinance,
    required this.binanceTakeProfit,
    required this.binanceBalanceUsage,
  });

  factory BinanceConfig.fromJson(Map<String, dynamic> json) {
    return BinanceConfig(
      useBinance: json['useBinance'] ?? false,
      binanceTakeProfit: (json['binanceTakeProfit'] ?? 15.0).toDouble(),
      binanceBalanceUsage: (json['binanceBalanceUsage'] ?? 0.09).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'useBinance': useBinance,
      'binanceTakeProfit': binanceTakeProfit,
      'binanceBalanceUsage': binanceBalanceUsage,
    };
  }

  @override
  String toString() {
    return 'BinanceConfig(useBinance: $useBinance, takeProfit: $binanceTakeProfit%, balanceUsage: ${binanceBalanceUsage * 100}%)';
  }
}

class HyperLiquidConfig {
  final bool useHyperLiquid;
  final double hlTakeProfit;
  final double hlBalanceUsage;

  HyperLiquidConfig({
    required this.useHyperLiquid,
    required this.hlTakeProfit,
    required this.hlBalanceUsage,
  });

  factory HyperLiquidConfig.fromJson(Map<String, dynamic> json) {
    return HyperLiquidConfig(
      useHyperLiquid: json['useHyperLiquid'] ?? true,
      hlTakeProfit: (json['hlTakeProfit'] ?? 20.0).toDouble(),
      hlBalanceUsage: (json['hlBalanceUsage'] ?? 0.1).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'useHyperLiquid': useHyperLiquid,
      'hlTakeProfit': hlTakeProfit,
      'hlBalanceUsage': hlBalanceUsage,
    };
  }

  @override
  String toString() {
    return 'HyperLiquidConfig(useHyperLiquid: $useHyperLiquid, takeProfit: $hlTakeProfit%, balanceUsage: ${hlBalanceUsage * 100}%)';
  }
}

class ProfileConfig {
  final String user;
  final String nativeMexcApiKey;
  final String secretKey;
  final String webKey;
  final BinanceConfig binance;
  final HyperLiquidConfig hyperLiquid;

  ProfileConfig({
    required this.user,
    required this.nativeMexcApiKey,
    required this.secretKey,
    required this.webKey,
    required this.binance,
    required this.hyperLiquid,
  });

  factory ProfileConfig.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] ?? json;

    return ProfileConfig(
      user: profile['user'] ?? 'alex',
      nativeMexcApiKey: profile['nativeMexcApiKey'] ?? '',
      secretKey: profile['secretKey'] ?? '',
      webKey: profile['webKey'] ?? '',
      binance: BinanceConfig.fromJson(profile['binance'] ?? {}),
      hyperLiquid: HyperLiquidConfig.fromJson(profile['hyperLiquid'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile': {
        'user': user,
        'nativeMexcApiKey': nativeMexcApiKey,
        'secretKey': secretKey,
        'webKey': webKey,
        'binance': binance.toJson(),
        'hyperLiquid': hyperLiquid.toJson(),
      },
    };
  }

  @override
  String toString() {
    return 'ProfileConfig(\n'
        '  user: $user\n'
        '  binance: $binance\n'
        '  hyperLiquid: $hyperLiquid\n'
        ')';
  }
}
