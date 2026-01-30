import '../models/transaction_model.dart';

abstract class WalletRepository {
  Future<List<UserTransaction>> getTransactions();
  Future<void> sendTransaction(double amountBtc, String address);
  Future<void> receiveTransaction(double amountBtc);
  Future<double> getBalance();
}
