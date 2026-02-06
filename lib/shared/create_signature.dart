// import 'dart:convert';
// import 'package:crypto/crypto.dart';
// import 'package:web3dart/web3dart.dart';

// // Пример с использованием пакета web3dart
// Future<Map<String, String>> createSignature(
//   String message,
//   String privateKeyHex,
// ) async {
//   // 1. Хэшируем сообщение (предполагая, что Hyperliquid использует keccak256)
//   List<int> messageBytes = utf8.encode(message);
//   List<int> messageHash = keccak256.call();

//   // 2. Создаем объект EthPrivateKey из HEX-строки приватного ключа
//   Credentials credentials = EthPrivateKey.fromHex(privateKeyHex);

//   // 3. Подписываем хэш
//   // Метод sign может требовать преобразования хэша. Уточните в документации пакета.
//   MsgSignature sig = await credentials.signToSignature(
//     messageHash,
//     chainId: null,
//   );

//   // 4. Разбиваем подпись на компоненты r, s, v
//   return {
//     'r': '0x' + sig.r.toRadixString(16).padLeft(64, '0'),
//     's': '0x' + sig.s.toRadixString(16).padLeft(64, '0'),
//     'v': '0x' + (sig.v + 27).toRadixString(16), // V часто смещается на 27
//   };
// }
