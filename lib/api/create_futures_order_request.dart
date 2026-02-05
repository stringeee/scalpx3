import 'package:scalpx3/shared/program.dart';
import 'package:scalpx3/shared/take_profit_price_calc.dart';

class CreateFuturesOrderRequest {
  final String symbol;
  final double price;
  final int type; // 1=Limit, 5=Market
  final int openType; // 1=Isolated, 2=Cross
  final int side; // 1 Long, 2 Close Short, 3 Short, 4 Close Long
  final double vol;
  final String externalId;
  final bool? reduceOnly;
  final int? leverage;
  final bool isBid; // Добавляем флаг для определения стороны
  final bool isBinance;

  CreateFuturesOrderRequest({
    required this.isBinance,
    required this.symbol,
    required this.price,
    required this.type,
    required this.openType,
    required this.side,
    required this.vol,
    required this.externalId,
    this.reduceOnly,
    this.leverage,
    required this.isBid, // Обязательный параметр
  });

  Map<String, dynamic> toJson() {
    // ТЕЙК-ПРОФИТ (как у вас было)

    // ТЕЙК-ПРОФИТ (15% вместо 25%)
    final double takeProfitPrice = takeProfitPriceCalc(
      isBinance: isBinance,
      leverage: 100,
      price: price,
      isBid: isBid,
    );

    // СТОП-ЛОСС (новая логика для 50% потери)
    final stopLossPrice = calculateStopLossPrice(
      isBid: isBid,
      price: price,
      leverage: 100,
      lossPercent: 20,
    ); // 0.50% для 100x
    // isBid ? price - 1 : price + 1;

    try {
      var res = {
        'symbol': symbol,
        'price': price.toStringAsFixed(
          Program.decimalsPerCoin[symbol.split('_').first]!,
        ),
        'type': type,
        'open_type': openType,
        'side': side,
        'stop_loss_price': double.parse(
          stopLossPrice.toStringAsFixed(
            Program.decimalsPerCoin[symbol.split('_').first]!,
          ),
        ),
        'take_profit_price': double.parse(
          takeProfitPrice.toStringAsFixed(
            Program.decimalsPerCoin[symbol.split('_').first]!,
            // 4,
          ),
        ),
        'take_profit_trend': 1,
        'stop_loss_trend': 1,
        'vol': vol,
        'external_id': externalId,
        // 'leverage': leverage,
        'leverage': 20,
      };

      print('[ORDER] $res');

      return res;
    } catch (e) {
      print(
        'zalupa symbol $symbol price $price type $type openType $openType side $side vol $vol externalId $externalId reduceOnly $reduceOnly leverage $leverage isBid $isBid',
      );
      rethrow;
    }
  }
}
