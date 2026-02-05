import 'dart:math';

import 'package:injectable/injectable.dart';
import 'package:scalpx3/entities/config_model.dart';

@singleton
class Program {
  ProfileConfig? _config;

  ProfileConfig? get config => _config;

  void setConfig(ProfileConfig config) {
    _config = config;
    print('[PROGRAM] Config set for user: ${config.user}');
  }

  double getContractSize(String symbol) {
    // Для USDT пар размер контракта обычно = 1
    // Для COIN-M пар (BTCUSD, ETHUSD) может быть другим
    final contractSizes = {
      "BONK_USDT": 1000000,
      "TRUMPOFFICIAL_USDT": 0.1,
      "BNB_USDT": 0.01,
      "PUMPFUN_USDT": 100,
      "TAO_USDT": 0.01,
      "ASTER_USDT": 1,
      "XPL_USDT": 1,
      "ENA_USDT": 10,
      "HYPE_USDT": 0.1,
      "ADA_USDT": 1,
      "PEPE_USDT": 10000000,
      "DOGE_USDT": 100,
      "LINK_USDT": 0.1,
      "XRP_USDT": 1,
      "ZEC_USDT": 0.01,
      "SUI_USDT": 1,
      "ETH_USDT": 0.01,
      "AVAX_USDT": 0.1,
      "SOL_USDT": 0.1,
      "BTC_USDT": 0.0001,
      "MATIC_USDT": 1,
      "DOT_USDT": 0.1,
      "LTC_USDT": 0.01,
      "BCH_USDT": 0.01,
      "ATOM_USDT": 0.1,
      "ETC_USDT": 0.1,
      "XLM_USDT": 10,
      "XMR_USDT": 0.01,
      "EOS_USDT": 0.1,
      "TRX_USDT": 10,
      "XTZ_USDT": 0.1,
      "ALGO_USDT": 1,
      "DASH_USDT": 0.01,
      "SHIB_USDT": 1000,
      "FLOKI_USDT": 100000,
      "MEME_USDT": 100,
      "UNI_USDT": 0.1,
      "AAVE_USDT": 0.01,
      "COMP_USDT": 0.01,
      "MKR_USDT": 0.01,
      "SNX_USDT": 0.1,
      "ARB_USDT": 1,
      "OP_USDT": 1,
      "FET_USDT": 10,
      "AGIX_USDT": 10,
      "OCEAN_USDT": 1,
      "SAND_USDT": 1,
      "MANA_USDT": 1,
      "ENJ_USDT": 1,
      "GALA_USDT": 10,
      "BAND_USDT": 0.1,
      "TRB_USDT": 0.1,
      "FIL_USDT": 0.01,
      "AR_USDT": 0.1,
      "XAUT_USDT": 0.001,
    };

    return (contractSizes[symbol] ?? 1.0) + 0.0; // По умолчанию 1
  }

  int leveragePerCoin(String symbol) =>
      {
        "BONK_USDT": 100,
        "TRUMPOFFICIAL_USDT": 50,
        "BNB_USDT": 100,
        "PUMPFUN_USDT": 100,
        "TAO_USDT": 100,
        "ASTER_USDT": 100,
        "XPL_USDT": 100,
        "ENA_USDT": 100,
        "HYPE_USDT": 100,
        "ADA_USDT": 100,
        "kPEPE_USDT": 100,
        "DOGE_USDT": 100,
        "LINK_USDT": 100,
        "XRP_USDT": 100,
        "ZEC_USDT": 100,
        "SUI_USDT": 100,
        "ETH_USDT": 100,
        "AVAX_USDT": 100,
      }[symbol] ??
      100;

