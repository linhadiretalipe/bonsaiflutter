import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help Center')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildFAQItem(
            'What is "Utreexo"?',
            'Utreexo is a novel accumulator technology that allows Bitcoin full nodes to verify the chain state using only a fraction of the memory (kilobytes vs gigabytes). This makes running a full node on mobile possible.',
          ),
          _buildFAQItem(
            'Why use this instead of other wallets?',
            'Most mobile wallets rely on centralized servers (like Electrum or Esplora) to tell you your balance. This leaks your IP and addresses. Bonsai connects directly to the Bitcoin P2P network, preserving your privacy.',
          ),
          _buildFAQItem(
            'How do I backup my wallet?',
            'Go to Settings > Wallet Backup to view your 12-word seed phrase. Write it down on paper and keep it safe. Never share it with anyone.',
          ),
          _buildFAQItem(
            'Is this safe?',
            'Bonsai is open source and non-custodial. You hold the keys. However, the software is currently in Beta/WIP state. Use with caution for large amounts.',
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconColor: AppTheme.primaryGreen,
        collapsedIconColor: Colors.white54,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            answer,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }
}
