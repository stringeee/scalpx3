// config_loader.dart

import 'dart:convert';
import 'dart:io';

import 'package:scalpx3/entities/config_model.dart';

class ConfigLoader {
  static Future<ProfileConfig> loadConfig(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('[CONFIG] Config file not found: $filePath');
        return _createDefaultConfig();
      }

      final contents = await file.readAsString();
      final jsonData = json.decode(contents);

      final config = ProfileConfig.fromJson(jsonData);
      print('[CONFIG] ✅ Config loaded successfully: $config');

      return config;
    } catch (e) {
      print('[CONFIG] ❌ Error loading config: $e');
      print('[CONFIG] Using default configuration');
      return _createDefaultConfig();
    }
  }

  static Future<void> saveConfig(ProfileConfig config, String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = json.encode(config.toJson());
      await file.writeAsString(jsonString);
      print('[CONFIG] ✅ Config saved to: $filePath');
    } catch (e) {
      print('[CONFIG] ❌ Error saving config: $e');
    }
  }

  static ProfileConfig _createDefaultConfig() {
    return ProfileConfig(
      user: '',
      nativeMexcApiKey: '',
      secretKey: '',
      webKey: '',
      binance: BinanceConfig(
        useBinance: false,
        binanceTakeProfit: 15.0,
        binanceBalanceUsage: 0.09,
      ),
      hyperLiquid: HyperLiquidConfig(
        useHyperLiquid: true,
        hlTakeProfit: 20.0,
        hlBalanceUsage: 0.1,
      ),
    );
  }

  static ProfileConfig createEmptyConfig() {
    return _createDefaultConfig();
  }
}
