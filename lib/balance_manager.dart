// balance_manager.dart

import 'package:scalpx3/entities/asset_snapshot.dart';
import 'package:scalpx3/interface/i_exchange_api.dart';

class BalanceManager {
  final IExchangeApi _api;
  AssetSnapshot? _currentBalance;
  DateTime? _lastUpdate;

  BalanceManager({required IExchangeApi api}) : _api = api;

  // Получить текущий баланс (кешированный)
  AssetSnapshot? get currentBalance => _currentBalance;
  DateTime? get lastUpdate => _lastUpdate;

  // Загрузить баланс при запуске
  Future<void> loadInitialBalance() async {
    try {
      print('[BALANCE] Loading initial balance...');

      final futuresAssets = await _api.getFuturesAssets('USDT');

      _currentBalance = AssetSnapshot(
        currency: futuresAssets.currency,
        availableBalance: futuresAssets.availableBalance,
      );

      _lastUpdate = DateTime.now();

      print(
        '[BALANCE] Initial balance loaded: ${_currentBalance!.toFormattedString()}',
      );
    } catch (e) {
      print('[BALANCE_ERROR] Failed to load initial balance: $e');
      rethrow;
    }
  }

  // Обновить баланс из WebSocket
  void updateFromWebSocket(AssetSnapshot assetSnapshot) {
    if (assetSnapshot.currency == 'USDT') {
      _currentBalance = assetSnapshot;
      _lastUpdate = DateTime.now();

      print('[BALANCE_UPDATE] Balance updated from WebSocket');
      print(assetSnapshot.toFormattedString());
    }
  }

  // Проверить достаточно ли средств для торговли
  bool hasSufficientBalance(double requiredAmount) {
    if (_currentBalance == null) {
      print('[BALANCE_WARNING] Balance not loaded yet');
      return false;
    }

    final hasEnough = _currentBalance!.availableBalance >= requiredAmount;

    if (!hasEnough) {
      print(
        '[BALANCE_INSUFFICIENT] Required: $requiredAmount, Available: ${_currentBalance!.availableBalance}',
      );
    }

    return hasEnough;
  }

  // Получить доступный баланс для торговли
  double get availableBalance => _currentBalance?.availableBalance ?? 0.0;

  @override
  String toString() {
    return _currentBalance?.toFormattedString() ?? 'Balance not loaded';
  }
}
