import 'dart:async';
import 'dart:convert';

import 'package:scalpx3/entities/candle.dart';
import 'package:scalpx3/entities/deal_model.dart';
import 'package:scalpx3/entities/signal_model.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class TradeBot {
  late WebSocketChannel _channel;
  final String symbol = 'ZEC_USDT';
  Candle? lastCandle;
  SignalModel? lastSignal;

  List<DealModel> deals = [];

  Future<void> connect() async {
    print('🔄 Подключение к фьючерсному WebSocket MEXC...');
    // Важно: используем фьючерсный эндпойнт[citation:1]
    final uri = Uri.parse('wss://api.hyperliquid.xyz/ws');
    _channel = WebSocketChannel.connect(uri);

    // Отправляем ping каждые 15 секунд для поддержания соединения[citation:1]
    Timer.periodic(Duration(seconds: 15), (_) {
      _channel.sink.add(jsonEncode({'method': 'ping'}));
    });

    _channel.stream.listen(
      _handleIncomingMessage,
      onError: (error) => print('❌ Ошибка WebSocket: $error'),
      onDone: () => print('📴 Соединение закрыто HL'),
    );

    // Небольшая задержка перед подпиской
    await Future.delayed(Duration(seconds: 1));
    _subscribeToDeals();
    await Future.delayed(Duration(seconds: 1));
    _subscribeToKline();
  }

  void _handleIncomingMessage(dynamic message) {
    try {
      if (message is String) {
        final jsonMsg = jsonDecode(message);
        if (jsonMsg['channel'] == 'pong') {
          return; // Игнорируем ответы на ping
        }

        if (jsonMsg['channel'] == 'candle') {
          _processKlineData(jsonMsg);
        }

        if (jsonMsg['channel'] == 'trades') {
          _processDealData(jsonMsg);
        }

        if (jsonMsg['channel'] == 'post') {
          print(message);
        }
        if (jsonMsg['channel'] == 'error') {
          print(message);
        }
      } else if (message is List<int>) {
        print(
          '⚠️ Получены бинарные данные. Убедитесь в правильной десериализации Protobuf[citation:2][citation:6].',
        );
      }
    } catch (e) {
      print('Ошибка обработки сообщения: $e');
    }
  }

  void _subscribeToDeals() {
    // Формат подписки на K-line для фьючерсов[citation:1]
    final subscribeMsg = {
      "method": "subscribe",
      "subscription": {"type": "trades", "coin": "ZEC"},
    };
    print('📡 Подписка на данные: $symbol');
    _channel.sink.add(jsonEncode(subscribeMsg));
  }

  void _processDealData(dynamic dealData) {
    List<dynamic> data = (dealData['data'] as List);

    List<DealModel> deals = data.map((d) => DealModel.fromJson(d)).toList();
    for (var deal in deals) {
      // if (deal.type == 2) {
      // print("${deal.totalSum}");
      // }
      addToBuffer(deal);
      // print("${deal.price} ${deal.quantity}");
    }
  }

  void _subscribeToKline() {
    // Формат подписки на K-line для фьючерсов[citation:1]
    final subscribeMsg = {
      'method': 'subscribe',
      'subscription': {"type": "candle", "coin": "ZEC", "interval": "1m"},
    };
    print('📡 Подписка на данные: $symbol (Min1)');
    _channel.sink.add(jsonEncode(subscribeMsg));
  }

  void _processKlineData(dynamic klineData) {
    // Пример обработки JSON-данных свечи[citation:1]
    final candle = Candle(
      open: double.parse(klineData['data']['o'].toString()),
      high: double.parse(klineData['data']['h'].toString()),
      low: double.parse(klineData['data']['l'].toString()),
      close: double.parse(klineData['data']['c'].toString()),
      volume: double.parse(klineData['data']['v'].toString()),
      time: DateTime.fromMillisecondsSinceEpoch(klineData['data']['t']),
    );

    lastCandle = candle;
  }

  void sendOrder() {
    final orderMessage = {
      "method": "post",
      "id": 256,
      "request": {
        "type": "action",
        "payload": {
          "action": {
            "type": "order",
            "orders": [
              {
                "a": 4,
                "b": true,
                "p": "1100",
                "s": "0.2",
                "r": false,
                "t": {
                  "limit": {"tif": "Gtc"},
                },
              },
            ],
            "grouping": "na",
          },
          "nonce": 1713825891591,
          "signature": {"r": "...", "s": "...", "v": "..."},
          "vaultAddress": "0xaF968AD4dEd405C5DFa59b07c2E11716506f4697",
        },
      },
    };
    _channel.sink.add(jsonEncode(orderMessage));
  }

  void addToBuffer(DealModel deal) {
    deals.add(deal);
    if (deals.length >= 100) {
      deals.removeAt(0);
    }

    if (deals.where((a) => a.tradeSide == "A").isNotEmpty &&
        deals.where((b) => b.tradeSide == "B").isNotEmpty) {
      double totalBuy = deals
          .where((d) => d.tradeSide == 'B')
          .map((deal) => deal.totalSum)
          .reduce((a, b) => a + b);

      double totalSell = deals
          .where((d) => d.tradeSide == 'A')
          .map((deal) => deal.totalSum)
          .reduce((a, b) => a + b);

      SignalModel currentSignal;

      if (lastCandle != null) {
        if (totalBuy > totalSell) {
          // print('LONG: ${(totalBuy / totalSell).toStringAsFixed(2)}');
          currentSignal = SignalModel(
            type: SignalEnum.long,
            power: (totalBuy / totalSell),
            aPrice: lastCandle!.close,
            aTime: DateTime.now(),
          );
        } else {
          // print('SHORT: ${(totalSell / totalBuy).toStringAsFixed(2)}');
          currentSignal = SignalModel(
            type: SignalEnum.short,
            power: (totalSell / totalBuy),
            aPrice: lastCandle!.close,
            aTime: DateTime.now(),
          );
        }
        if (lastSignal?.type != currentSignal.type) {
          lastSignal = currentSignal;
          print(currentSignal);
          // sendOrder();
        }
      }
    }
  }
}
