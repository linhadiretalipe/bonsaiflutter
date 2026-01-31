import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/security_provider.dart';

class LockScreen extends ConsumerStatefulWidget {
  final Widget child;

  const LockScreen({super.key, required this.child});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen>
    with WidgetsBindingObserver {
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Attempt authentication on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndAuthenticate();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final security = ref.read(securityProvider);
    if (state == AppLifecycleState.resumed &&
        security.value?.biometricEnabled == true) {
      // Re-authenticate when app comes back to foreground
      if (!security.value!.isUnlocked) {
        _checkAndAuthenticate();
      }
    } else if (state == AppLifecycleState.paused) {
      // Lock when app goes to background
      ref.read(securityProvider.notifier).lock();
    }
  }

  Future<void> _checkAndAuthenticate() async {
    final security = ref.read(securityProvider);
    if (security.value?.biometricEnabled == true &&
        security.value?.isUnlocked == false) {
      await _authenticate();
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() => _isAuthenticating = true);

    try {
      await ref.read(securityProvider.notifier).authenticate();
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final securityAsync = ref.watch(securityProvider);

    return securityAsync.when(
      data: (security) {
        // If biometric not enabled or already unlocked, show child
        if (!security.biometricEnabled || security.isUnlocked) {
          return widget.child;
        }

        // Show lock screen
        return Scaffold(
          backgroundColor: AppTheme.darkBackground,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Bonsai Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface,
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        size: 60,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Bonsai Wallet',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Authenticate to access your wallet',
                      style: TextStyle(fontSize: 16, color: Colors.white54),
                    ),
                    const SizedBox(height: 48),

                    // Unlock Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isAuthenticating ? null : _authenticate,
                        icon: _isAuthenticating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(Icons.fingerprint, size: 28),
                        label: Text(
                          _isAuthenticating
                              ? 'Authenticating...'
                              : 'Unlock with Biometrics',
                          style: const TextStyle(fontSize: 16),
                        ),
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
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => widget.child, // On error, show child
    );
  }
}
