import 'dart:async';
import 'dart:math' as math;

import 'package:scalpx3/balance_manager.dart';
import 'package:scalpx3/entities/order_snapshot.dart';
import 'package:scalpx3/entities/position_snapshot.dart';
import 'package:scalpx3/injector/injector.dart';
import 'package:scalpx3/interface/iorder_book_source.dart';
import 'package:scalpx3/shared/program.dart';

import 'interface/i_exchange_api.dart';
import 'api/create_futures_order_request.dart';

class ExecutionManager {
  final IExchangeApi _api;
  final double Function(String) _minVolBySymbol;
  final double Function(String) _qtyStepBySymbol;
  final BalanceManager _balanceManager;

  // Активные ордера
  final Map<String, List<OrderSnapshot>> _activeOrders = {};

  // Активные позиции
  final Map<String, List<PositionSnapshot>> _activePositions = {};

  Map<String, List<PositionSnapshot>> get activePositions =>
      Map.from(_activePositions);

  Map<String, List<OrderSnapshot>> get activeOrders => Map.from(_activeOrders);

  final Map<String, Timer> _orderCheckTimers = {};

  int get activePositionsCount => _activePositions.length;
  int get activeOrdersCount => _activeOrders.length;

  ExecutionManager({
    required IExchangeApi api,
    required double Function(String) minVolBySymbol,
    required double Function(String) qtyStepBySymbol,
    required BalanceManager balanceManager,
  }) : _api = api,
       //  _tickBySymbol = tickBySymbol,
       _minVolBySymbol = minVolBySymbol,
       _qtyStepBySymbol = qtyStepBySymbol,
       _balanceManager = balanceManager;

  // Разместить ордер при стабильной стене

  void wireOrderAndPositionUpdates(IOrderBookSource hl) {
    hl.onOrder.listen(_handleOrderUpdate);
    hl.onPosition.listen(_handlePositionUpdate);
  }

  void _handleOrderUpdate(OrderSnapshot order) {
    final symbol = order.symbol.replaceAll('_USDT', '');

    // Отслеживаем только наши ордера
    if (!_isOurOrder(order.externalDid)) {
      return;
    }

    print(
      '[ORDER_UPDATE] ${order.symbol} state: ${order.state} externalId: ${order.externalDid}',
    );

    // ИСПРАВЛЕНИЕ: Исполнение нашего ордера - это УСПЕХ, а не причина для отмены!
    if (order.state == 3) {
      // completed
      print(
        '[ORDER_FILLED_SUCCESS] 🎉 Our order filled: ${order.externalDid} - STRATEGY WORKED!',
      );

      // НЕ отменяем встречные ордера - наоборот, стратегия сработала!
      // Просто логируем успех и продолжаем работу

      // Автоматически удаляем исполненный ордер из отслеживания
      _removeOrderFromTracking(symbol, order.externalDid);
      return;
    }

    // Автоматически удаляем отмененные/невалидные ордера
    if (order.state == 4 || order.state == 5) {
      print('[ORDER_CANCELLED/INVALID] Removing order: ${order.externalDid}');
      _removeOrderFromTracking(symbol, order.externalDid);
      return;
    }

    // Сохраняем/обновляем только активные ордера (state=2)
    if (order.state == 2) {
      if (!_activeOrders.containsKey(symbol)) {
        _activeOrders[symbol] = [];
      }

      // Убираем старые записи этого ордера
      _activeOrders[symbol]!.removeWhere(
        (o) => o.externalDid == order.externalDid,
      );
      _activeOrders[symbol]!.add(order);
    }
  }

