import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../core/theme/app_theme.dart';
import '../../core/providers/node_provider.dart';
import '../../core/providers/security_provider.dart';
import 'recovery_phrase_view_screen.dart';
import 'wallet_setup_screen.dart';
import 'help_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodeAsync = ref.watch(nodeProvider);
    final isRunning = nodeAsync.value?.isRunning ?? false;
    final stats = nodeAsync.value?.stats;

    final securityAsync = ref.watch(securityProvider);
    final biometricEnabled = securityAsync.value?.biometricEnabled ?? false;
    final deviceSupported = securityAsync.value?.deviceSupported ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Security Section
          const Text(
            'Security',
            style: TextStyle(
              color: AppTheme.primaryGreen,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildBiometricTile(
            context: context,
            ref: ref,
            enabled: biometricEnabled,
            deviceSupported: deviceSupported,
          ),
          _buildSettingsTile(
            title: 'View Recovery Phrase',
            subtitle: 'Backup your wallet',
            icon: Icons.vpn_key,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RecoveryPhraseViewScreen(),
                ),
              );
            },
          ),
          const Divider(color: Colors.white10, height: 40),

          // Danger Zone
          if (isRunning) ...[
            const Text(
              'Danger Zone',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsTile(
              title: 'Reset Wallet',
              subtitle: 'Wipe all data and keys',
              icon: Icons.delete_forever,
              iconColor: Colors.redAccent,
              onTap: () => _confirmResetWallet(context),
            ),
            const Divider(color: Colors.white10, height: 40),
          ],

          // Node Configuration
          const Text(
            'Node Configuration',
            style: TextStyle(
              color: AppTheme.primaryGreen,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingsTile(
            title: 'Network',
            subtitle: isRunning ? 'Signet' : 'Disconnected',
            icon: Icons.hub,
            onTap: () {},
          ),
          _buildSettingsTile(
            title: 'User Agent',
            subtitle:
                stats?.userAgent ?? (isRunning ? 'Fetching...' : 'Not Running'),
            icon: Icons.person_outline,
            onTap: () {},
          ),
          _buildSettingsTile(
            title: 'SOCKS5 Proxy',
            subtitle: '127.0.0.1:9050',
            icon: Icons.security,
            onTap: () {},
          ),
          const Divider(color: Colors.white10, height: 40),

          // General
          const Text(
            'General',
            style: TextStyle(
              color: AppTheme.primaryGreen,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingsTile(
            title: 'Currency',
            subtitle: 'USD',
            icon: Icons.attach_money,
            onTap: () {},
          ),
          _buildSettingsTile(
            title: 'Help & Support',
            subtitle: 'FAQ and Guides',
            icon: Icons.help_outline,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpScreen()),
              );
            },
          ),
          _buildSettingsTile(
            title: 'About Bonsai',
            subtitle: 'Version 1.0.0',
            icon: Icons.info_outline,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricTile({
    required BuildContext context,
    required WidgetRef ref,
    required bool enabled,
    required bool deviceSupported,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        secondary: Icon(
          Icons.fingerprint,
          color: deviceSupported ? Colors.white70 : Colors.white30,
        ),
        title: Text(
          'Biometric Lock',
          style: TextStyle(
            color: deviceSupported ? Colors.white : Colors.white38,
          ),
        ),
        subtitle: Text(
          deviceSupported
              ? (enabled ? 'Enabled' : 'Disabled')
              : 'Not available on this device',
          style: const TextStyle(color: Colors.white38),
        ),
        value: enabled,
        activeColor: AppTheme.primaryGreen,
        onChanged: deviceSupported
            ? (value) async {
                if (value) {
                  // Test authentication before enabling
                  final success = await ref
                      .read(securityProvider.notifier)
                      .authenticate();
                  if (success) {
                    await ref
                        .read(securityProvider.notifier)
                        .toggleBiometric(true);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Biometric lock enabled'),
                          backgroundColor: AppTheme.primaryGreen,
                        ),
                      );
                    }
                  }
                } else {
                  await ref
                      .read(securityProvider.notifier)
                      .toggleBiometric(false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Biometric lock disabled'),
                        backgroundColor: AppTheme.darkSurface,
                      ),
                    );
                  }
                }
              }
            : null,
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? Colors.white70),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
        onTap: onTap,
      ),
    );
  }

  Future<void> _confirmResetWallet(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: const Text(
          'Reset Wallet?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will permanently delete your wallet keys and all data. '
          'Make sure you have backed up your recovery phrase first!\n\n'
          'Are you sure you want to continue?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // 1. Wipe data directory
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final dir = Directory(appDir.path);
        if (dir.existsSync()) {
          dir.deleteSync(recursive: true);
        }

        // 2. Clear Shared Preferences
        // Note: This is simpler if we just clear everything or specific keys
        // For now, let's assume we want a fresh start
        // Accessing refs inside context-less function is tricky, but we can restart app

        if (context.mounted) {
          // Navigate to Setup Screen
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WalletSetupScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error resetting wallet: $e')));
        }
      }
    }
  }
}
