import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:scalpx3/api/mexc_bypass.dart';
import 'package:scalpx3/entities/futures_assets.dart';
import 'package:scalpx3/entities/futures_ticker_model.dart';
import 'package:scalpx3/interface/i_exchange_api.dart';

import 'create_futures_order_request.dart';

class MexcApi implements IExchangeApi {
  final http.Client _client = http.Client();
  final String _baseUrl;
  final String _apiKey;
  final String _webKey;
  final String _network;
  final MexcBypass _mexcBypass;

  MexcApi(String baseUrl, String apiKey, String webKey, String network)
    : _baseUrl = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl,
      _apiKey = apiKey,
      _webKey = webKey,
      _network = network,
      _mexcBypass = MexcBypass(apiKey: webKey);

  @override
  Future<FuturesAssets> getFuturesAssets(String currency) async {
    final response = await _mexcBypass.getFuturesAssets();

    // if (response.statusCode != 200) {
    //   // print('[MEXC/getFuturesAssets] ${response.body}');
    //   throw Exception('Balance request failed: ${response.statusCode}');
    // }

    final data = response;

    final assets = (data['data'] as List)
        .where((s) => s['currency'] == 'USDT')
        .single;

    print(assets);

    return FuturesAssets(
      currency: assets['currency'],
      availableBalance: double.parse(assets['availableBalance'].toString()),
      cashBalance: double.parse(assets['cashBalance'].toString()),
      equity: double.parse(assets['equity'].toString()),
      success: data['success'],
      isTestnet: false,
    );
  }

  @override
  Future<FuturesTicker> getFuturesTicker(String symbol) async {
    final response = await _mexcBypass.getFuturesTicker({'symbol': symbol});

    // print('[MEXC/getFuturesTickers] ${response.body}');

    // if (response.statusCode != 200) {
    //   throw Exception('Ticker request failed: ${response.statusCode}');
    // }

    final data = response;
    if (data['success'] == false) {
      throw Exception(
        'getFuturesTickers failed: ${data['message'] ?? 'Unknown error'}',
      );
    }

    return FuturesTicker.fromJson(data);
  }

  @override
  Future<int> createFuturesOrder(CreateFuturesOrderRequest req) async {
    final startTime = DateTime.now();
    // final response = await _client.post(
    //   Uri.parse('$_baseUrl/v1/createFuturesOrder'),
    //   headers: {..._headers, 'Content-Type': 'application/json'},
    //   body: json.encode(req.toJson()),
    // );

    // final response = await _client.post(
    //   Uri.parse('$_baseUrl/v1/createFuturesOrder'),
    //   headers: {..._headers, 'Content-Type': 'application/json'},
    //   body: json.encode(req.toJson()),
    // );

    final response = await _mexcBypass.createFuturesOrder(req.toJson());

    print('${DateTime.now()}:[MEXC/createFuturesOrder] $response');

    // if (response.statusCode != 200) {
    //   throw Exception('Order creation failed: ${response.statusCode}');
    // }
    final endTime = DateTime.now();
    final data = response;
    if (data['success'] == false) {
      final code = data['code']?.toString() ?? '?';
      final msg = data['message']?.toString() ?? '';
      throw Exception('createFuturesOrder failed, code=$code, msg=$msg');
    }
    final latency = endTime.difference(startTime).inMilliseconds;
    print('[REQUEST PING] $latency');

    return int.parse(data['data']['orderId']);
  }

  @override
  Future<void> cancelFuturesOrderWithExternalId(
    String symbol,
    String externalId,
  ) async {
    final payload = {'symbol': symbol, 'external_id': externalId};
    // final response = await _client.post(
    //   Uri.parse('$_baseUrl/v1/cancelFuturesOrderWithExternalId'),
    //   headers: {..._headers, 'Content-Type': 'application/json'},
    //   body: json.encode(payload),
    // );

    final response = await _mexcBypass.cancelFuturesOrderWithExternalId(
      payload,
    );

    print('[MEXC/cancelFuturesOrderWithExternalId] $response');

    // if (response.statusCode != 200) {
    //   throw Exception('Cancel failed: ${response.statusCode}');
    // }
  }

  @override
  Future<double> getFairPrice(String mexcSymbol) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/v1/getFuturesContractFairPrice?symbol=$mexcSymbol'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      print('[MEXC/fairPrice] ${response.body}');
      throw Exception('Fair price request failed: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    if (data['success'] == false) {
      throw Exception('fairPrice failed: ${response.body}');
    }

    return double.parse(data['data']['fairPrice'].toString());
  }

  Map<String, String> get _headers => {
    'X-MEXC-BYPASS-API-KEY': _apiKey,
    'X-MEXC-WEB-KEY': _webKey,
    'X-MEXC-NETWORK': _network,
  };

  @override
  void dispose() {
    _client.close();
  }
}
