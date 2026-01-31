import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_theme.dart';
import '../../src/rust/api.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
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
            _buildInfoRow("Recipient", _addressController.text),
            _buildInfoRow("Amount", "$amountSats sats"),
            _buildInfoRow(
              "Est. Fee",
              "$estimatedFee sats (${_feeRate.toStringAsFixed(1)} s/vB)",
            ),
            const Divider(color: Colors.white10, height: 32),
            _buildInfoRow("Total", "$totalSats sats", isTotal: true),
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

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.white : Colors.white54,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: isTotal ? AppTheme.primaryGreen : Colors.white,
                fontFamily: 'Berkeley Mono',
                fontWeight: FontWeight.bold,
                fontSize: isTotal ? 18 : 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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

  Widget _buildFeeChip(String label, double rate) {
    final isSelected = _feeRate == rate;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _feeRate = rate);
        }
      },
      selectedColor: AppTheme.primaryGreen,
      backgroundColor: AppTheme.darkSurface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
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
                    // Open scanner in a modal or new route
                    bool isScanned = false;
                    final result = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Scaffold(
                          backgroundColor: Colors.black,
                          body: Stack(
                            children: [
                              MobileScanner(
                                onDetect: (capture) {
                                  if (isScanned) return;
                                  final List<Barcode> barcodes =
                                      capture.barcodes;
                                  for (final barcode in barcodes) {
                                    if (barcode.rawValue != null) {
                                      isScanned = true;
                                      if (context.mounted) {
                                        Navigator.of(
                                          context,
                                        ).pop(barcode.rawValue);
                                      }
                                      break;
                                    }
                                  }
                                },
                              ),

                              // Semi-transparent overlay with cut-out using ColorFiltered
                              ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withOpacity(0.5),
                                  BlendMode.srcOut,
                                ),
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black,
                                        backgroundBlendMode: BlendMode.dstOut,
                                      ),
                                    ),
                                    Center(
                                      child: Container(
                                        width: 250,
                                        height: 250,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Green Border
                              Center(
                                child: Container(
                                  width: 250,
                                  height: 250,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppTheme.primaryGreen,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                              // Title and Back Button
                              Positioned(
                                top: 50,
                                left: 20,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                              const Positioned(
                                top: 65,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Text(
                                    'Scan QR Code',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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
            const Text(
              "NETWORK FEE",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFeeChip("Slow", 1.0),
                _buildFeeChip("Medium", 10.0),
                _buildFeeChip("Fast", 50.0),
              ],
            ),
            if (_feeRate > 50) ...[
              const SizedBox(height: 16),
              Text(
                "Custom Fee: ${_feeRate.toStringAsFixed(1)} sats/vB",
                style: const TextStyle(
                  color: AppTheme.primaryGreen,
                  fontSize: 13,
                ),
              ),
            ],

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
