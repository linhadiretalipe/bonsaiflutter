import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../data/repositories/real_wallet_repository.dart';

// The repository provider (singleton)
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return RealWalletRepository();
});

// A provider that manages the list of transactions
final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<UserTransaction>>(() {
      return TransactionsNotifier();
    });

class TransactionsNotifier extends AsyncNotifier<List<UserTransaction>> {
  late WalletRepository _repository;

  @override
  Future<List<UserTransaction>> build() async {
    _repository = ref.read(walletRepositoryProvider);
    return _repository.getTransactions();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getTransactions());
  }

  Future<void> sendTransaction(double amountBtc, String address) async {
    // Optimistic update or wait for repository?
    // For this mock, we wait for repository to simulate network call
    await _repository.sendTransaction(amountBtc, address);
    // Refresh list to pull the new transaction
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
