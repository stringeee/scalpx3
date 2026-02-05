import 'package:scalpx3/entities/futures_assets.dart';
import 'package:scalpx3/entities/futures_ticker_model.dart';
import '../api/create_futures_order_request.dart';

abstract class IExchangeApi {
  Future<FuturesAssets> getFuturesAssets(String currency);
  Future<int> createFuturesOrder(CreateFuturesOrderRequest req);
  Future<void> cancelFuturesOrderWithExternalId(
    String symbol,
    String externalId,
  );
  Future<double> getFairPrice(String mexcSymbol);
  Future<FuturesTicker> getFuturesTicker(String symbol); // НОВЫЙ МЕТОД
  void dispose();
}