  void _handlePositionUpdate(PositionSnapshot position) {
    final symbol = position.symbol.replaceAll('_USDT', '');

    print(
      '[POSITION_UPDATE] ${position.symbol} state: ${position.state} '
      'holdVol: ${position.holdVol} avgPrice: ${position.holdAvgPrice}',
    );

    // Автоматически удаляем закрытые позиции
    if (position.state == 3) {
      // closed
      print('[POSITION_CLOSED] Removing closed position: ${position.symbol}');
      _removePositionFromTracking(symbol, position.positionId);
      return;
    }

    // Сохраняем/обновляем только активные позиции (state=1)
    if (position.state == 1) {
      // holding
      if (!_activePositions.containsKey(symbol)) {
        _activePositions[symbol] = [];
      }

      // Убираем старые записи этой позиции
      _activePositions[symbol]!.removeWhere(
        (p) => p.positionId == position.positionId,
      );
      _activePositions[symbol]!.add(position);

      print(
        '[POSITION_ACTIVE] Active position: ${position.symbol} '
        'vol: ${position.holdVol} PnL: ${position.realised}',
      );
    }
  }

  void _removePositionFromTracking(String symbol, int positionId) {
    if (_activePositions.containsKey(symbol)) {
      _activePositions[symbol]!.removeWhere((p) => p.positionId == positionId);
      if (_activePositions[symbol]!.isEmpty) {
        _activePositions.remove(symbol);
      }
    }
  }

  void _removeOrderFromTracking(String symbol, String externalId) {
    if (_activeOrders.containsKey(symbol)) {
      final beforeCount = _activeOrders[symbol]!.length;

      // Удаляем ордер по externalId
      _activeOrders[symbol]!.removeWhere(
        (order) => order.externalDid == externalId,
      );

      final afterCount = _activeOrders[symbol]!.length;

      // Если список ордеров для этого символа пуст - удаляем весь ключ
      if (_activeOrders[symbol]!.isEmpty) {
        _activeOrders.remove(symbol);
        print(
          '[ORDER_TRACKING_REMOVED] Removed all orders for $symbol (deleted $externalId)',
        );
      } else {
        print(
          '[ORDER_TRACKING_REMOVED] Removed order $externalId from $symbol '
          '($beforeCount → $afterCount orders)',
        );
      }
    } else {
      print('[ORDER_TRACKING_SKIP] Symbol $symbol not found in tracking');
    }
  }

  bool _isOurOrder(String externalId) {
    return externalId.startsWith('HL');
  }

  // Future<void> _closePositionIfExists(String symbol) async {
  //   final positions = _activePositions[symbol];
  //   if (positions == null || positions.isEmpty) {
  //     print('[CLOSE_POSITION_SKIP] No active positions found for $symbol');
  //     return;
  //   }

  //   // СОЗДАЕМ КОПИЮ для безопасной итерации
  //   final positionsToProcess = List<PositionSnapshot>.from(positions);

  //   int closedCount = 0;
  //   int skipCount = 0;

  //   for (final position in positionsToProcess) {
  //     if (position.state == 1) {
  //       // position holding
  //       try {
  //         await _closePosition(position);
  //         closedCount++;
  //       } catch (e) {
  //         print(
  //           '[CLOSE_POSITION_ERROR] Failed to close position ${position.positionId}: $e',
  //         );
  //       }
  //     } else {
  //       skipCount++;
  //       print(
  //         '[CLOSE_POSITION_SKIP] Position ${position.positionId} state=${position.state} - skip',
  //       );
  //     }
  //   }

  //   print(
  //     '[POSITION_CLOSE_RESULT] Closed $closedCount positions, skipped $skipCount for $symbol',
  //   );
  // }

  // Future<void> _closePosition(PositionSnapshot position) async {
  //   try {
  //     // Логика закрытия позиции
  //     final closeSide = position.positionType == 1
  //         ? 4
  //         : 2; // 4=Close Long, 2=Close Short
  //     final closeExtId = _generateOrderId(position.symbol, 'CLOSE');

  //     final closeReq = CreateFuturesOrderRequest(
  //       symbol: position.symbol,
  //       price: 0, // market close
  //       type: 5, // market order
  // openType: position.openType,
  //       side: closeSide,
  //       vol: position.holdVol,
  //       externalId: closeExtId,
  //       leverage: injector<Program>().leveragePerCoin(position.symbol),
  //       isBid: closeSide == 4, // close long is like bid
  //     );

