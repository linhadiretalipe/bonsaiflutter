import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/node_provider.dart';
import '../../core/providers/security_provider.dart';

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
          const Divider(color: Colors.white10, height: 40),

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
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
        onTap: onTap,
      ),
    );
  }
}
