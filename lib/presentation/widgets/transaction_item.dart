import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/transaction_model.dart';
import '../screens/transaction_detail_screen.dart';

class TransactionItem extends StatefulWidget {
  final UserTransaction transaction;
  final VoidCallback? onTap;

  const TransactionItem({super.key, required this.transaction, this.onTap});

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

    if (widget.transaction.isNew) {
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
    final isReceived = widget.transaction.type == TransactionType.received;
    final dateStr =
        '${widget.transaction.date.day}/${widget.transaction.date.month}/${widget.transaction.date.year}';
    final amountStr = isReceived
        ? '+${widget.transaction.amountBtc.toStringAsFixed(8)} BTC'
        : '-${widget.transaction.amountBtc.toStringAsFixed(8)} BTC';

    return GestureDetector(
      onTap:
          widget.onTap ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    TransactionDetailScreen(transaction: widget.transaction),
              ),
            );
          },
      child: AnimatedBuilder(
        animation: _colorAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _colorAnimation.value,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                    dateStr,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              amountStr,
              style: TextStyle(
                color: isReceived ? AppTheme.primaryGreen : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