  //     final orderId = await _api.createFuturesOrder(closeReq);
  //     print(
  //       '[POSITION_CLOSING] Closing position: ${position.symbol} orderId: $orderId',
  //     );

  //     // УДАЛЯЕМ позицию из отслеживания после успешного запроса на закрытие
  //     _removePositionFromTracking(
  //       position.symbol.replaceAll('_USDT', ''),
  //       position.positionId,
  //     );
  //   } catch (e) {
  //     print(
  //       '[CLOSE_POSITION_ERROR] Failed to close position ${position.positionId}: $e',
  //     );
  //     rethrow;
  //   }
  // }

  Future<void> placeOrderOnWall(
    String coin,
    String side,
    double wallPrice, {
    String exchange = 'HYPERLIQUID',
  }) async {
    String trackerSymbol = injector<Program>().mapToTrackerSymbol(coin);

    // ПРОВЕРКА 1: если уже есть АКТИВНАЯ ПОЗИЦИЯ - не размещаем новый ордер
    if (hasActivePosition(trackerSymbol)) {
      print(
        '[SKIP_POSITION] Active position already exists for $coin - skipping order',
      );
      return;
    }

    // ПРОВЕРКА 2: если уже есть активные НЕИСПОЛНЕННЫЕ ордера для этого символа, не размещаем новые
    if (hasActiveOrders(trackerSymbol)) {
      print('[SKIP_ORDER] Active uncompleted orders already exist for $coin');
      return;
    }

    // ПРОВЕРКА 3: если есть ИСПОЛНЕННЫЕ ордера (значит позиция открыта), тоже не размещаем
    if (hasFilledOrders(trackerSymbol)) {
      print(
        '[SKIP_FILLED] Filled orders exist for $coin - position likely open',
      );
      return;
    }

    final mx = injector<Program>().mapToMexcSymbol(coin);
    final openSide = side == 'BID' ? 1 : 3;

    final usdPerLeg = injector<Program>().usdPerDeal(
      mx,
      _balanceManager.availableBalance,
      exchange,
    );
    final step = _qtyStepBySymbol(mx);
    final minVol = _minVolBySymbol(mx);

    // Расчет объема
    double qty;
    try {
      // final ticker = await _api.getFuturesTicker(mx);
      // final lastPrice = ticker.lastPrice;
      final lastPrice = wallPrice;
      final contractSize = injector<Program>().getContractSize(mx);

      qty =
          (usdPerLeg * injector<Program>().leveragePerCoin(mx)) /
          (lastPrice * contractSize);
      qty = _roundDownToStep(qty, step);

      // ДОПОЛНИТЕЛЬНОЕ ОКРУГЛЕНИЕ по точности символа
      final symbolPrecision = injector<Program>().getSymbolQuantityPrecision(
        mx,
      );
      qty = double.parse(qty.toStringAsFixed(symbolPrecision));

      if (qty < minVol) {
        qty = _roundDownToStep(minVol, step);
        qty = double.parse(qty.toStringAsFixed(symbolPrecision));
      }

      print(
        '[VOLUME_CALC] $coin: ($usdPerLeg * ${injector<Program>().leveragePerCoin(mx)}) / '
        '(${lastPrice.toStringAsFixed(6)} * $contractSize) = ${qty.toStringAsFixed(6)} '
        '→ rounded to ${qty.toStringAsFixed(symbolPrecision)}',
      );
    } catch (e) {
      print('[VOLUME_FALLBACK] Using fallback calculation for $coin: $e');
      qty = usdPerLeg / wallPrice;
      qty = _roundDownToStep(qty, step);

      final symbolPrecision = injector<Program>().getSymbolQuantityPrecision(
        mx,
      );
      qty = double.parse(qty.toStringAsFixed(symbolPrecision));

      if (qty < minVol) {
        qty = _roundDownToStep(minVol, step);
        qty = double.parse(qty.toStringAsFixed(symbolPrecision));
      }
    }

    if (qty < minVol) {
      print('[SKIP_MIN_VOL] qty below minimum: $qty < $minVol for $coin');
      return;
    }

    final openExt = _generateOrderId(mx, 'OPEN');

    try {
      print(
        '[ORDER_PLACING] Placing order for $coin $side '
        '@${wallPrice.toStringAsFixed(6)} qty=${qty.toStringAsFixed(4)}',
      );

      final openReq = CreateFuturesOrderRequest(
        symbol: mx,
        price: wallPrice,
        type: 1, // Limit
        openType: 1, // Isolated
        side: openSide,
        vol: double.parse(qty.toStringAsFixed(0)),
        externalId: openExt,
        leverage: injector<Program>().leveragePerCoin(mx),
        isBid: side == 'BID',
        isBinance: exchange != 'HYPERLIQUID',
      );

      final openOrderId = await _api.createFuturesOrder(openReq);

      print(
        '[ORDER_PLACED] SUCCESS: $coin $side '
        'Open: $openOrderId (@${wallPrice.toStringAsFixed(6)}, qty: ${qty.toStringAsFixed(4)})',
      );

      // НОВОЕ: Запускаем таймер проверки исполнения
      _startOrderCheckTimer(coin, openExt);
    } catch (e) {
      print('[ORDER_ERROR] FAILED to place order for $coin: $e');
      // Останавливаем таймер при ошибке
      _stopOrderCheckTimer(coin);
      try {
        await _cancelOrderSafe(coin, openExt);
      } catch (cancelError) {
        print('[ORDER_CLEANUP_ERROR] Failed to cleanup order: $cancelError');
      }
    }
  }

