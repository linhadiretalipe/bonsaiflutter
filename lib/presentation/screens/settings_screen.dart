import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
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
            subtitle: 'Signet',
            icon: Icons.hub,
            onTap: () {},
          ),
          _buildSettingsTile(
            title: 'User Agent',
            subtitle: '/Bonsai:0.1.0/',
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
