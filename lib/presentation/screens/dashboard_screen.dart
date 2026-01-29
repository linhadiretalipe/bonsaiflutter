import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'receive_screen.dart';
import 'send_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // Mock Data for Transactions
  List<Map<String, dynamic>> _transactions = [
    {
      'id': '1',
      'type': 'received',
      'amount': '+0.005 BTC',
      'date': 'Today, 10:23 AM',
    },
    {
      'id': '2',
      'type': 'sent',
      'amount': '-0.001 BTC',
      'date': 'Yesterday, 4:15 PM',
    },
    {
      'id': '3',
      'type': 'received',
      'amount': '+0.050 BTC',
      'date': 'Jan 24, 9:00 AM',
    },
    {
      'id': '4',
      'type': 'sent',
      'amount': '-0.0025 BTC',
      'date': 'Jan 22, 2:30 PM',
    },
    {
      'id': '5',
      'type': 'received',
      'amount': '+0.010 BTC',
      'date': 'Jan 20, 11:45 AM',
    },
  ];

  @override
  Widget build(BuildContext context) {
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
                    const Text(
                      '1.240567 BTC',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '≈ \$54,320.00 USD',
                      style: TextStyle(
                        color: AppTheme.secondaryGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
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
                              // Check if a transaction was sent
                              if (result != null &&
                                  result is Map &&
                                  result['success'] == true) {
                                final amountSats =
                                    int.tryParse(result['amountSats'] ?? '0') ??
                                    0;
                                final double amountBtc =
                                    amountSats / 100000000.0;

                                // Add a mock 'sent' transaction to the top of the list
                                setState(() {
                                  _transactions.insert(0, {
                                    'id': DateTime.now().millisecondsSinceEpoch
                                        .toString(),
                                    'type': 'sent',
                                    'amount':
                                        '-${amountBtc.toStringAsFixed(8)} BTC',
                                    'date': 'Just now',
                                    'isNew': true,
                                  });
                                });
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
                child: ListView.separated(
                  itemCount: _transactions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final tx = _transactions[index];
                    return TransactionItem(
                      key: ValueKey(tx['id']),
                      data: tx,
                      isNew: tx['isNew'] ?? false,
                    );
                  },
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