  static final Map<String, int> decimalsPerCoin = {
    "kBONK": 6,
    "TRUMP": 3,
    "BNB": 1,
    "PUMPFUN": 6,
    "TAO": 1,
    "ASTER": 4,
    "XPL": 4,
    "ENA": 4,
    "HYPE": 3,
    "ADA": 4,
    "PEPE": 9,
    "DOGE": 5,
    "LINK": 3,
    "XRP": 4,
    "ZEC": 2,
    "@107": 4,
    "SUI": 4,
    "ETH": 2,
    "AVAX": 3,
    "SOL": 2,
    "LTC": 2,
    "XAUT": 1,
  };

  // External ID generator
  static int _extSeq = 0;
  static String newExternalId(String mexcSymbol, String tag) {
    final baseSym = mexcSymbol.split('_')[0].toUpperCase();
    final now = DateTime.now().toUtc();
    final t =
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';

    final seq = ++_extSeq;
    final s36 = _toBase36(seq);

    var raw = 'HL${baseSym.substring(0, min(4, baseSym.length))}$t$s36$tag';
    if (raw.length > 32) raw = raw.substring(0, 32);

    return raw;
  }

  static String _toBase36(int x) {
    const alphabet = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (x <= 0) return '0';
    final sb = StringBuffer();
    while (x > 0) {
      sb.write(alphabet[x % 36]);
      x ~/= 36;
    }
    return sb.toString().split('').reversed.join();
  }

  static final Map<String, double> thresholds = {
    "kBONK": 1000000.0,
    "TRUMP": 1200000.0,
    "BNB": 1000000.0,
    "PUMP": 1500000.0,
    "ASTER": 1000000.0,
    "XPL": 1000000.0,
    "ENA": 1000000.0,
    "ADA": 1000000.0,
    "DOGE": 1500000.0,
    "kPEPE": 1000000.0,
    "LINK": 1000000.0,
    "XRP": 3500000.0,
    "ZEC": 800000.0,
    "SUI": 1000000.0,
    "AVAX": 1000000.0,
    "TAO": 1000000.0,
    "LTC": 1000000.0,
    "HYPE": 2500000.0,
  };

  static final Map<String, double> binanceThresholds = {
    "BONK": 1000000,
    "TRUMP": 1200000,
    "BNB": 6000000,
    "PUMP": 1500000,
    "TAO": 1200000,
    "ASTER": 1200000,
    "XPL": 1000000,
    "ENA": 1200000,
    "HYPE": 2500000,
    "ADA": 2000000,
    "PEPE": 1000000,
    "DOGE": 3000000,
    "LINK": 2000000,

    "XRP": 3500000,
    "ZEC": 1200000,
    "SUI": 1200000,
    "ETH": 30000000,
    "AVAX": 2000000,
    "BTC": 30000000,
    "SOL": 5000000,
    "ARB": 1500000,
    "OP": 1000000,
    "INJ": 1000000,
    "UNI": 1500000,
    "LDO": 1200000,
    "SEI": 1000000,
    "FXS": 1000000,
    "STX": 800000,
  };

  double usdPerDeal(String mx, double currentBalance, String exchange) {
    // final usdAmounts = {'HYPE_USDT': 20, 'PUMPFUN_USDT': 20, 'XRP_USDT': 20};
    // return (usdAmounts[mx] ?? 20) + 0.0; // $0.20 на сделку по умолчанию

    if (_config != null) {
      if (exchange == 'BINANCE' && _config!.binance.useBinance) {
        return currentBalance * _config!.binance.binanceBalanceUsage;
      } else if (exchange == 'HYPERLIQUID' &&
          _config!.hyperLiquid.useHyperLiquid) {
        return currentBalance * _config!.hyperLiquid.hlBalanceUsage;
      }
    }
    return 1;
  }

  double minVolBySymbol(String mx) {
    final minVols = {
      'HYPE_USDT': 0.1,
      'PUMPFUN_USDT': 1.0,
      'BTC_USDT': 0.001,
      'ETH_USDT': 0.01,
      'XAUT_USDT': 0.0001,
      'XRP_USDT': 1.0,
      'PEPE_USDT': 0.000001,
    };
    return minVols[mx] ?? 1.0;
  }

