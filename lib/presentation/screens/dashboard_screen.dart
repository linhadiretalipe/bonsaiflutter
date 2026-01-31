import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/wallet_provider.dart';
import '../../domain/models/transaction_model.dart';
import 'receive_screen.dart';
import 'send_screen.dart';
import 'transaction_detail_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final balanceAsync = ref.watch(balanceProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header / User Greeting
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                      Text(
                        'Bitcoiner',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          // Trigger wallet sync
                          await ref
                              .read(transactionsProvider.notifier)
                              .refresh();
                          ref.invalidate(balanceProvider);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.darkSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.sync, color: Colors.white),
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.darkSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryGreen.withOpacity(0.2),
                      AppTheme.darkSurface,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Balance',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    balanceAsync.when(
                      data: (balance) => Text(
                        '${balance.toStringAsFixed(6)} BTC',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1.0,
                        ),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (err, stack) => const Text(
                        'Error',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    balanceAsync.when(
                      data: (balance) => Text(
                        '≈ \$${(balance * 43000).toStringAsFixed(2)} USD', // Mock conversion
                        style: const TextStyle(
                          color: AppTheme.secondaryGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SendScreen(),
                                ),
                              );

                              // Check if a transaction was sent
                              if (result != null &&
                                  result is Map &&
                                  result['success'] == true) {
                                final amountSats =
                                    int.tryParse(result['amountSats'] ?? '0') ??
                                    0;
                                final double amountBtc =
                                    amountSats / 100000000.0;
                                final address = result['address'] ?? '';

                                // Call the provider to send transaction
                                // The provider handles adding it to the repo and refreshing the list
                                await ref
                                    .read(transactionsProvider.notifier)
                                    .sendTransaction(amountBtc, address);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              elevation: 0,
                            ),
                            child: const Text('Send'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ReceiveScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.black,
                              elevation: 0,
                            ),
                            child: const Text('Receive'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Transactions Header
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'View All',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Recent Transactions List
              Expanded(
                child: transactionsAsync.when(
                  data: (transactions) => ListView.separated(
                    itemCount: transactions.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      // Calculate string amount
                      final sign = tx.type == TransactionType.received
                          ? '+'
                          : '-';
                      final amountStr =
                          '$sign${tx.amountBtc.toStringAsFixed(8)} BTC';

                      // Format Date simply for now
                      final dateStr =
                          "${tx.date.day}/${tx.date.month} ${tx.date.hour}:${tx.date.minute}";

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  TransactionDetailScreen(transaction: tx),
                            ),
                          );
                        },
                        child: TransactionItem(
                          key: ValueKey(tx.id),
                          data: {
                            'type': tx.type == TransactionType.received
                                ? 'received'
                                : 'sent',
                            'amount': amountStr,
                            'date': dateStr,
                          },
                          isNew: tx.isNew,
                        ),
                      );
                    },
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(
                    child: Text(
                      'Error: $err',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TransactionItem extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isNew;

  const TransactionItem({super.key, required this.data, this.isNew = false});

  @override
  State<TransactionItem> createState() => _TransactionItemState();
}

class _TransactionItemState extends State<TransactionItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Oscillation between darkSurface and a slightly lighter/tinted color
    _colorAnimation = ColorTween(
      begin: AppTheme.darkSurface,
      end: AppTheme.primaryGreen.withOpacity(0.15),
    ).animate(_controller);

    if (widget.isNew) {
      _startAnimation();
    }
  }

  void _startAnimation() async {
    // Repeat oscillation
    _controller.repeat(reverse: true);

    // Stop after 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      _controller.stop();
      _controller.reset(); // Return to original color
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReceived = widget.data['type'] == 'received';
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _colorAnimation.value,
            borderRadius: BorderRadius.circular(16),
          ),
          child: child,
        );
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isReceived
                  ? AppTheme.primaryGreen.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isReceived ? Icons.arrow_downward : Icons.arrow_upward,
              color: isReceived ? AppTheme.primaryGreen : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isReceived ? 'Received Bitcoin' : 'Sent Bitcoin',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.data['date'],
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            widget.data['amount'],
            style: TextStyle(
              color: isReceived ? AppTheme.primaryGreen : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
