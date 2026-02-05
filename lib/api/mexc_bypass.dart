import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

class MexcBypass {
  String? apiKey;
  bool isTestnet;
  String? proxyUrl;

  late Map<String, String> baseUrls;

  MexcBypass({this.apiKey, this.isTestnet = false, this.proxyUrl}) {
    baseUrls = {
      'api': 'https://api.mexc.com',
      'general': 'https://www.mexc.com',
      'futures': isTestnet
          ? 'https://futures.testnet.mexc.com/api/v1'
          : 'https://futures.mexc.com/api/v1',
      'contract': 'https://contract.mexc.com/api/v1',
      'other': '',
    };
  }

  List<String> generateSignature(Map<String, dynamic> payload, String method) {
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final time = currentTime.toString();
    final g = md5.convert(utf8.encode('$apiKey$time')).toString().substring(7);

    String sign;
    if (method == 'GET' || method == 'DELETE') {
      final queryString = Uri(queryParameters: _stringifyMap(payload)).query;
      sign = md5.convert(utf8.encode('$time$queryString$g')).toString();
    } else {
      final jsonPayload = payload.isNotEmpty ? jsonEncode(payload) : '';
      sign = md5.convert(utf8.encode('$time$jsonPayload$g')).toString();
    }

    return [time, sign];
  }

  Map<String, dynamic> _stringifyMap(Map<String, dynamic> map) {
    return map.map((key, value) => MapEntry(key, value?.toString() ?? ''));
  }

  Map<String, dynamic> createErrorResponse(int code, String message) {
    return {
      'success': false,
      'code': code,
      'message': message,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'isTestnet': isTestnet,
    };
  }

