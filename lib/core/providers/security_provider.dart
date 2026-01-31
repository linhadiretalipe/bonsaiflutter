import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screen_protector/screen_protector.dart';

/// Keys for SharedPreferences
const _kBiometricEnabled = 'biometric_enabled';
const _kScreenProtectionEnabled = 'screen_protection_enabled';

/// Provider for LocalAuthentication instance
final localAuthProvider = Provider<LocalAuthentication>((ref) {
  return LocalAuthentication();
});

/// Provider for SharedPreferences
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return SharedPreferences.getInstance();
});

/// Provider that checks if device supports biometrics
final canCheckBiometricsProvider = FutureProvider<bool>((ref) async {
  final auth = ref.read(localAuthProvider);
  return await auth.canCheckBiometrics || await auth.isDeviceSupported();
});

/// Provider that checks available biometric types
final availableBiometricsProvider = FutureProvider<List<BiometricType>>((
  ref,
) async {
  final auth = ref.read(localAuthProvider);
  return await auth.getAvailableBiometrics();
});

/// Notifier for biometric security state
class SecurityNotifier extends AsyncNotifier<SecurityState> {
  @override
  Future<SecurityState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_kBiometricEnabled) ?? false;
    final isScreenProtectionEnabled =
        prefs.getBool(_kScreenProtectionEnabled) ?? true; // Default true

    final auth = ref.read(localAuthProvider);
    final canCheck =
        await auth.canCheckBiometrics || await auth.isDeviceSupported();

    // Initialize screen protection
    if (isScreenProtectionEnabled) {
      await ScreenProtector.protectDataLeakageOn();
      await ScreenProtector.preventScreenshotOn();
    } else {
      await ScreenProtector.protectDataLeakageOff();
      await ScreenProtector.preventScreenshotOff();
    }

    return SecurityState(
      biometricEnabled: isEnabled,
      screenProtectionEnabled: isScreenProtectionEnabled,
      deviceSupported: canCheck,
      isUnlocked: !isEnabled, // If not enabled, consider unlocked
    );
  }

  /// Toggle biometric authentication on/off
  Future<void> toggleBiometric(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBiometricEnabled, enabled);

    state = AsyncValue.data(
      state.value!.copyWith(
        biometricEnabled: enabled,
        isUnlocked: !enabled, // If disabling, unlock
      ),
    );
  }

  /// Toggle screen protection (screenshot/recording block)
  Future<void> toggleScreenProtection(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kScreenProtectionEnabled, enabled);

    if (enabled) {
      await ScreenProtector.protectDataLeakageOn();
      await ScreenProtector.preventScreenshotOn();
    } else {
      await ScreenProtector.protectDataLeakageOff();
      await ScreenProtector.preventScreenshotOff();
    }

    state = AsyncValue.data(
      state.value!.copyWith(screenProtectionEnabled: enabled),
    );
  }

  /// Authenticate with biometrics
  Future<bool> authenticate() async {
    final auth = ref.read(localAuthProvider);

    try {
      final authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to access your wallet',
        biometricOnly: false,
      );

      if (authenticated) {
        state = AsyncValue.data(state.value!.copyWith(isUnlocked: true));
      }

      return authenticated;
    } catch (e) {
      return false;
    }
  }

  /// Lock the app (require authentication again)
  void lock() {
    if (state.value?.biometricEnabled == true) {
      state = AsyncValue.data(state.value!.copyWith(isUnlocked: false));
    }
  }
}

/// State class for security
class SecurityState {
  final bool biometricEnabled;
  final bool screenProtectionEnabled;
  final bool deviceSupported;
  final bool isUnlocked;

  const SecurityState({
    required this.biometricEnabled,
    required this.screenProtectionEnabled,
    required this.deviceSupported,
    required this.isUnlocked,
  });

  SecurityState copyWith({
    bool? biometricEnabled,
    bool? screenProtectionEnabled,
    bool? deviceSupported,
    bool? isUnlocked,
  }) {
    return SecurityState(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      screenProtectionEnabled:
          screenProtectionEnabled ?? this.screenProtectionEnabled,
      deviceSupported: deviceSupported ?? this.deviceSupported,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }
}

/// Main security provider
final securityProvider = AsyncNotifierProvider<SecurityNotifier, SecurityState>(
  () => SecurityNotifier(),
);
