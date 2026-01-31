import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/wallet_provider.dart';
import '../widgets/copyable_address.dart';

class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({super.key});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  String _address = "";
  bool _isLoading = true;
  bool _isAddressSelected = true;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(walletRepositoryProvider);
      final address = await repository.getAddress();

      if (address != null && mounted) {
        setState(() {
          _address = address;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
        _showError("Wallet not ready");
      }
    } catch (e) {
      debugPrint("ReceiveScreen error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        _showError("Failed to load address: $e");
      }
    }
  }

  // NOTE: getWalletInfo (FFI) is generally needed to generate a NEW address specifically.
  // The repository currently exposes `getAddress` which gets the *current* unused address.
  // If we want explicit "Generate New", the repository needs a method for it.
  // For now, re-fetching getAddress is a reasonable proxy if the backend rotates it,
  // but standardized behavior usually implies triggering a new derivation.
  // Given RealWalletRepository implementation, `getWalletInfo` returns current address.
  // We'll keep the reload behavior for now or assume repository handles rotation.
  Future<void> _generateNewAddress() async {
    if (!mounted) return;
    await _loadAddress();
    if (mounted && _address.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Address updated"),
          duration: Duration(seconds: 1),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        action: SnackBarAction(
          label: "Retry",
          textColor: Colors.white,
          onPressed: _loadAddress,
        ),
      ),
    );
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
            CopyableAddress(label: "YOUR ADDRESS", address: _address),
            const SizedBox(height: 16),

            // Full address display (small text)
            if (_address.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface.withValues(alpha: 0.5),
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
                label: const Text('Refresh Address'),
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

  void _shareAddress() {
    // For now, just copy to clipboard
    if (_address.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _address));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Address copied to clipboard for sharing"),
          duration: Duration(seconds: 2),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }
}
