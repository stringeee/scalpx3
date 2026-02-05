import 'package:scalpx3/injector/injector.dart';
import 'package:scalpx3/shared/program.dart';

double calculateStopLossPrice({
  required bool isBid,
  required double price,
  required int leverage,
  required double lossPercent,
}) {
  final priceChangePercent = lossPercent / leverage;

  final stopLossPrice = isBid
      ? price *
            (1 - priceChangePercent / 100) // Для лонга стоп ниже
      : price * (1 + priceChangePercent / 100); // Для шорта стоп выше

  print(
    '[SL_CALC] ${isBid ? 'LONG' : 'SHORT'}, price: $price, '
    'lev: $leverage, loss: ${lossPercent}% -> '
    'SL: $stopLossPrice (${priceChangePercent.toStringAsFixed(3)}%)',
  );

  return stopLossPrice;
}

double calculateTakeProfitPrice({
  required bool isBid,
  required double price,
  required int leverage,
  required double profitPercent, // Процент прибыли (например 15.0 для 15%)
}) {
  // Рассчитываем изменение цены в процентах
  final priceChangePercent = profitPercent / leverage;

  // Для лонга: цена увеличивается, для шорта: уменьшается
  final takeProfitPrice = isBid
      ? price * (1 + priceChangePercent / 100)
      : price * (1 - priceChangePercent / 100);

  print(
    '[TAKE_PROFIT_CALC] isBid: $isBid, price: $price, '
    'leverage: $leverage, profitPercent: ${profitPercent}% -> '
    'priceChange: ${priceChangePercent.toStringAsFixed(4)}% -> '
    'TP: $takeProfitPrice',
  );

  return takeProfitPrice;
}

double takeProfitPriceCalc({
  required bool isBinance,
  required int leverage,
  required double price,
  required bool isBid,
}) {
  double? takeProfitPrice;

  takeProfitPrice = calculateTakeProfitPrice(
    isBid: isBid,
    price: price,
    leverage: leverage,
    profitPercent: isBinance
        ? (injector<Program>().config?.binance.binanceTakeProfit ?? 15.0)
        : (injector<Program>().config?.hyperLiquid.hlTakeProfit ?? 15.0),
    // profitPercent: 5,
  );

  return takeProfitPrice;
}
