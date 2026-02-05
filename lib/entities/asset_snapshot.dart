// asset_snapshot.dart

class AssetSnapshot {
  final String currency;
  final double availableBalance;

  AssetSnapshot({required this.currency, required this.availableBalance});

  factory AssetSnapshot.fromJson(Map<String, dynamic> json) {
    return AssetSnapshot(
      currency: (json['currency'] ?? '') as String,
      availableBalance: ((json['availableBalance'] ?? 0) as num).toDouble(),
    );
  }

  @override
  String toString() {
    return 'AssetSnapshot{'
        'currency: $currency, '
        'available: ${availableBalance.toStringAsFixed(6)}, '
        '}';
  }

  String toFormattedString() {
    return '''
💰 Asset Snapshot ($currency)
   💵 Available: ${availableBalance.toStringAsFixed(6)}
''';
  }
}
