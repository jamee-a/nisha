import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HistoricalReportsScreen extends StatelessWidget {
  const HistoricalReportsScreen({super.key}); // ✅ منشئ const

  final List<double> pastSleepHours = const [6.5, 7.0, 5.8, 6.2, 8.1, 7.5, 6.9];

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return const Scaffold(
        body: Center(child: Text('Localization not loaded')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.historicalReports),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              localizations.sleepDurationOverWeek,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SleepHistoryBarChart(
                data: pastSleepHours,
                localizations: localizations,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SleepHistoryBarChart extends StatelessWidget {
  final List<double> data;
  final AppLocalizations localizations;

  const SleepHistoryBarChart({
    super.key,
    required this.data,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    final days = [
      localizations.sunday,
      localizations.monday,
      localizations.tuesday,
      localizations.wednesday,
      localizations.thursday,
      localizations.friday,
      localizations.saturday,
    ];

    return BarChart(
      BarChartData(
        maxY: 10,
        barGroups: List.generate(data.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data[index],
                color: Colors.deepPurple,
                width: 14,
              )
            ],
          );
        }),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    days[value.toInt()],
                    style: const TextStyle(fontSize: 12, fontFamily: 'Roboto'),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}h',
                  style: const TextStyle(fontSize: 12, fontFamily: 'Roboto'),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: true),
      ),
    );
  }
}
