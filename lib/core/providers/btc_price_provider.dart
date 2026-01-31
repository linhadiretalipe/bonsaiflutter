import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Provider for the current BTC price in USD
final btcPriceProvider = AsyncNotifierProvider<BtcPriceNotifier, double>(() {
  return BtcPriceNotifier();
});

class BtcPriceNotifier extends AsyncNotifier<double> {
  static const _apiUrl =
      'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd';

  @override
  Future<double> build() async {
    return _fetchPrice();
  }

  Future<double> _fetchPrice() async {
    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['bitcoin']['usd'] as num).toDouble();
      } else {
        // Fallback to a reasonable estimate if API fails
        return 43000.0;
      }
    } catch (e) {
      // Use fallback price on error
      return 43000.0;
    }
  }

  /// Refresh the price
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPrice());
  }
}

/// Provider for formatted fiat value given BTC amount
final fiatValueProvider = Provider.family<String, double>((ref, btcAmount) {
  final priceAsync = ref.watch(btcPriceProvider);
  return priceAsync.when(
    data: (price) {
      final fiatValue = btcAmount * price;
      return '\$${_formatNumber(fiatValue)}';
    },
    loading: () => '...',
    error: (_, __) => '--',
  );
});

String _formatNumber(double value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(2)}M';
  } else if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(2)}K';
  } else {
    return value.toStringAsFixed(2);
  }
}
