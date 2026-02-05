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

  List<DealModel> buyDeals = [];
  List<DealModel> sellDeals = [];

  Future<void> connect() async {
    print('🔄 Подключение к фьючерсному WebSocket MEXC...');
    // Важно: используем фьючерсный эндпойнт[citation:1]
    final uri = Uri.parse('wss://contract.mexc.com/edge');
    _channel = WebSocketChannel.connect(uri);

    // Отправляем ping каждые 15 секунд для поддержания соединения[citation:1]
    Timer.periodic(Duration(seconds: 15), (_) {
      _channel.sink.add(jsonEncode({'method': 'ping'}));
    });

    _channel.stream.listen(
      _handleIncomingMessage,
      onError: (error) => print('❌ Ошибка WebSocket: $error'),
      onDone: () => print('📴 Соединение закрыто'),
    );

    // Небольшая задержка перед подпиской
    await Future.delayed(Duration(seconds: 1));
    _subscribeToDeals();
    await Future.delayed(Duration(seconds: 1));
  }

  void _handleIncomingMessage(dynamic message) {
    // print(message);
    try {
      // 1. Проверяем, является ли сообщение строкой JSON (например, ping/pong)
      if (message is String) {
        final jsonMsg = jsonDecode(message);
        if (jsonMsg['channel'] == 'pong') {
          return; // Игнорируем ответы на ping
        }
        // Обрабатываем сообщения с данными (например, push.kline)

        if (jsonMsg['channel'] == 'push.deal') {
          _processDealData(jsonMsg);
        }
      }
      // 2. Если сообщение бинарное (Protobuf) - десериализуем
      else if (message is List<int>) {
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
      'method': 'sub.deal',
      'param': {
        'symbol': symbol, // например, 'BTC_USDT'
      },
    };
    print('📡 Подписка на данные: $symbol');
    _channel.sink.add(jsonEncode(subscribeMsg));
  }

  void _processDealData(dynamic dealData) {
    List<dynamic> data = (dealData['data'] as List);

    List<DealModel> deals = data.map((d) => DealModel.fromJson(d)).toList();
    double price = 0;
    double quantity = 0;
    for (var deal in deals) {
      // if (deal.type == 2) {
      print("${deal.price} ${deal.quantity}");
      // }
      // addToBuffer(deal);
    }
  }

  void addToBuffer(DealModel deal) {
    if (deal.tradeSide == 1) {
      buyDeals.add(deal);
    } else {
      sellDeals.add(deal);
    }

    double totalBuy = buyDeals
        .map((deal) => deal.totalSum)
        .reduce((a, b) => a + b);

    double totalSell = sellDeals
        .map((deal) => deal.totalSum)
        .reduce((a, b) => a + b);

    if (totalBuy > totalSell) {
      print('LONG: ${(totalBuy / totalSell).toStringAsFixed(2)}');
    } else {
      print('SHORT: ${(totalSell / totalBuy).toStringAsFixed(2)}');
    }
  }
}
