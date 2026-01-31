import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/security_provider.dart';
import '../../src/rust/api.dart' as api;

class RecoveryPhraseViewScreen extends ConsumerStatefulWidget {
  const RecoveryPhraseViewScreen({super.key});

  @override
  ConsumerState<RecoveryPhraseViewScreen> createState() =>
      _RecoveryPhraseViewScreenState();
}

class _RecoveryPhraseViewScreenState
    extends ConsumerState<RecoveryPhraseViewScreen> {
  bool _isAuthenticated = false;
  List<String> _mnemonic = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Delay slightly to allow transition to finish before prompting auth
    Future.delayed(const Duration(milliseconds: 300), _authenticate);
  }

  Future<void> _authenticate() async {
    final securityNotifier = ref.read(securityProvider.notifier);
    final isAuthenticated = await securityNotifier.authenticate();

    if (isAuthenticated && mounted) {
      setState(() {
        _isAuthenticated = true;
      });
      _loadMnemonic();
    } else if (mounted) {
      // If auth fails/cancelled, go back
      Navigator.of(context).pop();
    }
  }

  Future<void> _loadMnemonic() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final phrase = await api.getWalletMnemonic(dataDir: appDir.path);

      if (phrase != null && mounted) {
        setState(() {
          _mnemonic = phrase.split(' ');
          _isLoading = false;
        });
      } else if (mounted) {
        // Handle error (no mnemonic found)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No recovery phrase found')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading mnemonic: $e')));
      }
    }
  }

  void _copyToClipboard() {
    if (_mnemonic.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _mnemonic.join(' ')));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recovery phrase copied to clipboard'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Recovery Phrase'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: !_isAuthenticated || _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text(
                    'Write down these 12 words',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Keep this phrase safe. Anyone with these words can access your wallet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 32),

                  // Mnemonic Grid
                  Expanded(
                    child: GridView.builder(
                      itemCount: _mnemonic.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 3.5,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemBuilder: (context, index) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.darkSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${index + 1}.',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _mnemonic[index],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Warning Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Never share these words with anyone.',
                            style: TextStyle(color: Colors.amber),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Copy Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _copyToClipboard,
                      icon: const Icon(
                        Icons.copy,
                        color: AppTheme.primaryGreen,
                      ),
                      label: const Text('Copy to Clipboard'),
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
}
