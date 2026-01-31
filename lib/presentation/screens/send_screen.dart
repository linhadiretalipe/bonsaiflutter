import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/btc_price_provider.dart';
import '../../src/rust/api.dart';
import '../widgets/fee_selector.dart';
import '../widgets/info_row.dart';
import '../widgets/qr_scanner_modal.dart';

class SendScreen extends ConsumerStatefulWidget {
  const SendScreen({super.key});

  @override
  ConsumerState<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends ConsumerState<SendScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;
  double _balance = 0;
  double _feeRate = 1.0; // Default fee rate in sats/vB

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final info = await getWalletInfo();
    if (info != null && mounted) {
      setState(() {
        _balance = info.balanceSats.toInt() / 100000000.0;
      });
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onSendPressed() {
    if (_addressController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter address and amount"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final amountSats = int.tryParse(_amountController.text) ?? 0;
    if (amountSats <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid amount"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    _showConfirmationDialog(amountSats);
  }

  void _showConfirmationDialog(int amountSats) {
    // Basic estimation: 140 vB for a standard P2WPKH transaction
    final estimatedFee = (140 * _feeRate).ceil();
    final totalSats = amountSats + estimatedFee;

    // Calculate USD values
    final btcPrice = ref.read(btcPriceProvider).value ?? 0.0;
    final amountUsd = (amountSats / 100000000) * btcPrice;
    final feeUsd = (estimatedFee / 100000000) * btcPrice;
    final totalUsd = (totalSats / 100000000) * btcPrice;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Confirm Transaction",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            InfoRow(label: "Recipient", value: _addressController.text),
            InfoRow(
              label: "Amount",
              value: "$amountSats sats\n(~\$${amountUsd.toStringAsFixed(2)})",
            ),
            InfoRow(
              label: "Est. Fee",
              value:
                  "$estimatedFee sats (${_feeRate.toStringAsFixed(1)} s/vB)\n(~\$${feeUsd.toStringAsFixed(2)})",
            ),
            const Divider(color: Colors.white10, height: 32),
            InfoRow(
              label: "Total",
              value: "$totalSats sats\n(~\$${totalUsd.toStringAsFixed(2)})",
              isTotal: true,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _sendTransaction(amountSats);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Confirm & Send",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendTransaction(int amountSats) async {
    setState(() => _isLoading = true);

    try {
      final result = await sendTransaction(
        address: _addressController.text.trim(),
        amountSats: BigInt.from(amountSats),
        feeRate: _feeRate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Transaction created! TXID: ${result.txid.substring(0, 8)}...",
            ),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        Navigator.pop(context, {'success': true, 'txid': result.txid});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text(
          'Send BTC',
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
            // Balance display
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Available Balance',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  Text(
                    '${_balance.toStringAsFixed(8)} BTC',
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Berkeley Mono',
                    ),
                  ),
                ],
              ),
            ),

            // Address Input
            const Text(
              "RECIPIENT ADDRESS",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Berkeley Mono',
              ),
              decoration: InputDecoration(
                hintText: "Enter Bitcoin address",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: AppTheme.darkSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryGreen),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.qr_code_scanner,
                    color: AppTheme.primaryGreen,
                  ),
                  onPressed: () async {
                    final result = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QrScannerModal(),
                      ),
                    );

                    if (result != null) {
                      setState(() {
                        // Basic parsing for bitcoin URI if needed 'bitcoin:address?amount=...'
                        String address = result;
                        if (address.toLowerCase().startsWith('bitcoin:')) {
                          address = address
                              .replaceAll(
                                RegExp(r'^bitcoin:', caseSensitive: false),
                                '',
                              )
                              .split('?')[0];
                        }
                        _addressController.text = address;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Amount Input
            const Text(
              "AMOUNT (SATS)",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Berkeley Mono',
              ),
              decoration: InputDecoration(
                hintText: "0",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: AppTheme.darkSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryGreen),
                ),
                suffixText: "sats",
                suffixStyle: const TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 24),

            // Fee Selection
            FeeSelector(
              currentFeeRate: _feeRate,
              onFeeSelected: (rate) {
                setState(() => _feeRate = rate);
              },
            ),

            const SizedBox(height: 48),

            // Send Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _onSendPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        "Review Transaction",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
