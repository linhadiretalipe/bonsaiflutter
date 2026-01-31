import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/transaction_model.dart';

class TransactionDetailScreen extends StatelessWidget {
  final UserTransaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isReceived = transaction.type == TransactionType.received;
    final statusColor = transaction.isConfirmed
        ? AppTheme.primaryGreen
        : Colors.amber;
    final statusText = transaction.isConfirmed ? 'Confirmed' : 'Pending';

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text(
          'Transaction Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isReceived
                          ? AppTheme.primaryGreen.withOpacity(0.2)
                          : Colors.redAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(36),
                    ),
                    child: Icon(
                      isReceived ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isReceived
                          ? AppTheme.primaryGreen
                          : Colors.redAccent,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${isReceived ? '+' : '-'}${transaction.amountBtc.toStringAsFixed(8)} BTC',
                    style: TextStyle(
                      color: isReceived
                          ? AppTheme.primaryGreen
                          : Colors.redAccent,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Berkeley Mono',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          transaction.isConfirmed
                              ? Icons.check_circle
                              : Icons.access_time,
                          color: statusColor,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Details Section
            _buildDetailSection(
              'Transaction ID',
              transaction.id,
              isCopyable: true,
            ),
            _buildDetailSection('Type', isReceived ? 'Received' : 'Sent'),
            _buildDetailSection('Date', _formatDate(transaction.date)),
            if (transaction.confirmationHeight != null)
              _buildDetailSection(
                'Block Height',
                '${transaction.confirmationHeight}',
              ),

            const SizedBox(height: 32),

            // View on Explorer Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Open in block explorer
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Opening block explorer...'),
                      backgroundColor: AppTheme.darkSurface,
                    ),
                  );
                },
                icon: const Icon(
                  Icons.open_in_new,
                  color: AppTheme.primaryGreen,
                ),
                label: const Text(
                  'View on Block Explorer',
                  style: TextStyle(color: AppTheme.primaryGreen),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryGreen),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(
    String label,
    String value, {
    bool isCopyable = false,
  }) {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Berkeley Mono',
                    ),
                  ),
                ),
                if (isCopyable)
                  IconButton(
                    icon: const Icon(
                      Icons.copy,
                      color: AppTheme.primaryGreen,
                      size: 20,
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied to clipboard'),
                          backgroundColor: AppTheme.darkSurface,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
