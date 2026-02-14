import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class BarChartCard extends StatelessWidget {
  const BarChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    /// TAU Urban Acoustic Scene classes dummy data
    final classNames = [
      'Airport',
      'Mall',
      'Metro St.',
      'Street Ped.',
      'Square',
      'Traffic',
      'Tram',
      'Bus',
      'Metro',
      'Park',
    ];

    /// Dummy TAU occurrence counts
    final occurrences = [18, 15, 12, 10, 9, 8, 7, 6, 5, 4];

    final maxY = (occurrences.reduce((a, b) => a > b ? a : b) + 3).toDouble();

    final colors = [
      scheme.primary,
      scheme.secondary,
      scheme.tertiary,
      scheme.primaryContainer,
      scheme.secondaryContainer,
      scheme.error,
      scheme.surfaceTint,
      scheme.inversePrimary,
      scheme.outline,
      scheme.secondary.withValues(alpha: 0.7),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth * 0.05;

        return BarChart(
          BarChartData(
            minY: 0,
            maxY: maxY,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: scheme.outline.withValues(alpha: 0.25),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() < 0 ||
                        value.toInt() >= classNames.length) {
                      return const SizedBox.shrink();
                    }

                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        classNames[value.toInt()],
                        style: TextStyle(
                          fontSize: 10,
                          color: scheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 34,
                  interval: 5,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: List.generate(classNames.length, (i) {
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: occurrences[i].toDouble(),
                    color: colors[i % colors.length],
                    width: barWidth,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }
}
