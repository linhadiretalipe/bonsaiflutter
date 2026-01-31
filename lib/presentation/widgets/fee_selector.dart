import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class FeeSelector extends StatelessWidget {
  final double currentFeeRate;
  final ValueChanged<double> onFeeSelected;

  const FeeSelector({
    super.key,
    required this.currentFeeRate,
    required this.onFeeSelected,
  });

  Widget _buildFeeChip(String label, double rate) {
    final isSelected = currentFeeRate == rate;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onFeeSelected(rate);
        }
      },
      selectedColor: AppTheme.primaryGreen,
      backgroundColor: AppTheme.darkSurface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "NETWORK FEE",
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFeeChip("Slow", 1.0),
            _buildFeeChip("Medium", 10.0),
            _buildFeeChip("Fast", 50.0),
          ],
        ),
        if (currentFeeRate > 50) ...[
          const SizedBox(height: 16),
          Text(
            "Custom Fee: ${currentFeeRate.toStringAsFixed(1)} sats/vB",
            style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 13),
          ),
        ],
      ],
    );
  }
}