  // Отменить ордер при падении стены на 50%

  Future<void> cancelOrderOnWallDisappear(String coin) async {
    final orders = _activeOrders[coin];
    if (orders == null || orders.isEmpty) {
      print('[CANCEL_SKIP] No active orders found for $coin');
      return;
    }

    try {
      print('[ORDER_CANCELING] Found ${orders.length} orders for $coin');

      // СОЗДАЕМ КОПИЮ для безопасной итерации
      final ordersToProcess = List<OrderSnapshot>.from(orders);

      int cancelledCount = 0;
      int skipCount = 0;

      for (final order in ordersToProcess) {
        // Отменяем только неисполненные ордера (state=2)
        if (order.state == 2) {
          try {
            await _cancelOrderSafe(coin, order.externalDid);
            cancelledCount++;
            print('[ORDER_CANCELLED] Cancelled order: ${order.externalDid}');
          } catch (e) {
            print(
              '[CANCEL_ORDER_ERROR] Failed to cancel ${order.externalDid}: $e',
            );
          }
        } else {
          skipCount++;
          print(
            '[CANCEL_SKIP] Order ${order.externalDid} state=${order.state} - skip',
          );
        }
      }

      // Всегда удаляем из активных, даже если не все удалось отменить
      _activeOrders.remove(coin);

      print(
        '[ORDER_CANCELLED] SUCCESS: Cancelled $cancelledCount orders, skipped $skipCount for $coin',
      );
    } catch (e) {
      print('[CANCEL_ERROR] FAILED to cancel orders for $coin: $e');
      // При ошибке все равно удаляем, чтобы не зацикливаться
      _activeOrders.remove(coin);
    }
  }

  // Безопасная отмена ордера
  Future<void> _cancelOrderSafe(String coin, String externalId) async {
    try {
      await _api.cancelFuturesOrderWithExternalId(
        injector<Program>().mapToMexcSymbol(coin),
        externalId,
      );
    } catch (e) {
      // Игнорируем ошибки "ордер не найден" или "нельзя отменить"
      final errorStr = e.toString();
      if (errorStr.contains('2001') || // order not found
          errorStr.contains(
            '2041',
          ) || // cannot cancel (already filled/cancelled)
          errorStr.contains('2042')) {
        // order completed
        print('[CANCEL_SKIP] Order $externalId already filled/cancelled: $e');
        return;
      }
      // Для других ошибок - пробрасываем исключение
      rethrow;
    }
  }

