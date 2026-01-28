import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_theme.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  // Placeholder address
  String _address = "2Mx1KKNGZkRPuvX...mEDYuDyQSwwXrS4";
  String _fullAddress = "2Mx1KKNGZkRPuvXmEDYuDyQSwwXrS4";
  bool _isAddressSelected = true;

  void _generateNewAddress() {
    setState(() {
      // Mock logic to simulate generating a new address
      // In a real app, this would call the Rust bridge
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _fullAddress = "bc1q${timestamp}mockaddress...new";
      _address =
          "${_fullAddress.substring(0, 15)}...${_fullAddress.substring(_fullAddress.length - 10)}";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("New address generated"),
        duration: Duration(seconds: 1),
        backgroundColor: AppTheme.darkSurface,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text(
          'Receive BTC',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            // Toggle Button
            Container(
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToggleOption(
                    label: "Address",
                    isSelected: _isAddressSelected,
                    onTap: () => setState(() => _isAddressSelected = true),
                  ),
                  _buildToggleOption(
                    label: "Link",
                    isSelected: !_isAddressSelected,
                    onTap: () => setState(() => _isAddressSelected = false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // QR Code Container
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: QrImageView(
                data: _fullAddress,
                version: QrVersions.auto,
                size: 260.0,
                backgroundColor: Colors.white,
                errorCorrectionLevel:
                    QrErrorCorrectLevel.H, // High correction for logo embedding
                embeddedImage: const AssetImage('assets/icon/bonsai-dark.png'),
                embeddedImageStyle: const QrEmbeddedImageStyle(
                  size: Size(60, 60),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Address Section
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "ADDRESS",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _copyAddress,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _address,
                        style: const TextStyle(
                          fontFamily: 'Berkeley Mono',
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.copy_outlined,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Labels Section
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "LABELS",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Select or type label",
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _generateNewAddress,
                icon: const Icon(Icons.refresh, color: AppTheme.primaryGreen),
                label: const Text('Generate New Address'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
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

  Widget _buildToggleOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white54,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _copyAddress() {
    Clipboard.setData(ClipboardData(text: _fullAddress));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Address copied to clipboard"),
        duration: Duration(seconds: 2),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }
}
