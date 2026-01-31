import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.white : Colors.white54,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: isTotal ? AppTheme.primaryGreen : Colors.white,
                fontFamily: 'Berkeley Mono',
                fontWeight: FontWeight.bold,
                fontSize: isTotal ? 18 : 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