  bool hasFilledOrders(String symbol) {
    final orders = _activeOrders[symbol];
    if (orders == null || orders.isEmpty) return false;

    return orders.any((order) => order.state == 3); // state=3 completed
  }

  // НОВЫЙ МЕТОД: проверка есть ли активные неисполненные ордера
  bool hasActiveOrders(String symbol) {
    final orders = _activeOrders[symbol];
    if (orders == null || orders.isEmpty) return false;

    return orders.any((order) => order.state == 2); // state=2 uncompleted
  }

  bool hasActivePosition(String symbol) {
    final positions = _activePositions[symbol];
    if (positions == null || positions.isEmpty) return false;

    return positions.any((position) => position.state == 1); // state=1 holding
  }

  List<OrderSnapshot> getOrdersForSymbol(String symbol) {
    return List.from(_activeOrders[symbol] ?? []);
  }

  // Вспомогательные методы
  double _roundDownToStep(double value, double step) {
    if (step <= 0) return value;
    final k = (value / step).floorToDouble();
    return k * step;
  }

  void _startOrderCheckTimer(String symbol, String externalId) {
    // Отменяем предыдущий таймер если был
    _stopOrderCheckTimer(symbol);

    print('[ORDER_CHECK_TIMER] Starting 1min timer for $symbol ($externalId)');

    _orderCheckTimers[symbol] = Timer(Duration(seconds: 25), () {
      _checkOrderFilled(symbol, externalId);
    });
  }

  // Остановка таймера
  void _stopOrderCheckTimer(String symbol) {
    final timer = _orderCheckTimers[symbol];
    if (timer != null) {
      timer.cancel();
      _orderCheckTimers.remove(symbol);
      print('[ORDER_CHECK_TIMER] Stopped timer for $symbol');
    }
  }

  // Проверка исполнения ордера
  void _checkOrderFilled(String symbol, String externalId) {
    print('[ORDER_CHECK] Checking if order $externalId filled for $symbol');

    // Ищем ордер в активных
    final orders = _activeOrders[symbol];
    if (orders == null || orders.isEmpty) {
      print('[ORDER_CHECK] No orders found for $symbol - cancelling');
      _cancelOrderSafe(symbol, externalId);
      return;
    }

    final order = orders.firstWhere(
      (o) => o.externalDid == externalId,
      orElse: () => OrderSnapshot(
        ordered: 0,
        symbol: '',
        positionId: 0,
        price: 0,
        vol: 0,
        leverage: 0,
        side: 0,
        category: 0,
        orderType: 0,
        dealWgPrice: 0,
        dealVol: 0,
        orderMargin: 0,
        usedMargin: 0,
        takerFee: 0,
        makerFee: 0,
        profit: 0,
        feeCurrency: '',
        openType: 0,
        state: 0,
        errorCode: 0,
        externalDid: '',
        createTime: DateTime.now(),
        updateTime: DateTime.now(),
      ),
    );

    // Если ордер не найден или не исполнен - отменяем
    if (order.externalDid.isEmpty || order.state != 3) {
      print(
        '[ORDER_CHECK_TIMEOUT] Order $externalId not filled within 1min - CANCELLING',
      );
      _cancelOrderSafe(symbol, externalId);

      // Удаляем из активных
      _removeOrderFromTracking(symbol, externalId);
    } else {
      print('[ORDER_CHECK_SUCCESS] Order $externalId already filled');
    }

    // Очищаем таймер в любом случае
    _orderCheckTimers.remove(symbol);
  }

  String _generateOrderId(String mexcSymbol, String type) {
    final baseSym = mexcSymbol.split('_')[0].toUpperCase();
    final now = DateTime.now().toUtc();
    final t =
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';

    final random = now.millisecond;
    return 'HL${baseSym.substring(0, math.min(3, baseSym.length))}$t${random.toString().padLeft(3, '0')}$type';
  }
}