  double qtyStepBySymbol(String mx) {
    final steps = {
      'BTC_USDT': 0.001,
      'ETH_USDT': 0.01,
      'BNB_USDT': 0.01,
      'SOL_USDT': 0.01,
      'ADA_USDT': 1.0,
      'XRP_USDT': 1.0,
      'DOGE_USDT': 1.0,
      'MATIC_USDT': 1.0,
      'DOT_USDT': 0.1,
      'LTC_USDT': 0.01,
      'LINK_USDT': 0.1,
      'AVAX_USDT': 0.1,
      'ETC_USDT': 0.1,
      'XLM_USDT': 1.0,
      'XMR_USDT': 0.01,
      'EOS_USDT': 1.0,
      'TRX_USDT': 1.0,
      'XTZ_USDT': 1.0,
      'ALGO_USDT': 1.0,
      'ZEC_USDT': 0.01,
      'DASH_USDT': 0.01,
      'SUI_USDT': 1.0,
      'ENA_USDT': 0.1,
      'HYPE_USDT': 0.01,
      'PUMPFUN_USDT': 1.0,
      'BONK_USDT': 1.0,
      'PEPE_USDT': 1.0,
      'TRUMPOFFICIAL_USDT': 0.1,
      'SHIB_USDT': 1.0,
      'FLOKI_USDT': 1.0,
      'MEME_USDT': 1.0,
      'XAUT_USDT': 0.001,
      'TAO_USDT': 0.01,
      'ASTER_USDT': 1.0,
      'XPL_USDT': 1.0,

      'UNI_USDT': 0.1,
      'AAVE_USDT': 0.01,
      'COMP_USDT': 0.01,
      'MKR_USDT': 0.001,
      'SNX_USDT': 0.1,

      'ARB_USDT': 1.0,
      'OP_USDT': 1.0,

      'FET_USDT': 1.0,
      'AGIX_USDT': 1.0,
      'OCEAN_USDT': 1.0,

      'BAND_USDT': 0.1,
      'TRB_USDT': 0.01,
    };

    final step = steps[mx];
    if (step == null) {
      print(
        '[QTY_STEP_WARNING] No quantity step found for $mx, using default 1.0',
      );
      return 1.0;
    }

    return step;
  }

  int getSymbolQuantityPrecision(String symbol) {
    final precisions = {
      'HYPE_USDT': 0,
      'PUMPFUN_USDT': 0,
      'BONK_USDT': 0,
      'TRUMPOFFICIAL': 1,
      'BNB_USDT': 2,
      'TAO_USDT': 2,
      'ASTER_USDT': 0,
      'XPL_USDT': 0,
      'ENA_USDT': 1,
      'ADA_USDT': 0,
      'SOL_USDT': 2,
      'kPEPE_USDT': 0,
      'DOGE_USDT': 0,
      'LINK_USDT': 1,
      'XRP_USDT': 0,
      'ZEC_USDT': 2,
      'XAUT_USDT': 1,
      'SUI_USDT': 0,
      'ETH_USDT': 2,
      'AVAX_USDT': 1,
    };

    return precisions[symbol] ?? 1;
  }

  String mapToMexcSymbol(String hlCoin) {
    String c = hlCoin;

    if (c.startsWith('k')) c = c.substring(1);
    if (c.toUpperCase() == 'PUMP') return 'PUMPFUN_USDT';
    if (c.toUpperCase() == 'TRUMP') return 'TRUMPOFFICIAL';
    return '${c}_USDT';
  }

  String mapToTrackerSymbol(String hlCoin) {
    String c = hlCoin;

    if (c.startsWith('k')) c = c.substring(1);
    if (c.toUpperCase() == 'PUMP') return 'PUMPFUN';
    if (c.toUpperCase() == 'TRUMP') return 'TRUMPOFFICIAL';
    return c;
  }
}
