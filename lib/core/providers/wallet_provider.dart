import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../data/repositories/real_wallet_repository.dart';
import '../../src/rust/api.dart' as api;

// The repository provider (singleton)
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return RealWalletRepository();
});

// A provider that manages the list of transactions with auto-sync
final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<UserTransaction>>(() {
      return TransactionsNotifier();
    });

class TransactionsNotifier extends AsyncNotifier<List<UserTransaction>> {
  late WalletRepository _repository;
  Timer? _syncTimer;
  static const _syncIntervalSeconds = 30;

  @override
  Future<List<UserTransaction>> build() async {
    _repository = ref.read(walletRepositoryProvider);

    // Start auto-sync timer when node is running
    _startAutoSync();

    // Clean up timer when notifier is disposed
    ref.onDispose(() {
      _syncTimer?.cancel();
    });

    return _repository.getTransactions();
  }

  void _startAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(Duration(seconds: _syncIntervalSeconds), (
      _,
    ) async {
      // Only sync if node is running
      final isRunning = await api.isNodeRunning();
      if (isRunning) {
        await _silentRefresh();
      }
    });
  }

  /// Refresh without setting loading state (silent background refresh)
  Future<void> _silentRefresh() async {
    final newTxs = await _repository.getTransactions();
    // Only update if state is not loading
    if (state is! AsyncLoading) {
      state = AsyncValue.data(newTxs);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getTransactions());
  }

  Future<void> sendTransaction(double amountBtc, String address) async {
    await _repository.sendTransaction(amountBtc, address);
    await refresh();
  }
}

// A provider for the balance
final balanceProvider = FutureProvider<double>((ref) async {
  final repository = ref.read(walletRepositoryProvider);
  // Watch transactions to auto-update balance
  ref.watch(transactionsProvider);
  return repository.getBalance();
});
