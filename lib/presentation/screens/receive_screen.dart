import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../src/rust/api.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  String _address = "";
  bool _isLoading = true;
  bool _isAddressSelected = true;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    setState(() => _isLoading = true);
    final info = await getWalletInfo();
    if (info != null && mounted) {
      setState(() {
        _address = info.address;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateNewAddress() async {
    setState(() => _isLoading = true);

    // Calling getWalletInfo reveals next address internally
    final info = await getWalletInfo();
    if (info != null && mounted) {
      setState(() {
        _address = info.address;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("New address generated"),
          duration: Duration(seconds: 1),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String get _displayAddress {
    if (_address.isEmpty) return "Loading...";
    if (_address.length > 20) {
      return "${_address.substring(0, 12)}...${_address.substring(_address.length - 8)}";
    }
    return _address;
  }

  String get _qrData {
    if (_isAddressSelected) {
      return _address;
    } else {
      // Bitcoin URI format
      return "bitcoin:$_address";
    }
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
            // Toggle Button (Address / Link)
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
              child: _isLoading || _address.isEmpty
                  ? const SizedBox(
                      width: 260,
                      height: 260,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    )
                  : QrImageView(
                      data: _qrData,
                      version: QrVersions.auto,
                      size: 260.0,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                      embeddedImage: const AssetImage(
                        'assets/icon/bonsai-dark.png',
                      ),
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
                "YOUR ADDRESS",
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
                        _displayAddress,
                        style: const TextStyle(
                          fontFamily: 'Berkeley Mono',
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.copy_outlined,
                        color: AppTheme.primaryGreen,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Full address display (small text)
            if (_address.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _address,
                  style: const TextStyle(
                    fontFamily: 'Berkeley Mono',
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 24),

            // Generate New Address Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _generateNewAddress,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryGreen,
                        ),
                      )
                    : const Icon(Icons.refresh, color: AppTheme.primaryGreen),
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

            const SizedBox(height: 16),

            // Share Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _address.isEmpty ? null : _shareAddress,
                icon: const Icon(Icons.share, color: Colors.black),
                label: const Text('Share Address'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.black,
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
    if (_address.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _address));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Address copied to clipboard"),
        duration: Duration(seconds: 2),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  void _shareAddress() {
    // For now, just copy to clipboard
    // Could integrate with share_plus package for native sharing
    _copyAddress();
  }
}
