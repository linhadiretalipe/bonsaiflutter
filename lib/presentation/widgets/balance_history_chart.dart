import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class BalanceHistoryChart extends StatelessWidget {
  final List<double> balanceHistory;

  const BalanceHistoryChart({super.key, required this.balanceHistory});

  @override
  Widget build(BuildContext context) {
    if (balanceHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    // Create spots from history
    final spots = balanceHistory.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    // Calculate min/max for Y axis
    final minY = balanceHistory.reduce((a, b) => a < b ? a : b);
    final maxY = balanceHistory.reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1;

    return Container(
      height: 120,
      padding: const EdgeInsets.only(right: 16, top: 8),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (balanceHistory.length - 1).toDouble(),
          minY: minY - padding,
          maxY: maxY + padding,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppTheme.darkSurface,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(6)} BTC',
                    const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: AppTheme.primaryGreen,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryGreen.withOpacity(0.3),
                    AppTheme.primaryGreen.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 250),
      ),
    );
  }
}
