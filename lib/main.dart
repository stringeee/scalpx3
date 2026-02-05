import 'package:scalpx3/injector/injector.dart';
import 'package:scalpx3/shared/config_loader.dart';
import 'package:scalpx3/shared/program.dart';
import 'package:scalpx3/trade_bot.dart';

void main() async {
  configureDependencies();
  var config = await ConfigLoader.loadConfig('config.json');
  injector<Program>().setConfig(config);
  TradeBot bot = TradeBot();

  bot.connect();
}
