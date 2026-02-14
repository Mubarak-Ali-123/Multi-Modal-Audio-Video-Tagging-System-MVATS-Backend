import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PieChartCard extends StatelessWidget {
  const PieChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    /// TAU Urban Acoustic Scene classes dummy data
    final classNames = [
      'Airport',
      'Shopping Mall',
      'Metro Station',
      'Street Pedestrian',
      'Public Square',
      'Street Traffic',
      'Tram',
      'Bus',
      'Metro',
      'Park',
    ];

    final dataValues = [12, 14, 10, 9, 10, 11, 8, 7, 9, 6];

    final total = dataValues.reduce((a, b) => a + b);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide * 0.95;

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: size * 0.22,
                sectionsSpace: 3,
                sections: List.generate(classNames.length, (i) {
                  final percentage = (dataValues[i] / total) * 100;

                  final colors = [
                    scheme.primary,
                    scheme.secondary,
                    scheme.tertiary,
                    scheme.error,
                    scheme.secondaryContainer,
                    scheme.primaryContainer,
                    scheme.surfaceTint,
                    scheme.inversePrimary,
                    scheme.outline,
                    scheme.secondary.withValues(alpha: 0.7),
                  ];

                  return PieChartSectionData(
                    value: dataValues[i].toDouble(),
                    title: "${percentage.toStringAsFixed(1)}%",
                    color: colors[i % colors.length],
                    radius: size * 0.30,
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}