  Map<String, String> prepareHeaders(
    String apiType,
    List<String> signatureData,
    String origin,
  ) {
    final time = signatureData[0];
    final sign = signatureData[1];

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': '*/*',
      'Accept-Encoding': 'gzip, deflate, br',
      'User-Agent': 'Mozilla/5.0 (compatible; MEXC-API/1.0)',
      'Origin': origin,
      'Connection': 'keep-alive',
    };

    if (apiType == 'general') {
      headers['Cookie'] = 'u_id=$apiKey; uc_token=$apiKey;';
      headers['Ucenter-Token'] = apiKey!;
    } else {
      headers['Authorization'] = apiKey!;
      headers['X-Mxc-Nonce'] = time;
      headers['X-Mxc-Sign'] = sign;
    }

    return headers;
  }

  String buildUrl(
    String baseUrl,
    String endpoint,
    Map<String, dynamic> data,
    String method,
  ) {
    String url = baseUrl + endpoint;

    if ((method == 'GET' || method == 'DELETE') && data.isNotEmpty) {
      final queryParams = data.entries
          .where((entry) => entry.value != null)
          .map(
            (entry) =>
                '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value.toString())}',
          )
          .join('&');
      url += '?$queryParams';
    }

    return url;
  }

  Future<Map<String, dynamic>> request({
    String method = 'GET',
    String apiType = 'futures',
    String endpoint = '',
    Map<String, dynamic> data = const {},
  }) async {
    String baseUrl;

    if (apiType == 'other') {
      final parsedUrl = Uri.parse(endpoint);
      baseUrl = 'https://${parsedUrl.host}';
      endpoint =
          parsedUrl.path +
          (parsedUrl.query.isNotEmpty ? '?${parsedUrl.query}' : '');
    } else {
      baseUrl = baseUrls[apiType]!;
    }

    final signatureData = generateSignature(data, method);
    final origin = baseUrl.split('/').sublist(0, 3).join('/');
    final headers = prepareHeaders(apiType, signatureData, origin);
    final url = buildUrl(
      baseUrl,
      endpoint,
      (method == 'GET' || method == 'DELETE') ? data : {},
      method,
    );

    try {
      final client = http.Client();
      final request = Request(method, Uri.parse(url));
      request.headers.addAll(headers);

      if ((method == 'POST' || method == 'PUT') && data.isNotEmpty) {
        request.body = jsonEncode(data);
      }

      final streamedResponse = await client.send(request);
      final response = await Response.fromStream(streamedResponse);

      if (response.body == 'false') {
        return createErrorResponse(response.statusCode, 'Request failed');
      }

      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        return createErrorResponse(
          response.statusCode,
          'Invalid JSON response',
        );
      }

      responseData['isTestnet'] = isTestnet;
      return responseData;
    } catch (error) {
      return createErrorResponse(-1, 'Client error: $error');
    }
  }

  dynamic renameArrayKeys(dynamic data, Map<String, String> keysMap) {
    if (data == null) return null;

    // Обработка списка
    if (data is List<dynamic>) {
      return data.map((item) => renameArrayKeys(item, keysMap)).toList();
    }

    // Обработка Map с ключами String
    if (data is Map<String, dynamic>) {
      return data.map<String, dynamic>((key, value) {
        final newKey = keysMap[key] ?? key;
        return MapEntry<String, dynamic>(
          newKey,
          renameArrayKeys(value, keysMap),
        );
      });
    }

    // Обработка Map с динамическими ключами
    if (data is Map<dynamic, dynamic>) {
      final result = <String, dynamic>{};

      data.forEach((key, value) {
        final stringKey = key.toString();
        final newKey = keysMap[stringKey] ?? stringKey;
        result[newKey] = renameArrayKeys(value, keysMap);
      });

      return result;
    }

    // Возвращаем примитивные значения как есть
    return data;
  }

  // === API methods ===

  Future<Map<String, dynamic>> getServerTime() async {
    return request(
      method: 'GET',
      apiType: 'contract',
      endpoint: '/contract/ping',
    );
  }

  Future<Map<String, dynamic>> getCustomerInfo() async {
    return request(
      method: 'GET',
      apiType: 'general',
      endpoint: '/ucenter/api/customer_info',
    );
  }

  Future<Map<String, dynamic>> getMarketSymbols([
    Map<String, dynamic> params = const {},
  ]) async {
    final response = await request(
      method: 'GET',
      apiType: 'general',
      endpoint: '/api/platform/spot/market-v2/web/symbolsV2',
    );

    if (response['data'] != null) {
      final fields = {
        'mcd': 'marketCurrencyId',
        'cd': 'coinId',
        'vn': 'currency',
        'fn': 'currencyFullName',
        'srt': 'sortOrder',
        'sts': 'status',
        'tp': 'marketType',
        'in': 'icon',
        'ot': 'openingTime',
        'cp': 'categories',
        'ci': 'categories_ids',
        'ps': 'priceScale',
        'qs': 'quantityScale',
        'cdm': 'contractDecimalMultiplier',
        'st': 'spotEnabled',
        'dst': 'depositStatus',
        'tt': 'tradingType',
        'ca': 'contractAddress',
        'fne': 'currencyFullNameEn',
      };

      response['data'] = renameArrayKeys(response['data'], fields);
    }

    String? baseCoin;
    final quoteCoin = params['quoteCoin'] ?? 'USDT';

    if (params['symbol'] != null && params['baseCoin'] == null) {
      final parts = (params['symbol'] as String).split('_');
      baseCoin = parts[0];
    } else {
      baseCoin = params['baseCoin'];
    }

    if (baseCoin != null) {
      final search = baseCoin.toUpperCase();

      if (response['data'] != null &&
          response['data']['symbols'] != null &&
          response['data']['symbols'][quoteCoin] != null) {
        final symbols = response['data']['symbols'][quoteCoin] as List;

        final matches = symbols
            .where(
              (item) =>
                  item['currency'] != null &&
                  (item['currency'] as String).toUpperCase() == search,
            )
            .toList();

        if (matches.isEmpty) {
          return createErrorResponse(404, 'No matching tokens found');
        }

        return {
          'success': true,
          'count': matches.length,
          'data': matches,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
      } else {
        return createErrorResponse(400, 'No $quoteCoin symbols found');
      }
    }

    return response;
  }

  Future<Map<String, dynamic>> getFuturesTodayPnL() async {
    return request(
      method: 'GET',
      apiType: 'futures',
      endpoint: '/private/account/asset/analysis/today_pnl',
    );
  }

  Future<Map<String, dynamic>> getFuturesContracts([
    Map<String, dynamic> params = const {},
  ]) async {
    final response = await request(
      method: 'GET',
      apiType: 'futures',
      endpoint: '/contract/detailV2',
      data: {'symbol': params['symbol']},
    );

    if (response['data'] != null) {
      final fields = {
        'dn': 'displayName',
        'dne': 'displayNameEn',
        'pot': 'positionOpenType',
        'bc': 'baseCoin',
        'qc': 'quoteCoin',
        'bcn': 'baseCoinName',
        'qcn': 'quoteCoinName',
        'ft': 'futureType',
        'sc': 'settleCoin',
        'cs': 'contractSize',
        'minL': 'minLeverage',
        'maxL': 'maxLeverage',
        'ccMaxL': 'countryConfigContractMaxLeverage',
        'ps': 'priceScale',
        'vs': 'volScale',
        'as': 'amountScale',
        'pu': 'priceUnit',
        'vu': 'volUnit',
        'minV': 'minVol',
        'maxV': 'maxVol',
        'blpr': 'bidLimitPriceRate',
        'alpr': 'askLimitPriceRate',
        'tfr': 'takerFeeRate',
        'mfr': 'makerFeeRate',
        'mmr': 'maintenanceMarginRate',
        'imr': 'initialMarginRate',
        'rbv': 'riskBaseVol',
        'riv': 'riskIncrVol',
        'rlss': 'riskLongShortSwitch',
        'rim': 'riskIncrMmr',
        'rii': 'riskIncrImr',
        'rll': 'riskLevelLimit',
        'pcv': 'priceCoefficientVariation',
        'io': 'indexOrigin',
        'in': 'isNew',
        'ih': 'isHot',
        'ihd': 'isHidden',
        'ip': 'isPromoted',
        'cp': 'conceptPlate',
        'cpi': 'conceptPlateId',
        'rlt': 'riskLimitType',
        'mno': 'maxNumOrders',
        'moml': 'marketOrderMaxLevel',
        'moplr1': 'marketOrderPriceLimitRate1',
        'moplr2': 'marketOrderPriceLimitRate2',
        'tp': 'triggerProtect',
        'ae': 'appraisal',
        'sac': 'showAppraisalCountdown',
        'ad': 'automaticDelivery',
        'aa': 'apiAllowed',
        'dsl': 'depthStepList',
        'lmv': 'limitMaxVol',
        'tsd': 'threshold',
        'bciu': 'baseCoinIconUrl',
        'bcid': 'baseCoinId',
        'ct': 'createTime',
        'ot': 'openingTime',
        'oco': 'openingCountdownOption',
        'sbo': 'showBeforeOpen',
        'iml': 'isMaxLeverage',
        'izfr': 'isZeroFeeRate',
        'rlm': 'riskLimitMode',
        'rlcs': 'riskLimitCustom',
        'izfs': 'isZeroFeeSymbol',
        'liqfr': 'liquidationFeeRate',
        'frm': 'feeRateMode',
        'levfrs': 'leverageFeeRates',
        'tiefrs': 'tieredFeeRates',
      };

      response['data'] = renameArrayKeys(response['data'], fields);
    }

    return response;
  }

  Future<Map<String, dynamic>> calculateFuturesVolume(
    Map<String, dynamic> params,
  ) async {
    final requiredParams = ['symbol', 'amount', 'leverage'];

    for (final param in requiredParams) {
      if (params[param] == null) {
        return createErrorResponse(404, 'Missed $param');
      }
    }

    final ticker = await getFuturesTickers({'symbol': params['symbol']});

    if (!ticker['success'] || ticker['data'] == null) {
      return createErrorResponse(
        400,
        'Failed to get ticker data or empty response',
      );
    }

    final contract = await getFuturesContracts({'symbol': params['symbol']});

    if (!contract['success'] ||
        contract['data'] == null ||
        (contract['data'] as List).isEmpty) {
      return createErrorResponse(
        400,
        'Failed to get contract data or empty response',
      );
    }

    final contractData = (contract['data'] as List)[0];
    final priceType =
        params['priceType'] ?? params['price_type'] ?? 'last_price';

    double price;
    switch (priceType) {
      case 'index_price':
        price = double.tryParse(ticker['data']['indexPrice'].toString()) ?? 0;
        break;
      case 'fair_price':
        price = double.tryParse(ticker['data']['fairPrice'].toString()) ?? 0;
        break;
      default:
        price = double.tryParse(ticker['data']['lastPrice'].toString()) ?? 0;
        break;
    }

    if (price <= 0) {
      return createErrorResponse(400, 'Invalid price value');
    }

    final amount = double.tryParse(params['amount'].toString()) ?? 0;
    if (amount <= 0) {
      return createErrorResponse(400, 'Amount must be positive');
    }

    final leverage = double.tryParse(params['leverage'].toString()) ?? 0;
    if (leverage <= 0) {
      return createErrorResponse(400, 'Leverage must be positive');
    }

    final contractSize =
        double.tryParse(contractData['contractSize'].toString()) ?? 0;
    if (contractSize <= 0) {
      return createErrorResponse(400, 'Invalid contract size');
    }

    double adjustedLeverage;
    final minLeverage =
        double.tryParse(contractData['minLeverage'].toString()) ?? 0;
    final maxLeverage =
        double.tryParse(contractData['maxLeverage'].toString()) ?? 0;

    if (leverage < minLeverage) {
      adjustedLeverage = minLeverage;
    } else if (leverage > maxLeverage) {
      adjustedLeverage = maxLeverage;
    } else {
      adjustedLeverage = leverage;
    }

    double volume = (amount * adjustedLeverage) / (price * contractSize);

    final volumeScale = int.tryParse(contractData['volScale'].toString()) ?? 0;
    final volumeUnit = double.tryParse(contractData['volUnit'].toString()) ?? 1;

    double roundedVolume = double.parse(volume.toStringAsFixed(volumeScale));

    if (volumeUnit > 0) {
      roundedVolume = (roundedVolume / volumeUnit).floor() * volumeUnit;
    }

    final minVol = double.tryParse(contractData['minVol'].toString()) ?? 0;
    final maxVol =
        double.tryParse(contractData['maxVol'].toString()) ?? double.maxFinite;

    if (roundedVolume < minVol) {
      roundedVolume = minVol;
    } else if (roundedVolume > maxVol) {
      roundedVolume = maxVol;
    }

    final usdtValue = double.parse(
      ((roundedVolume * price * contractSize) / adjustedLeverage)
          .toStringAsFixed(contractData['priceScale'] ?? 2),
    );

    return {
      'success': true,
      'code': 0,
      'data': {
        'usdt_value': usdtValue,
        'volume': roundedVolume,
        'leverage': adjustedLeverage,
        'price': price,
        'min_volume': minVol,
        'max_volume': maxVol,
        'min_leverage': minLeverage,
        'max_leverage': maxLeverage,
        'price_type': priceType,
        'volume_scale': contractData['volScale'],
        'volume_unit': contractData['volUnit'],
        'price_scale': contractData['priceScale'],
        'price_unit': contractData['priceUnit'],
      },
    };
  }

  Future<Map<String, dynamic>> createFuturesOrder(
    Map<String, dynamic> params,
  ) async {
    final payload = <String, dynamic>{
      'symbol': params['symbol'],
      'price': params['price'],
      'type': params['type'],
      'openType': params['open_type'] ?? params['openType'],
      'positionMode': params['position_mode'] ?? params['positionMode'],
      'side': params['side'],
      'vol': params['vol'],
      'leverage': params['leverage'],
      'positionId': params['position_id'] ?? params['positionId'],
      'externalOid': params['external_id'] ?? params['externalId'],
      'takeProfitPrice':
          params['take_profit_price'] ?? params['takeProfitPrice'],
      'profitTrend':
          params['take_profit_trend'] ?? params['takeProfitTrend'] ?? 1,
      'stopLossPrice': params['stop_loss_price'] ?? params['stopLossPrice'],
      'lossTrend': params['stop_loss_trend'] ?? params['stopLossTrend'] ?? 1,
      'priceProtect': params['price_protect'] ?? params['priceProtect'] ?? 0,
      'reduceOnly': params['reduce_only'] ?? params['reduceOnly'] ?? false,
      'flashClose': params['flash_close'] ?? params['flashClose'],
    };

    payload.removeWhere((key, value) => value == null);

    return request(
      method: 'POST',
      apiType: 'futures',
      endpoint: '/private/order/create',
      data: payload,
    );
  }

  Future<Map<String, dynamic>> getFuturesTickers([
    Map<String, dynamic> params = const {},
  ]) async {
    return request(
      method: 'GET',
      apiType: 'futures',
      endpoint: '/contract/ticker',
      data: {'symbol': params['symbol']},
    );
  }

  Future<Map<String, dynamic>> getFuturesPendingOrders([
    Map<String, dynamic> params = const {},
  ]) async {
    if (params['symbol'] != null) {
      return request(
        method: 'GET',
        apiType: 'futures',
        endpoint: '/private/order/list/open_orders/${params['symbol']}',
        data: {
          'page_num': params['pageNum'] ?? params['page_num'] ?? 1,
          'page_size': params['pageSize'] ?? params['page_size'] ?? 20,
        },
      );
    }

    return request(
      method: 'GET',
      apiType: 'futures',
      endpoint: '/private/order/list/open_orders/',
      data: {
        'page_num': params['pageNum'] ?? params['page_num'] ?? 1,
        'page_size': params['pageSize'] ?? params['page_size'] ?? 20,
      },
    );
  }

  Future<Map<String, dynamic>> cancelAllFuturesOrders([
    Map<String, dynamic> params = const {},
  ]) async {
    return request(
      method: 'POST',
      apiType: 'futures',
      endpoint: '/private/order/cancel_all',
      data: {'symbol': params['symbol']},
    );
  }

  Future<Map<String, dynamic>> getFuturesAssets([
    Map<String, dynamic> params = const {},
  ]) async {
    String endpoint;

    if (params['currency'] != null &&
        (params['currency'] as String).isNotEmpty) {
      endpoint = '/private/account/asset/${params['currency']}';
    } else {
      endpoint = '/private/account/assets';
    }

    return request(
      method: 'GET',
      apiType: 'futures',
      endpoint: endpoint,
      data: params,
    );
  }

  Future<Map<String, dynamic>> cancelFuturesOrderWithExternalId(
    Map<String, dynamic> params,
  ) async {
    if (params['symbol'] == null) {
      return createErrorResponse(400, 'Symbol is required');
    }

    if (params['external_id'] == null && params['externalId'] == null) {
      return createErrorResponse(400, 'External ID is required');
    }

    return request(
      method: 'POST',
      apiType: 'futures',
      endpoint: '/private/order/cancel_with_external',
      data: {
        'symbol': params['symbol'],
        'externalOid': params['external_id'] ?? params['externalId'],
      },
    );
  }

  // Дополнительные методы, которые могут быть полезны
  Future<Map<String, dynamic>> getFuturesAssetTransferRecords([
    Map<String, dynamic> params = const {},
  ]) async {
    return request(
      method: 'GET',
      apiType: 'futures',
      endpoint: '/private/account/transfer_record',
      data: {
        'currency': params['currency'],
        'state': params['state'],
        'type': params['type'],
        'page_num': params['pageNum'] ?? params['page_num'] ?? 1,
        'page_size': params['pageSize'] ?? params['page_size'] ?? 20,
      },
    );
  }

  Future<Map<String, dynamic>> getFuturesAnalysis([
    Map<String, dynamic> params = const {},
  ]) async {
    final now = DateTime.now();
    final startTime =
        params['startTime'] ??
        params['start_time'] ??
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endTime =
        params['endTime'] ??
        params['end_time'] ??
        DateTime(
          now.year,
          now.month,
          now.day,
          23,
          59,
          59,
          999,
        ).millisecondsSinceEpoch;

    return request(
      method: 'POST',
      apiType: 'futures',
      endpoint: '/private/account/asset/analysis/v3',
      data: {
        'currency': params['currency'] ?? 'USDT',
        'symbol': params['symbol'],
        'includeUnrealisedPnl':
            params['includeUnrealisedPnl'] ??
            params['include_unrealised_pnl'] ??
            1,
        'reverse': params['reverse'] ?? 0,
        'startTime': startTime,
        'endTime': endTime,
      },
    );
  }

  Future<Map<String, dynamic>> getFuturesOrdersDeals(
    Map<String, dynamic> params,
  ) async {
    if (params['symbol'] == null) {
      return createErrorResponse(400, 'Symbol is required');
    }

    final now = DateTime.now();
    final startTime =
        params['startTime'] ??
        params['start_time'] ??
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endTime =
        params['endTime'] ??
        params['end_time'] ??
        DateTime(
          now.year,
          now.month,
          now.day,
          23,
          59,
          59,
          999,
        ).millisecondsSinceEpoch;

    return request(
      method: 'GET',
      apiType: 'futures',
      endpoint: '/private/order/list/order_deals',
      data: {
        'symbol': params['symbol'],
        'start_time': startTime,
        'end_time': endTime,
        'page_num': params['pageNum'] ?? params['page_num'] ?? 1,
        'page_size': params['pageSize'] ?? params['page_size'] ?? 20,
      },
    );
  }

  Future<Map<String, dynamic>> getFuturesOpenPositions([
    Map<String, dynamic> params = const {},
  ]) async {
    return request(
      method: 'GET',
      apiType: 'futures',
      endpoint: '/private/position/open_positions',
      data: {'symbol': params['symbol']},
    );
  }

  Future<Map<String, dynamic>> getFuturesPositionsHistory([
    Map<String, dynamic> params = const {},
  ]) async {
    return request(
      method: 'GET',
      apiType: 'futures',
      endpoint: '/private/position/list/history_positions',
      data: {
        'symbol': params['symbol'],
        'type': params['type'],
        'page_num': params['pageNum'] ?? params['page_num'] ?? 1,
        'page_size': params['pageSize'] ?? params['page_size'] ?? 20,
      },
    );
  }

  Future<Map<String, dynamic>> closeAllFuturesPositions() async {
    return request(
      method: 'POST',
      apiType: 'futures',
      endpoint: '/private/position/close_all',
    );
  }

  Future<Map<String, dynamic>> getFuturesOpenLimitOrders([
    Map<String, dynamic> params = const {},
  ]) async {
    return request(
      method: 'GET',
      apiType: 'futures',
      endpoint: '/private/order/list/open_orders',
      data: {'page_size': params['pageSize'] ?? params['page_size'] ?? 200},
    );
  }

  Future<Map<String, dynamic>> getFuturesTicker(
    Map<String, dynamic> params,
  ) async {
    if (params['symbol'] == null) {
      return createErrorResponse(400, 'Symbol is required');
    }

    return request(
      method: 'GET',
      apiType: 'futures',
      endpoint: '/contract/ticker',
      data: {'symbol': params['symbol']},
    );
  }

  Future<Map<String, dynamic>> cancelFuturesOrders(
    Map<String, dynamic> params,
  ) async {
    if (params['ids'] == null) {
      return createErrorResponse(400, 'Order IDs are required');
    }

    List<String> ids;
    if (params['ids'] is String) {
      ids = (params['ids'] as String)
          .split(',')
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toList();
    } else if (params['ids'] is List<String>) {
      ids = params['ids'] as List<String>;
    } else {
      return createErrorResponse(400, 'Invalid order IDs format');
    }

    // Создаем Map с ключом 'orderIds' как ожидает API
    final payload = {'orderIds': ids};

    return request(
      method: 'POST',
      apiType: 'futures',
      endpoint: '/private/order/cancel',
      data: payload,
    );
  }

  Future<Map<String, dynamic>> getFuturesOrdersById(
    Map<String, dynamic> params,
  ) async {
    if (params['ids'] == null) {
      return createErrorResponse(400, 'Order IDs are required');
    }

    final ids = (params['ids'] as String)
        .split(',')
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();

    if (ids.length > 1) {
      return request(
        method: 'GET',
        apiType: 'futures',
        endpoint: '/private/order/batch_query',
        data: {'order_ids': params['ids']},
      );
    } else {
      return request(
        method: 'GET',
        apiType: 'futures',
        endpoint: '/private/order/get/${ids.first}',
      );
    }
  }

  // Добавьте остальные методы аналогичным образом...
}
